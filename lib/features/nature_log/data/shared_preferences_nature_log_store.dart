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

  /// Set when what is stored could not be read at all. While it is set,
  /// [write] refuses: the screen is showing nothing, and saving that
  /// would overwrite what is still on the device.
  bool _unreadable = false;

  /// Stored lines this version could not read — damaged, or written by
  /// a newer version with a category or level this one has never heard
  /// of. Never shown, but written back untouched, so saving something
  /// new can never quietly delete a record the app merely did not
  /// understand.
  List<String> _unread = const [];

  Future<SharedPreferencesWithCache> _open() =>
      _opening ??= SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(allowList: keys),
      );

  @override
  Future<NatureLog> read() async {
    try {
      final preferences = await _open();
      final lines = preferences.getStringList(_observationsKey) ?? const [];
      final value = decodeLog(lines);
      _unread = [
        for (final line in lines)
          if (decodeObservation(line) == null) line,
      ];
      _unreadable = false;
      return value;
    } on Object catch (error) {
      // The failure, never the contents.
      debugPrint('Nature Log could not be read: ${error.runtimeType}');
      _unreadable = true;
      return NatureLog.empty;
    }
  }

  @override
  Future<void> write(NatureLog log) async {
    if (_unreadable) {
      throw StateError('Stored nature log could not be read; not overwriting');
    }
    final preferences = await _open();
    await preferences.setStringList(_observationsKey, [
      ...encodeLog(log),
      ..._unread,
    ]);
  }

  @override
  Future<void> deleteAll() async {
    final preferences = await _open();
    for (final key in keys) {
      await preferences.remove(key);
    }
    // Deliberately emptied: there is nothing left to overwrite.
    _unreadable = false;
    _unread = const [];
  }
}
