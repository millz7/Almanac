import 'package:flutter/foundation.dart';

import 'geo_location.dart';
import 'weather_condition.dart';

export 'weather_condition.dart';

/// Conditions right now.
@immutable
class CurrentWeather {
  const CurrentWeather({
    required this.temperatureC,
    required this.apparentTemperatureC,
    required this.condition,
    required this.precipitationMm,
    required this.cloudCoverPercent,
    required this.windSpeedKmh,
    this.windGustKmh,
  });

  final double temperatureC;

  /// "Feels like" — what the narrative's temperature language is based
  /// on, since it is closer to what a person actually notices than the
  /// dry-bulb reading.
  final double apparentTemperatureC;

  final WeatherCondition condition;

  /// Millimetres in whatever short window the provider aggregates (Open
  /// Meteo's `current` block is a recent-past window, not a forecast).
  final double precipitationMm;

  final double cloudCoverPercent;
  final double windSpeedKmh;
  final double? windGustKmh;

  @override
  String toString() =>
      'CurrentWeather(${condition.name}, '
      '${temperatureC.round()}°C, feels ${apparentTemperatureC.round()}°C)';
}

/// One hour of forecast, close enough to now to be worth narrating.
@immutable
class HourlyWeather {
  const HourlyWeather({
    required this.time,
    required this.condition,
    required this.temperatureC,
    required this.precipitationProbabilityPercent,
    required this.windSpeedKmh,
  });

  /// UTC instant this hour begins.
  final DateTime time;

  final WeatherCondition condition;
  final double temperatureC;
  final double precipitationProbabilityPercent;
  final double windSpeedKmh;
}

/// Today's headline numbers.
@immutable
class DailySummary {
  const DailySummary({
    required this.highC,
    required this.lowC,
    required this.precipitationProbabilityPercent,
  });

  final double highC;
  final double lowC;
  final double precipitationProbabilityPercent;
}

/// Everything the Almanac keeps from one forecast fetch.
///
/// **Mapped once, kept small.** The provider's raw response is not held
/// anywhere past the call that parses it — every value here is an
/// app-owned type (`WeatherCondition`, plain doubles with a named unit),
/// so nothing downstream ever touches a vendor field name or a numeric
/// weather code.
@immutable
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.location,
    required this.obtainedAt,
    required this.current,
    required this.today,
    required this.hourly,
  });

  /// The (rounded, low-precision) coordinates this forecast was fetched
  /// for — see `OpenMeteoWeatherService` for the exact rounding. Kept so
  /// a later, still-fresh read can tell whether the cached forecast is
  /// still for roughly where the user is.
  final GeoLocation location;

  /// When the fetch completed. Not persisted between launches, and not
  /// shown to the user as a coordinate or a timestamp — used only to
  /// decide whether this snapshot is stale.
  final DateTime obtainedAt;

  final CurrentWeather current;
  final DailySummary today;

  /// The next stretch of hours, in order, starting at or after
  /// [obtainedAt]'s hour. Enough to narrate "later today" and "overnight
  /// into tomorrow morning" — not a multi-day forecast.
  final List<HourlyWeather> hourly;

  /// Whether this snapshot is older than [maxAge].
  bool isStaleAt(DateTime now, Duration maxAge) =>
      now.toUtc().difference(obtainedAt.toUtc()) > maxAge;

  @override
  String toString() => 'WeatherSnapshot($current, obtained $obtainedAt)';
}

/// Thrown by a [WeatherService] on a network failure, a non-200 response,
/// or a response that cannot be parsed. Always caught at the seam that
/// calls the service — see `WeatherController` — so the app is never left
/// without weather it can fall back to gracefully.
class WeatherServiceFailure implements Exception {
  const WeatherServiceFailure(this.message);

  final String message;

  @override
  String toString() => 'WeatherServiceFailure: $message';
}
