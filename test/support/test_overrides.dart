import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:almanac/core/environment/location_service.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/core/settings/settings_store.dart';
import 'package:almanac/core/settings/user_settings.dart';
import 'package:flutter_riverpod/misc.dart';

import 'fake_environment_services.dart';

/// Pins everything time-, place- and storage-dependent so tests are not
/// affected by the real date, the device time zone, or the platform.
///
/// Defaults describe a settled user: mid-July, London, midday, onboarding
/// already finished and location never shared. Tests override only the
/// part they are about.
List<Override> environmentOverrides({
  DateTime? now,
  LocalTimeZone timeZone = TestTimeZones.london,
  DateTime? sunrise,
  DateTime? sunset,
  LocationService? locationService,
  LocationState? locationState,
  SettingsStore? settingsStore,
  Hemisphere? hemisphere = Hemisphere.northern,
  bool locationIntroSeen = true,
  bool refreshEnabled = false,
}) {
  final store =
      settingsStore ??
      InMemorySettingsStore(
        UserSettings(
          hemisphere: hemisphere,
          locationIntroSeen: locationIntroSeen,
        ),
      );

  // Sunrise/sunset default to 06:00–20:00 on the local day that contains
  // `now`, so a test that only changes the date still gets sensible
  // daylight instead of the previous default day's sun.
  final instant = now ?? DateTime.utc(2025, 7, 15, 12);
  final localMidnight = timeZone.midnightOf(instant);

  return [
    // No background refresh timer, so no timers outlive the test.
    environmentRefreshEnabledProvider.overrideWithValue(refreshEnabled),
    settingsStoreProvider.overrideWithValue(store),
    clockProvider.overrideWithValue(() => instant),
    timeZoneProvider.overrideWithValue(timeZone),
    locationServiceProvider.overrideWithValue(
      locationService ??
          FakeLocationService(
            checkResult:
                locationState ?? const LocationPermissionNotRequested(),
          ),
    ),
    // In the running app the controller reaches this state by checking
    // permission after the first frame. Unit tests that read the
    // environment directly never get that far, so start it where the
    // test wants it.
    if (locationState != null)
      locationStateProvider.overrideWith(
        () => FixedLocationController(locationState),
      ),
    solarServiceProvider.overrideWithValue(
      FakeSolarService(
        sunrise: sunrise ?? localMidnight.add(const Duration(hours: 6)),
        sunset: sunset ?? localMidnight.add(const Duration(hours: 20)),
      ),
    ),
  ];
}
