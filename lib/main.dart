import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/settings/settings_providers.dart';
import 'core/settings/shared_preferences_settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Settings are opened before the app is built so the very first frame
  // already knows whether the user has chosen a hemisphere. That avoids a
  // flash of onboarding for someone who set it up months ago.
  final settingsStore = await openSettingsStore();

  runApp(
    ProviderScope(
      overrides: [settingsStoreProvider.overrideWithValue(settingsStore)],
      child: const AlmanacApp(),
    ),
  );
}
