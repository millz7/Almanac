import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:almanac/core/environment/location_service.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/solar_service.dart';
import 'package:almanac/core/environment/time_zone_service.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/core/settings/settings_store.dart';
import 'package:almanac/core/settings/user_settings.dart';
import 'package:almanac/features/cycle/application/cycle_providers.dart';
import 'package:almanac/features/garden/application/garden_providers.dart';
import 'package:flutter_riverpod/misc.dart';

import 'fake_environment_services.dart';

/// Pins everything time-, place- and storage-dependent so tests are not
/// affected by the real date, the machine's time zone, or the platform.
///
/// Defaults describe a settled user: mid-July, London time, midday,
/// onboarding already finished, no name, no chosen features and location
/// never shared. Tests override only the part they are about.
///
/// Pass `onboardingCompleted: false` (and whichever earlier answers are
/// still missing) to land in the middle of first-launch setup.
///
/// Loads the IANA time-zone database as a side effect, since almost every
/// test needs a named zone.
List<Override> environmentOverrides({
  DateTime? now,
  LocalTimeZone? timeZone,
  DateTime? sunrise,
  DateTime? sunset,
  SolarService? solarService,
  LocationService? locationService,
  LocationState? locationState,
  SettingsStore? settingsStore,
  CycleStore? cycleStore,
  GardenStore? gardenStore,
  Hemisphere? hemisphere = Hemisphere.northern,
  bool locationIntroSeen = true,
  bool refreshEnabled = false,
  String? name,
  bool? nameAsked,
  Set<FeatureId> features = const {},
  bool onboardingCompleted = true,
}) {
  useTimeZoneDatabase();

  final zone = timeZone ?? TestTimeZones.london;
  final store =
      settingsStore ??
      InMemorySettingsStore(
        UserSettings(
          name: name,
          // A supplied name implies the question was asked, which is
          // almost always what a test means.
          nameAsked: nameAsked ?? (name != null || onboardingCompleted),
          hemisphere: hemisphere,
          locationIntroSeen: locationIntroSeen,
          features: features,
          onboardingCompleted: onboardingCompleted,
        ),
      );

  // Sunrise/sunset default to 06:00–20:00 on the local day that contains
  // `now`, so a test that only changes the date still gets sensible
  // daylight instead of the previous default day's sun.
  final instant = now ?? DateTime.utc(2025, 7, 15, 12);
  final localMidnight = zone.midnightOf(instant);

  return [
    // No background refresh timer, so no timers outlive the test.
    environmentRefreshEnabledProvider.overrideWithValue(refreshEnabled),
    settingsStoreProvider.overrideWithValue(store),
    // Cycle keeps its data in its own store, so tests get their own
    // empty one rather than the device's preferences.
    cycleStoreProvider.overrideWithValue(cycleStore ?? InMemoryCycleStore()),
    // My Garden likewise keeps its own store, so tests get their own
    // empty one rather than the device's preferences.
    gardenStoreProvider.overrideWithValue(gardenStore ?? InMemoryGardenStore()),
    clockProvider.overrideWithValue(() => instant),
    initialTimeZoneProvider.overrideWithValue(zone),
    timeZoneServiceProvider.overrideWithValue(FixedTimeZoneService(zone)),
    locationServiceProvider.overrideWithValue(
      locationService ??
          FakeLocationService(
            checkResult:
                locationState ?? const LocationPermissionNotRequested(),
          ),
    ),
    solarServiceProvider.overrideWithValue(
      solarService ??
          FakeSolarService(
            sunrise: sunrise ?? localMidnight.add(const Duration(hours: 6)),
            sunset: sunset ?? localMidnight.add(const Duration(hours: 20)),
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
  ];
}
