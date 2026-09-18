import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app.dart';
import '../core/environment/environment_providers.dart';
import '../core/environment/geo_location.dart';
import '../core/environment/local_time_zone.dart';
import '../core/environment/location_state.dart';
import '../core/environment/time_zone_service.dart';
import '../core/features/feature_registry.dart';
import '../core/settings/settings_providers.dart';
import '../core/settings/settings_store.dart';
import '../core/settings/user_settings.dart';

/// A debug entry point that runs **the real app** at a fixed moment.
///
/// Not a preview screen and not a mock: this is `AlmanacApp`, the same
/// widget `main.dart` runs, with the same providers overridden the way a
/// widget test overrides them — a pinned clock, a real London position,
/// a settled user. Everything downstream is production code, including
/// the real NOAA sunrise/sunset calculation, so what appears on screen is
/// what a user in London would see at that instant.
///
/// It exists so a human (or a headless browser) can *look* at the
/// Environment in each season and each light without waiting six months.
///
///   flutter run -t lib/dev/visual_qa_main.dart \
///     --dart-define=ALMANAC_QA_INSTANT=2025-07-15T11:00:00Z
///
/// On the web the instant can also come from the URL, so one build
/// serves every season and every light:
///
///   .../index.html?at=2025-01-15T22:00:00Z
///
/// Never reachable from the shipped app: nothing imports this file, so it
/// is only ever compiled when it is the target.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeTimeZoneDatabase();

  const defined = String.fromEnvironment(
    'ALMANAC_QA_INSTANT',
    defaultValue: '2025-07-15T11:00:00Z',
  );
  final raw = Uri.base.queryParameters['at'] ?? defined;
  final instant = DateTime.parse(raw).toUtc();

  final zone = LocalTimeZone.byName('Europe/London');

  runApp(
    ProviderScope(
      overrides: [
        // A settled user with every feature chosen, so the navigation bar
        // is inspected at its most crowded.
        settingsStoreProvider.overrideWithValue(
          InMemorySettingsStore(
            UserSettings(
              name: 'Millie',
              nameAsked: true,
              hemisphere: Hemisphere.northern,
              locationIntroSeen: true,
              features: FeatureId.values
                  .where((id) => id != FeatureId.environment)
                  .toSet(),
              onboardingCompleted: true,
            ),
          ),
        ),
        initialTimeZoneProvider.overrideWithValue(zone),
        timeZoneServiceProvider.overrideWithValue(FixedTimeZoneService(zone)),
        clockProvider.overrideWithValue(() => instant),
        // A real position, so sunrise and sunset are really calculated.
        locationStateProvider.overrideWith(_PinnedLocation.new),
        // No refresh timer: the moment is meant to stay still while it is
        // being looked at.
        environmentRefreshEnabledProvider.overrideWithValue(false),
      ],
      child: const AlmanacApp(),
    ),
  );
}

/// London, shared rather than requested. The QA build never touches the
/// platform's location services.
///
/// [refresh] and [requestAccess] are stubbed deliberately: the app asks
/// the controller to re-check permission on every resume, and the
/// inherited implementation would call the real platform, be denied in a
/// browser, and quietly throw the pinned position away — leaving the
/// screen in its no-location state. That is a QA-harness detail, not app
/// behaviour.
class _PinnedLocation extends LocationController {
  static const _london = LocationAvailable(
    GeoLocation(latitude: 51.5074, longitude: -0.1278),
  );

  @override
  LocationState build() => _london;

  @override
  Future<void> refresh({bool force = false}) async {}

  @override
  Future<void> requestAccess() async {}
}

/// The device's zone, pinned.
class FixedTimeZoneService implements TimeZoneService {
  const FixedTimeZoneService(this.zone);

  final LocalTimeZone zone;

  @override
  Future<LocalTimeZone> currentTimeZone() async => zone;
}
