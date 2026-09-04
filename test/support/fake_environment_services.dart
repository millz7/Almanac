import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_service.dart';
import 'package:almanac/core/environment/solar_service.dart';

/// Returns whatever location the test asks for.
class FakeLocationService implements LocationService {
  FakeLocationService(this.location);

  final GeoLocation location;

  @override
  Future<GeoLocation> currentLocation() async => location;
}

/// Returns fixed sunrise/sunset instants, so day/night behaviour can be
/// tested without any real astronomy.
class FakeSolarService implements SolarService {
  FakeSolarService({required this.sunrise, required this.sunset});

  final DateTime sunrise;
  final DateTime sunset;

  @override
  Future<SolarEvents> eventsFor(GeoLocation location, DateTime instant) async =>
      SolarEvents(sunrise: sunrise, sunset: sunset);
}

/// A few real places, for hemisphere and time-zone coverage.
abstract final class TestLocations {
  /// London: northern hemisphere, near zero meridian.
  static const london = GeoLocation(
    latitude: 51.5,
    longitude: -0.13,
    utcOffset: Duration(hours: 0),
  );

  /// Wellington: southern hemisphere, well ahead of UTC.
  static const wellington = GeoLocation(
    latitude: -41.29,
    longitude: 174.78,
    utcOffset: Duration(hours: 13),
  );

  /// Sydney: southern hemisphere.
  static const sydney = GeoLocation(
    latitude: -33.87,
    longitude: 151.21,
    utcOffset: Duration(hours: 11),
  );
}
