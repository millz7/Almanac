import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../environment/geo_location.dart';
import 'settings_store.dart';
import 'user_settings.dart';

/// The real settings store, backed by Android's shared preferences.
///
/// Uses [SharedPreferencesWithCache] so that after one asynchronous
/// [open] every read is synchronous — startup can then decide about
/// onboarding without an intermediate loading state.
class SharedPreferencesSettingsStore implements SettingsStore {
  SharedPreferencesSettingsStore._(this._preferences);

  static const _hemisphereKey = 'settings.hemisphere';
  static const _locationIntroSeenKey = 'settings.locationIntroSeen';

  /// Everything this app is allowed to read or write. Keeping the list
  /// explicit stops unrelated keys being pulled into the cache.
  static const _keys = <String>{_hemisphereKey, _locationIntroSeenKey};

  final SharedPreferencesWithCache _preferences;

  /// Opens the store. Throws if the platform cannot provide preferences —
  /// see [openSettingsStore] for the handling of that.
  static Future<SettingsStore> open() async {
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(allowList: _keys),
    );
    return SharedPreferencesSettingsStore._(preferences);
  }

  @override
  UserSettings read() => UserSettings(
    hemisphere: _readHemisphere(),
    locationIntroSeen: _preferences.getBool(_locationIntroSeenKey) ?? false,
  );

  @override
  Future<void> write(UserSettings settings) async {
    final hemisphere = settings.hemisphere;
    if (hemisphere == null) {
      await _preferences.remove(_hemisphereKey);
    } else {
      await _preferences.setString(_hemisphereKey, hemisphere.name);
    }
    await _preferences.setBool(
      _locationIntroSeenKey,
      settings.locationIntroSeen,
    );
  }

  /// Stored by [Hemisphere.name] rather than by index, so reordering the
  /// enum can never silently flip a user to the other hemisphere. An
  /// unrecognised value is treated as "not chosen", which sends the user
  /// back through onboarding rather than guessing.
  Hemisphere? _readHemisphere() {
    final stored = _preferences.getString(_hemisphereKey);
    if (stored == null) return null;
    for (final hemisphere in Hemisphere.values) {
      if (hemisphere.name == stored) return hemisphere;
    }
    return null;
  }
}

/// Opens the persistent settings store, falling back to an in-memory one
/// if the platform will not provide preferences.
///
/// A device that cannot store preferences should still run the app: the
/// user picks a hemisphere, uses the app normally, and is simply asked
/// again next launch. That is a far better outcome than refusing to start.
Future<SettingsStore> openSettingsStore() async {
  try {
    return await SharedPreferencesSettingsStore.open();
  } on Object catch (error, stackTrace) {
    debugPrint('Falling back to in-memory settings: $error\n$stackTrace');
    return InMemorySettingsStore();
  }
}
