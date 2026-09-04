import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:almanac/core/environment/location_service.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/solar_service.dart';

/// A location service that reports whatever the test wants, and records
/// whether the app prompted or merely checked.
class FakeLocationService implements LocationService {
  FakeLocationService({
    this.checkResult = const LocationPermissionNotRequested(),
    LocationState? requestResult,
  }) : requestResult = requestResult ?? checkResult;

  /// What a non-prompting check reports.
  LocationState checkResult;

  /// What the prompting request reports.
  LocationState requestResult;

  /// How many times each entry point was used, so tests can assert the
  /// app never prompts on its own.
  int checkCount = 0;
  int requestCount = 0;

  @override
  Future<LocationState> currentState() async {
    checkCount++;
    return checkResult;
  }

  @override
  Future<LocationState> requestAccess() async {
    requestCount++;
    return requestResult;
  }
}

/// A location service whose calls always blow up, to prove the app
/// survives a broken platform layer.
class ThrowingLocationService implements LocationService {
  const ThrowingLocationService();

  @override
  Future<LocationState> currentState() async =>
      throw StateError('platform location channel unavailable');

  @override
  Future<LocationState> requestAccess() async =>
      throw StateError('platform location channel unavailable');
}

/// A location controller that starts in a given state instead of "never
/// asked". Everything else — [refresh], [requestAccess] — still runs
/// against the injected [LocationService].
class FixedLocationController extends LocationController {
  FixedLocationController(this.initialState);

  final LocationState initialState;

  @override
  LocationState build() => initialState;
}

/// Returns fixed sunrise/sunset instants, so day/night behaviour can be
/// tested without any real astronomy.
class FakeSolarService implements SolarService {
  FakeSolarService({required this.sunrise, required this.sunset});

  final DateTime sunrise;
  final DateTime sunset;

  /// The location the app passed in, for asserting that precise location
  /// is forwarded when available and omitted when not.
  GeoLocation? lastLocation;

  @override
  Future<SolarEvents> eventsFor({
    required DateTime instant,
    required LocalTimeZone timeZone,
    GeoLocation? location,
  }) async {
    lastLocation = location;
    return SolarEvents(sunrise: sunrise, sunset: sunset);
  }
}

/// A few real places, for hemisphere and time-zone coverage.
abstract final class TestLocations {
  /// London: northern hemisphere, near zero meridian.
  static const london = GeoLocation(latitude: 51.5, longitude: -0.13);

  /// Wellington: southern hemisphere, well ahead of UTC. The primary
  /// New Zealand case the app has to get right.
  static const wellington = GeoLocation(latitude: -41.29, longitude: 174.78);

  /// Sydney: southern hemisphere.
  static const sydney = GeoLocation(latitude: -33.87, longitude: 151.21);

  /// Quito: effectively on the equator, for the boundary rule.
  static const equator = GeoLocation(latitude: 0, longitude: -78.47);
}

/// Matching time zones, kept separate from position — as the app does.
abstract final class TestTimeZones {
  static const london = LocalTimeZone(Duration());
  static const wellington = LocalTimeZone(Duration(hours: 13));
  static const sydney = LocalTimeZone(Duration(hours: 11));
}
