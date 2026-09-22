import 'dart:convert';

import 'package:http/http.dart' as http;

import 'geo_location.dart';
import 'local_time_zone.dart';
import 'tide.dart';
import 'tide_extrema.dart';
import 'tide_service.dart';

/// Fetches a tide curve from
/// [Open-Meteo Marine](https://open-meteo.com/en/docs/marine-weather-api)
/// — the same provider and account-free, non-commercial model the app
/// already uses for weather, so this is not a second network dependency
/// or a second privacy model, just a second endpoint on the one already
/// trusted.
///
/// **This is the only place `sea_level_height_msl` is read.** Open-Meteo
/// documents that field as "sea level height accounts for ocean tides,
/// the inverted barometer effect, sea surface height, global mean steric
/// variation, and global mean mass volume variation" against a global
/// mean sea level datum — a modelled curve, not a harbour tide table —
/// and states plainly: "Accuracy is limited in coastal areas — while it
/// can be reasonably accurate near unobstructed coasts, it may be
/// completely unreliable further inland. This data is not suitable for
/// coastal navigation." Every high/low this service derives inherits
/// that limitation, which is why the app never claims more precision
/// than "roughly" and always shows the non-navigation note — see
/// `TideText.nonNavigationNote`.
class OpenMeteoMarineTideService implements TideService {
  // ignore: prefer_initializing_formals
  const OpenMeteoMarineTideService({http.Client? client}) : _client = client;

  /// Injected in tests; a fresh client is opened and closed per call
  /// otherwise; see [fetch].
  final http.Client? _client;

  static final _endpoint = Uri.parse(
    'https://marine-api.open-meteo.com/v1/marine',
  );

  /// One day back, today, and one day ahead: enough hourly samples to
  /// find the high/low either side of "now" and the next one or two
  /// events beyond it, without asking for — or retaining — a
  /// multi-day tide table. Documented here rather than left as a bare
  /// number in the query so the window's size is easy to find and
  /// change in one place.
  static const _pastDays = 1;
  static const _forecastDays = 2;

  @override
  Future<TideFetchResult> fetch({
    required GeoLocation location,
    required LocalTimeZone timeZone,
    required DateTime now,
  }) async {
    final latitude = _round(location.latitude);
    final longitude = _round(location.longitude);

    final uri = _endpoint.replace(
      queryParameters: {
        'latitude': latitude.toStringAsFixed(2),
        'longitude': longitude.toStringAsFixed(2),
        'hourly': 'sea_level_height_msl',
        'timezone': timeZone.id,
        'past_days': '$_pastDays',
        'forecast_days': '$_forecastDays',
      },
    );

    final client = _client ?? http.Client();
    try {
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw TideServiceFailure(
          'Open-Meteo Marine returned HTTP ${response.statusCode}',
        );
      }

      final Object? decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException catch (error) {
        throw TideServiceFailure('invalid JSON: $error');
      }
      if (decoded is! Map<String, dynamic>) {
        throw const TideServiceFailure('unexpected response shape');
      }

      return _parse(
        decoded,
        location: GeoLocation(latitude: latitude, longitude: longitude),
        timeZone: timeZone,
        obtainedAt: now,
      );
    } on TideServiceFailure {
      rethrow;
    } on Object catch (error) {
      throw TideServiceFailure('$error');
    } finally {
      if (_client == null) client.close();
    }
  }

  TideFetchResult _parse(
    Map<String, dynamic> json, {
    required GeoLocation location,
    required LocalTimeZone timeZone,
    required DateTime obtainedAt,
  }) {
    final hourly = json['hourly'];
    if (hourly is! Map) {
      throw const TideServiceFailure('missing hourly block');
    }

    final times = _stringList(hourly['time']);
    final heights = _nullableNumberList(hourly['sea_level_height_msl']);
    if (times.isEmpty || heights.isEmpty) {
      throw const TideServiceFailure('empty hourly series');
    }
    if (times.length != heights.length) {
      throw const TideServiceFailure(
        'mismatched time and sea_level_height_msl lengths',
      );
    }

    final samples = <TideSample>[
      for (var i = 0; i < times.length; i++)
        if (heights[i] case final height?)
          TideSample(
            time: _parseLocalTime(times[i], timeZone),
            heightMetres: height.toDouble(),
          ),
    ];

    // Every reading came back null: the documented shape of "this grid
    // cell has no marine data", almost always meaning the position is
    // not on water the model covers. Not a failure — a clean answer.
    if (samples.isEmpty) return const TideFetchNoData();
    // A handful of stray gaps is normal at the edge of a model run; too
    // few real samples to find a turning point is treated the same way
    // as no data at all, rather than guessing from a couple of points.
    if (samples.length < 3) return const TideFetchNoData();

    return TideFetchData(
      TideSnapshot(
        location: location,
        obtainedAt: obtainedAt,
        samples: samples,
        extrema: extractTideExtrema(samples),
      ),
    );
  }

  /// Rounds to two decimal places — the same precision, and the same
  /// reasoning, as `OpenMeteoWeatherService._round`: roughly a
  /// kilometre, ample for a marine grid modelled at about 8 km
  /// resolution, and far coarser than the raw GPS fix already held.
  double _round(double value) => (value * 100).round() / 100;

  List<num?> _nullableNumberList(Object? value) => switch (value) {
    List<dynamic> list => [
      for (final item in list)
        switch (item) {
          num n => n,
          null => null,
          _ => throw TideServiceFailure('expected a number, got $item'),
        },
    ],
    _ => const [],
  };

  List<String> _stringList(Object? value) => switch (value) {
    List<dynamic> list => [for (final item in list) '$item'],
    _ => const [],
  };

  /// Same local-time parsing as `OpenMeteoWeatherService`: Open-Meteo,
  /// given an explicit IANA `timezone`, returns local wall-clock ISO
  /// 8601 with no offset — `"2026-04-27T14:00"` — parsed as local time
  /// in [zone] and turned into a real instant via
  /// [LocalTimeZone.instantAtLocal].
  DateTime _parseLocalTime(String iso, LocalTimeZone zone) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})')
        .firstMatch(iso);
    if (match == null) {
      throw TideServiceFailure('unparseable time "$iso"');
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
