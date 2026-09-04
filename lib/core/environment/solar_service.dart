import 'package:flutter/foundation.dart';

import 'geo_location.dart';

/// Sunrise and sunset for one local day, as absolute UTC instants.
@immutable
class SolarEvents {
  const SolarEvents({required this.sunrise, required this.sunset});

  final DateTime sunrise;
  final DateTime sunset;

  @override
  String toString() => 'SolarEvents(sunrise: $sunrise, sunset: $sunset)';
}

/// Supplies sunrise/sunset for a location.
///
/// Asynchronous because the real implementation — a platform plugin, an API
/// call, or a cached calculation — will be. Keeping the signature async now
/// means connecting it in a later step requires no changes to any caller.
abstract interface class SolarService {
  /// Sunrise and sunset for the local day that contains [instant].
  Future<SolarEvents> eventsFor(GeoLocation location, DateTime instant);
}

/// PROVISIONAL — placeholder sunrise/sunset times.
///
/// This does **not** calculate anything astronomical: it returns the same
/// two local clock times every day, everywhere. It exists only so the
/// day/night theme engine has something to run against until the real
/// solar service is built in a later step. Nothing in the UI presents
/// these values to the user as real data.
class PlaceholderSolarService implements SolarService {
  const PlaceholderSolarService({
    this.sunriseAfterLocalMidnight = const Duration(hours: 6, minutes: 30),
    this.sunsetAfterLocalMidnight = const Duration(hours: 20, minutes: 30),
  });

  final Duration sunriseAfterLocalMidnight;
  final Duration sunsetAfterLocalMidnight;

  @override
  Future<SolarEvents> eventsFor(GeoLocation location, DateTime instant) async {
    final midnight = location.localMidnight(instant);
    return SolarEvents(
      sunrise: location.toInstant(midnight.add(sunriseAfterLocalMidnight)),
      sunset: location.toInstant(midnight.add(sunsetAfterLocalMidnight)),
    );
  }
}
