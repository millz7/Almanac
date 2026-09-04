import 'geo_location.dart';

/// Supplies the user's location.
///
/// Asynchronous because the real implementation will consult the platform
/// (and, at that point, ask permission). Nothing in this step requests any
/// permission or transmits anything.
abstract interface class LocationService {
  Future<GeoLocation> currentLocation();
}

/// PROVISIONAL — a permission-free stand-in for real location.
///
/// The device's UTC offset is genuinely available without permission, so
/// the local calendar day is correct. Latitude is *not* knowable this way,
/// so the hemisphere is a documented assumption ([fallbackLatitude]) and
/// the result is flagged [GeoLocation.isFallback].
///
/// This matters: a user in New Zealand would be shown winter in January
/// until the real location service is connected. Change
/// [fallbackLatitude] to a southern value while developing, or use the
/// developer theme preview to inspect any season.
class DeviceOffsetLocationService implements LocationService {
  const DeviceOffsetLocationService({
    this.fallbackLatitude = 51.5,
    this.fallbackLongitude = 0,
  });

  /// Assumed latitude when the real position is unknown. Positive values
  /// mean northern hemisphere seasons.
  final double fallbackLatitude;
  final double fallbackLongitude;

  @override
  Future<GeoLocation> currentLocation() async => GeoLocation(
    latitude: fallbackLatitude,
    longitude: fallbackLongitude,
    utcOffset: DateTime.now().timeZoneOffset,
    isFallback: true,
  );
}
