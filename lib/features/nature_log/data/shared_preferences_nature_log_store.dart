import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/observation.dart';
import 'nature_log_store.dart';

/// The real Nature Log store, backed by Android's shared preferences.
///
/// No new dependency and no database: the log is a list of short JSON
/// lines. It has its own key under its own prefix, so it can neither see
/// nor touch what the settings, cycle or garden stores own.
///
/// Opened on first use rather than at startup, so somebody who never
/// opens the Nature Log never has it read into memory.
class SharedPreferencesNatureLogStore implements NatureLogStore {
  SharedPreferencesNatureLogStore();

  static const _observationsKey = 'natureLog.observations';

  /// Everything this store may read or write, and nothing else.
  static const keys = <String>{_observationsKey};

  Future<SharedPreferencesWithCache>? _opening;

  Future<SharedPreferencesWithCache> _open() =>
      _opening ??= SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(allowList: keys),
      );

  @override
  Future<NatureLog> read() async {
    try {
      final preferences = await _open();
      return decodeLog(preferences.getStringList(_observationsKey) ?? const []);
    } on Object catch (error) {
      // The failure, never the contents.
      debugPrint('Nature Log could not be read: ${error.runtimeType}');
      return NatureLog.empty;
    }
  }

  @override
  Future<void> write(NatureLog log) async {
    final preferences = await _open();
    await preferences.setStringList(_observationsKey, encodeLog(log));
  }

  @override
  Future<void> deleteAll() async {
    final preferences = await _open();
    for (final key in keys) {
      await preferences.remove(key);
    }
  }
}
