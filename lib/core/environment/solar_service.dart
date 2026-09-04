import 'package:flutter/foundation.dart';

import 'geo_location.dart';
import 'local_time_zone.dart';

/// Sunrise and sunset for one local day, as absolute UTC instants.
@immutable
class SolarEvents {
  const SolarEvents({required this.sunrise, required this.sunset});

  final DateTime sunrise;
  final DateTime sunset;

  @override
  String toString() => 'SolarEvents(sunrise: $sunrise, sunset: $sunset)';
}

/// Supplies sunrise/sunset.
///
/// [location] is nullable because the app must keep working when the user
/// has not shared their position. A real astronomical implementation will
/// need it and should report that it cannot answer without one; the
/// current placeholder does not use it at all.
///
/// Asynchronous because the real implementation — a platform plugin, an
/// API call, or a cached calculation — will be. Keeping the signature
/// async now means connecting it later requires no changes to callers.
abstract interface class SolarService {
  /// Sunrise and sunset for the local day that contains [instant].
  Future<SolarEvents> eventsFor({
    required DateTime instant,
    required LocalTimeZone timeZone,
    GeoLocation? location,
  });
}

/// PROVISIONAL — placeholder sunrise/sunset times.
///
/// This does **not** calculate anything astronomical: it returns the same
/// two local clock times every day, everywhere, and ignores [location]
/// entirely. It exists only so the day/night theme engine has something
/// to run against until the real solar service is built in a later step.
/// Nothing in the UI presents these values to the user as real data.
///
/// A useful side effect of needing only the time zone: day/night theming
/// behaves identically whether or not the user shares their location.
/// When the real service lands, that will no longer be true, and the
/// "location required" degradation will apply to it.
class PlaceholderSolarService implements SolarService {
  const PlaceholderSolarService({
    this.sunriseAfterLocalMidnight = const Duration(hours: 6, minutes: 30),
    this.sunsetAfterLocalMidnight = const Duration(hours: 20, minutes: 30),
  });

  final Duration sunriseAfterLocalMidnight;
  final Duration sunsetAfterLocalMidnight;

  @override
  Future<SolarEvents> eventsFor({
    required DateTime instant,
    required LocalTimeZone timeZone,
    GeoLocation? location,
  }) async {
    final midnight = timeZone.midnightOf(instant);
    return SolarEvents(
      sunrise: midnight.add(sunriseAfterLocalMidnight),
      sunset: midnight.add(sunsetAfterLocalMidnight),
    );
  }
}
