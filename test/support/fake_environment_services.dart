import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:almanac/core/environment/location_service.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/solar_service.dart';
import 'package:almanac/core/environment/time_zone_service.dart';

/// A location service that reports whatever the test wants, and records
/// whether the app prompted or merely checked.
class FakeLocationService implements LocationService {
  FakeLocationService({
    this.checkResult = const LocationPermissionNotRequested(),
    LocationState? requestResult,
    this.canOpenSettings = true,
  }) : requestResult = requestResult ?? checkResult;

  /// What a non-prompting check reports.
  LocationState checkResult;

  /// What the prompting request reports.
  LocationState requestResult;

  final bool canOpenSettings;

  /// How many times each entry point was used, so tests can assert the
  /// app never prompts on its own and never re-reads a fresh position.
  int checkCount = 0;
  int requestCount = 0;
  int openSettingsCount = 0;

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

  @override
  Future<bool> openSystemSettings() async {
    openSettingsCount++;
    return canOpenSettings;
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

  @override
  Future<bool> openSystemSettings() async =>
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
/// tested without depending on the real solar calculation.
class FakeSolarService implements SolarService {
  FakeSolarService({this.sunrise, this.sunset, this.kind});

  final DateTime? sunrise;
  final DateTime? sunset;

  /// Force a polar-day/polar-night answer instead of times.
  final SolarDayKind? kind;

  /// What the app passed in, for asserting that precise location is
  /// forwarded when available and omitted when not.
  GeoLocation? lastLocation;
  LocalTimeZone? lastTimeZone;

  @override
  Future<SolarEvents> eventsFor({
    required DateTime instant,
    required LocalTimeZone timeZone,
    GeoLocation? location,
  }) async {
    lastLocation = location;
    lastTimeZone = timeZone;

    if (kind == SolarDayKind.sunNeverRises) {
      return const SolarEvents.sunNeverRises();
    }
    if (kind == SolarDayKind.sunNeverSets) {
      return const SolarEvents.sunNeverSets();
    }
    if (sunrise == null || sunset == null) {
      return const SolarEvents.locationRequired();
    }
    return SolarEvents.risesAndSets(sunrise: sunrise!, sunset: sunset!);
  }
}

/// A few real places, for hemisphere and time-zone coverage.
///
/// Test data only — none of these appears in the production app.
abstract final class TestLocations {
  /// Wellington, New Zealand: southern hemisphere, well ahead of UTC and
  /// daylight-saving observing. The primary case the app has to get right.
  static const wellington = GeoLocation(
    latitude: -41.2866,
    longitude: 174.7756,
  );

  /// London: northern hemisphere, near the zero meridian, also
  /// daylight-saving observing.
  static const london = GeoLocation(latitude: 51.5074, longitude: -0.1278);

  /// Sydney: southern hemisphere.
  static const sydney = GeoLocation(latitude: -33.8688, longitude: 151.2093);

  /// Quito: effectively on the equator, for the boundary rule.
  static const equator = GeoLocation(latitude: 0, longitude: -78.4678);

  /// Tromsø, Norway: inside the Arctic circle, so it has both polar
  /// nights and midnight sun.
  static const tromso = GeoLocation(latitude: 69.6492, longitude: 18.9553);
}

/// Matching IANA time zones, kept separate from position — as the app
/// does.
///
/// Each getter loads the database first, so a test can reach for a zone
/// while declaring its groups, before any `setUp` has run.
abstract final class TestTimeZones {
  static LocalTimeZone _zone(String id) {
    useTimeZoneDatabase();
    return LocalTimeZone.byName(id);
  }

  static LocalTimeZone get wellington => _zone('Pacific/Auckland');
  static LocalTimeZone get london => _zone('Europe/London');
  static LocalTimeZone get sydney => _zone('Australia/Sydney');

  /// Tromsø's zone. tzdata links Europe/Oslo to Europe/Berlin, and
  /// the two keep identical offsets (CET/CEST).
  static LocalTimeZone get tromso => _zone('Europe/Berlin');
  static LocalTimeZone get utc => LocalTimeZone.utc;
}

bool _databaseLoaded = false;

/// Loads the IANA database once per test process. Safe to call from
/// anywhere; repeated calls do nothing.
void useTimeZoneDatabase() {
  if (_databaseLoaded) return;
  initializeTimeZoneDatabase();
  _databaseLoaded = true;
}
