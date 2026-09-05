import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../environment/geo_location.dart';
import '../features/feature_registry.dart';
import 'settings_store.dart';
import 'user_settings.dart';

/// The real settings store, backed by Android's shared preferences.
///
/// Uses [SharedPreferencesWithCache] so that after one asynchronous
/// [open] every read is synchronous — startup can then decide about
/// onboarding without an intermediate loading state.
///
/// Everything is stored by *name* rather than by index or ordinal, so
/// reordering an enum can never silently change what somebody chose.
class SharedPreferencesSettingsStore implements SettingsStore {
  SharedPreferencesSettingsStore._(this._preferences);

  static const _nameKey = 'settings.name';
  static const _nameAskedKey = 'settings.nameAsked';
  static const _hemisphereKey = 'settings.hemisphere';
  static const _locationIntroSeenKey = 'settings.locationIntroSeen';
  static const _featuresKey = 'settings.features';
  static const _onboardingCompletedKey = 'settings.onboardingCompleted';

  /// Everything this app is allowed to read or write. Keeping the list
  /// explicit stops unrelated keys being pulled into the cache.
  static const _keys = <String>{
    _nameKey,
    _nameAskedKey,
    _hemisphereKey,
    _locationIntroSeenKey,
    _featuresKey,
    _onboardingCompletedKey,
  };

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
  UserSettings read() {
    final hemisphere = _readHemisphere();
    final locationIntroSeen =
        _preferences.getBool(_locationIntroSeenKey) ?? false;

    return UserSettings(
      name: _readName(),
      nameAsked: _preferences.getBool(_nameAskedKey) ?? false,
      hemisphere: hemisphere,
      locationIntroSeen: locationIntroSeen,
      features: _readFeatures(),
      onboardingCompleted: _readOnboardingCompleted(
        hemisphere: hemisphere,
        locationIntroSeen: locationIntroSeen,
      ),
    );
  }

  @override
  Future<void> write(UserSettings settings) async {
    final name = settings.name;
    if (name == null) {
      await _preferences.remove(_nameKey);
    } else {
      await _preferences.setString(_nameKey, name);
    }
    await _preferences.setBool(_nameAskedKey, settings.nameAsked);

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

    // Written in registry order rather than selection order, so the
    // stored value is stable and diffable.
    await _preferences.setStringList(_featuresKey, [
      for (final feature in FeatureRegistry.optional)
        if (settings.features.contains(feature.id)) feature.id.name,
    ]);
    await _preferences.setBool(
      _onboardingCompletedKey,
      settings.onboardingCompleted,
    );
  }

  /// A blank stored name is treated as no name, so an empty string can
  /// never become the title "'s Almanac".
  String? _readName() {
    final stored = _preferences.getString(_nameKey)?.trim();
    return (stored == null || stored.isEmpty) ? null : stored;
  }

  /// An unrecognised hemisphere is treated as "not chosen", which sends
  /// the user back through onboarding rather than guessing for them.
  Hemisphere? _readHemisphere() {
    final stored = _preferences.getString(_hemisphereKey);
    if (stored == null) return null;
    for (final hemisphere in Hemisphere.values) {
      if (hemisphere.name == stored) return hemisphere;
    }
    return null;
  }

  /// Unrecognised entries are dropped rather than throwing — see
  /// [FeatureId.tryParse]. The Environment is never stored as a chosen
  /// feature, so it is filtered out if an old or hand-edited value
  /// contains it.
  Set<FeatureId> _readFeatures() {
    final stored = _preferences.getStringList(_featuresKey);
    if (stored == null) return const {};

    return {
      for (final entry in stored)
        if (FeatureId.tryParse(entry) case final id?)
          if (id != FeatureId.environment) id,
    };
  }

  /// Whether setup is finished, with a migration for anyone who set the
  /// app up before this question existed.
  ///
  /// Someone who had already chosen a hemisphere and seen the location
  /// explanation has finished the setup that existed at the time. Without
  /// this they would be sent back through onboarding by the arrival of a
  /// key their install has never heard of.
  bool _readOnboardingCompleted({
    required Hemisphere? hemisphere,
    required bool locationIntroSeen,
  }) =>
      _preferences.getBool(_onboardingCompletedKey) ??
      (hemisphere != null && locationIntroSeen);
}

/// Opens the persistent settings store, falling back to an in-memory one
/// if the platform will not provide preferences.
///
/// A device that cannot store preferences should still run the app: the
/// user sets up their Almanac, uses it normally, and is simply asked
/// again next launch. That is a far better outcome than refusing to
/// start.
Future<SettingsStore> openSettingsStore() async {
  try {
    return await SharedPreferencesSettingsStore.open();
  } on Object catch (error, stackTrace) {
    debugPrint('Falling back to in-memory settings: $error\n$stackTrace');
    return InMemorySettingsStore();
  }
}
