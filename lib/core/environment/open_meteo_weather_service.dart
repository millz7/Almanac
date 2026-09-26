import 'dart:convert';

import 'package:http/http.dart' as http;

import 'geo_location.dart';
import 'local_time_zone.dart';
import 'weather.dart';
import 'weather_service.dart';

/// Fetches a forecast from [Open-Meteo](https://open-meteo.com) — chosen
/// because its free, non-commercial forecast endpoint needs no account,
/// no API key and no client secret embedded in the app. The data itself
/// is CC BY 4.0; attribution is given in the app's privacy documentation
/// rather than on every screen, matching how the app credits its other
/// external sources.
///
/// **The only network call in the app**, and it sends the least it can:
/// coordinates rounded to two decimal places (roughly a kilometre — see
/// [_round]) and nothing else identifying. No account, no device
/// identifier, no header beyond what `package:http` sends by default.
///
/// Requests `forecast_days=2` (today and tomorrow) so the hourly series
/// comfortably covers "later tonight" and "towards tomorrow morning" for
/// a request made late in the evening, without asking for — or
/// retaining — a multi-day forecast.
class OpenMeteoWeatherService implements WeatherService {
  // Named `client` rather than `_client` in the constructor so it stays
  // a normal, callable-from-anywhere parameter for tests to inject.
  // ignore: prefer_initializing_formals
  const OpenMeteoWeatherService({http.Client? client}) : _client = client;

  /// Injected in tests; a fresh client is opened and closed per call
  /// otherwise; see [fetch].
  final http.Client? _client;

  static final _endpoint = Uri.parse('https://api.open-meteo.com/v1/forecast');

  static const _currentFields =
      'temperature_2m,apparent_temperature,weather_code,precipitation,'
      'cloud_cover,wind_speed_10m,wind_gusts_10m';
  static const _hourlyFields =
      'temperature_2m,weather_code,precipitation_probability,wind_speed_10m';
  static const _dailyFields =
      'temperature_2m_max,temperature_2m_min,precipitation_probability_max';

  /// How many hours of hourly forecast to keep, from the current hour.
  /// Comfortably spans "later today", all of tonight, and into tomorrow
  /// morning for every daypart's narrative, without retaining a second
  /// day's worth of detail nothing reads.
  static const _hourlyWindow = 24;

  @override
  Future<WeatherSnapshot> fetch({
    required GeoLocation location,
    required LocalTimeZone timeZone,
    required DateTime now,
  }) async {
    final latitude = _round(location.latitude);
    final longitude = _round(location.longitude);

    final uri = _endpoint.replace(
      queryParameters: {
        // Instants rather than local wall-clock strings: in the hour a
        // clock falls back, two local "01:00" readings would otherwise
        // name the same moment. The time zone still shapes the days.
        'timeformat': 'unixtime',
        'latitude': latitude.toStringAsFixed(2),
        'longitude': longitude.toStringAsFixed(2),
        'current': _currentFields,
        'hourly': _hourlyFields,
        'daily': _dailyFields,
        'timezone': timeZone.id,
        'forecast_days': '2',
      },
    );

    final client = _client ?? http.Client();
    try {
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw WeatherServiceFailure(
          'Open-Meteo returned HTTP ${response.statusCode}',
        );
      }

      final Object? decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException catch (error) {
        throw WeatherServiceFailure('invalid JSON: $error');
      }
      if (decoded is! Map<String, dynamic>) {
        throw WeatherServiceFailure('unexpected response shape');
      }

      return _parse(
        decoded,
        location: GeoLocation(latitude: latitude, longitude: longitude),
        timeZone: timeZone,
        obtainedAt: now,
      );
    } on WeatherServiceFailure {
      rethrow;
    } on Object catch (error) {
      // Any other failure — no connectivity, a DNS lookup that never
      // resolves, a timeout — is reported the same honest way.
      throw WeatherServiceFailure('$error');
    } finally {
      if (_client == null) client.close();
    }
  }

  WeatherSnapshot _parse(
    Map<String, dynamic> json, {
    required GeoLocation location,
    required LocalTimeZone timeZone,
    required DateTime obtainedAt,
  }) {
    final current = json['current'];
    final hourly = json['hourly'];
    final daily = json['daily'];
    if (current is! Map || hourly is! Map || daily is! Map) {
      throw const WeatherServiceFailure('missing current/hourly/daily block');
    }

    final currentWeather = CurrentWeather(
      temperatureC: _number(current['temperature_2m']),
      apparentTemperatureC: _number(current['apparent_temperature']),
      condition: WeatherCondition.fromWmoCode(
        _number(current['weather_code']).round(),
      ),
      precipitationMm: _number(current['precipitation']),
      cloudCoverPercent: _number(current['cloud_cover']),
      windSpeedKmh: _number(current['wind_speed_10m']),
      windGustKmh: current['wind_gusts_10m'] == null
          ? null
          : _number(current['wind_gusts_10m']),
    );
    _plausible(currentWeather.temperatureC, -90, 60, 'temperature');
    _plausible(
      currentWeather.apparentTemperatureC,
      -100,
      70,
      'apparent temperature',
    );
    _plausible(currentWeather.windSpeedKmh, 0, 400, 'wind speed');
    _plausible(currentWeather.precipitationMm, 0, 500, 'precipitation');
    _plausible(currentWeather.cloudCoverPercent, 0, 100, 'cloud cover');

    final dailyTimes = _stringList(daily['time']);
    final highs = _numberList(daily['temperature_2m_max']);
    final lows = _numberList(daily['temperature_2m_min']);
    final rainChance = _numberList(daily['precipitation_probability_max']);
    if (dailyTimes.isEmpty || highs.isEmpty || lows.isEmpty) {
      throw const WeatherServiceFailure('empty daily forecast');
    }
    final today = DailySummary(
      highC: highs.first,
      lowC: lows.first,
      precipitationProbabilityPercent: rainChance.isNotEmpty
          ? rainChance.first
          : 0,
    );

    final hourlyTimes = _stringList(hourly['time']);
    final hourlyTemps = _numberList(hourly['temperature_2m']);
    final hourlyCodes = _numberList(hourly['weather_code']);
    final hourlyRainChance = _numberList(hourly['precipitation_probability']);
    final hourlyWind = _numberList(hourly['wind_speed_10m']);
    for (final t in [...hourlyTemps, ...highs, ...lows]) {
      _plausible(t, -90, 60, 'temperature');
    }
    for (final w in hourlyWind) {
      _plausible(w, 0, 400, 'wind speed');
    }
    for (final p in [...hourlyRainChance, ...rainChance]) {
      _plausible(p, 0, 100, 'chance of rain');
    }

    // Read in time order, whatever order they arrived in, and a repeated
    // time only once: the look-ahead reads "the next few hours" and must
    // not be told the same hour twice or an earlier hour later.
    final order = [
      for (var i = 0; i < hourlyTimes.length; i++)
        (i, _parseLocalTime(hourlyTimes[i], timeZone)),
    ]..sort((a, b) => a.$2.compareTo(b.$2));

    final series = <HourlyWeather>[];
    for (final (i, time) in order) {
      if (series.isNotEmpty && !time.isAfter(series.last.time)) continue;
      if (time.isBefore(
        obtainedAt.toUtc().subtract(const Duration(hours: 1)),
      )) {
        continue;
      }
      if (series.length >= _hourlyWindow) break;
      series.add(
        HourlyWeather(
          time: time,
          condition: WeatherCondition.fromWmoCode(
            i < hourlyCodes.length ? hourlyCodes[i].round() : 0,
          ),
          temperatureC: i < hourlyTemps.length
              ? hourlyTemps[i]
              : currentWeather.temperatureC,
          precipitationProbabilityPercent: i < hourlyRainChance.length
              ? hourlyRainChance[i]
              : 0,
          windSpeedKmh: i < hourlyWind.length ? hourlyWind[i] : 0,
        ),
      );
    }

    return WeatherSnapshot(
      location: location,
      obtainedAt: obtainedAt,
      current: currentWeather,
      today: today,
      hourly: series,
    );
  }

  /// Rounds to two decimal places — roughly a kilometre of precision,
  /// ample for a local forecast and far coarser than the raw GPS fix the
  /// rest of the app already holds. This is the only place a coordinate
  /// is prepared for something outside the device.
  double _round(double value) => (value * 100).round() / 100;

  double _number(Object? value) => switch (value) {
    num n when n.isFinite => n.toDouble(),
    _ => throw WeatherServiceFailure('expected a number, got $value'),
  };

  /// A reading no weather on Earth produces is a broken response, not a
  /// forecast: the fetch fails quietly and the app says nothing, rather
  /// than describing a 900° afternoon.
  static void _plausible(double value, double min, double max, String what) {
    if (value < min || value > max) {
      throw WeatherServiceFailure('implausible $what: $value');
    }
  }

  List<double> _numberList(Object? value) => switch (value) {
    List<dynamic> list => [for (final item in list) _number(item)],
    _ => const [],
  };

  List<String> _stringList(Object? value) => switch (value) {
    List<dynamic> list => [for (final item in list) '$item'],
    _ => const [],
  };

  /// Open-Meteo, given an explicit IANA `timezone`, returns hourly/daily
  /// timestamps as local wall-clock ISO 8601 with no offset —
  /// `"2026-04-27T14:00"` — so they are parsed as local time in [zone]
  /// and turned into a real instant via [LocalTimeZone.instantAtLocal],
  /// never stored as a naive clock time.
  ///
  /// With `timeformat=unixtime`, which the app asks for, a time is whole
  /// seconds since the epoch — an unambiguous UTC instant, the right
  /// answer on the days the clocks change. The ISO form is still read.
  DateTime _parseLocalTime(String iso, LocalTimeZone zone) {
    if (int.tryParse(iso) case final seconds?) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    }
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})')
        .firstMatch(iso);
    if (match == null) {
      throw WeatherServiceFailure('unparseable time "$iso"');
    }
    return zone.instantAtLocal(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
    );
  }
}
