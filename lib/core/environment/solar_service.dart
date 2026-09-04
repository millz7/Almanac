import 'package:flutter/foundation.dart';

import 'geo_location.dart';
import 'local_time_zone.dart';
import 'solar_calculator.dart';

export 'solar_calculator.dart' show SolarDayKind;

/// Sunrise and sunset for one local day, as absolute UTC instants.
///
/// Absolute instants, not local clock times: an instant is unambiguous
/// across time zones and daylight-saving changes, and is converted to
/// local time only for display.
@immutable
class SolarEvents {
  const SolarEvents.risesAndSets({
    required DateTime this.sunrise,
    required DateTime this.sunset,
  }) : kind = SolarDayKind.risesAndSets;

  /// Polar night: the sun stays below the horizon all day.
  const SolarEvents.sunNeverRises()
    : kind = SolarDayKind.sunNeverRises,
      sunrise = null,
      sunset = null;

  /// Midnight sun: the sun stays above the horizon all day.
  const SolarEvents.sunNeverSets()
    : kind = SolarDayKind.sunNeverSets,
      sunrise = null,
      sunset = null;

  /// The app cannot know: no position has been shared.
  const SolarEvents.locationRequired()
    : kind = SolarDayKind.risesAndSets,
      sunrise = null,
      sunset = null;

  final SolarDayKind kind;

  /// UTC instant of sunrise, or null when there is none to report.
  final DateTime? sunrise;

  /// UTC instant of sunset, or null when there is none to report.
  final DateTime? sunset;

  /// True when there are real times to work with.
  bool get hasTimes => sunrise != null && sunset != null;

  @override
  String toString() => hasTimes
      ? 'SolarEvents($sunrise → $sunset)'
      : 'SolarEvents(${kind.name}, no times)';
}

/// Supplies sunrise/sunset.
///
/// [location] is nullable because the app must keep working when the user
/// has not shared their position. Sunrise genuinely cannot be computed
/// without coordinates, so implementations return
/// [SolarEvents.locationRequired] rather than a guess.
///
/// Asynchronous so an implementation may do work off the main isolate or
/// consult a cache; the current one calculates locally and returns
/// immediately.
abstract interface class SolarService {
  /// Sunrise and sunset for the local day that contains [instant].
  Future<SolarEvents> eventsFor({
    required DateTime instant,
    required LocalTimeZone timeZone,
    GeoLocation? location,
  });
}

/// Calculates sunrise and sunset locally from the user's coordinates.
///
/// Everything happens on the device: no network call, no third-party
/// service, and nothing about where the user is leaves the phone. See
/// [SolarCalculator] for the algorithm, its accuracy and its assumptions.
class AstronomicalSolarService implements SolarService {
  const AstronomicalSolarService();

  @override
  Future<SolarEvents> eventsFor({
    required DateTime instant,
    required LocalTimeZone timeZone,
    GeoLocation? location,
  }) async {
    if (location == null) return const SolarEvents.locationRequired();

    // The local calendar date is what "today's sunrise" means, so the
    // date comes from the user's zone rather than from UTC.
    final date = timeZone.localDateOf(instant);
    final times = SolarCalculator.forDate(
      year: date.year,
      month: date.month,
      day: date.day,
      latitude: location.latitude,
      longitude: location.longitude,
    );

    return switch (times.kind) {
      SolarDayKind.risesAndSets => SolarEvents.risesAndSets(
        sunrise: times.sunrise!,
        sunset: times.sunset!,
      ),
      SolarDayKind.sunNeverRises => const SolarEvents.sunNeverRises(),
      SolarDayKind.sunNeverSets => const SolarEvents.sunNeverSets(),
    };
  }
}
