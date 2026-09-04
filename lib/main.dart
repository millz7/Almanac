import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/environment/environment_providers.dart';
import 'core/environment/time_zone_service.dart';
import 'core/settings/settings_providers.dart';
import 'core/settings/shared_preferences_settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The IANA time-zone database has to be in memory before any zone can
  // be looked up.
  initializeTimeZoneDatabase();

  // Settings and the device's time zone are resolved before the app is
  // built, so the very first frame already knows whether the user has
  // chosen a hemisphere and what their local day looks like. That avoids
  // both a flash of onboarding for someone who set it up months ago and a
  // flash of the wrong day/night palette.
  const timeZoneService = PlatformTimeZoneService();
  final settingsStore = await openSettingsStore();
  final timeZone = await timeZoneService.currentTimeZone();

  runApp(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(settingsStore),
        initialTimeZoneProvider.overrideWithValue(timeZone),
        timeZoneServiceProvider.overrideWithValue(timeZoneService),
      ],
      child: const AlmanacApp(),
    ),
  );
}
