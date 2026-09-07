import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cycle_data.dart';
import 'cycle_store.dart';

/// The real cycle store, backed by Android's shared preferences.
///
/// No new dependency, and no database: the whole of this feature's data
/// is a short list of `YYYY-MM-DD` strings and one integer, which
/// preferences hold perfectly well. Adding SQLite for that would be a
/// larger decision than the data justifies.
///
/// It has its **own** two keys and its own allow-list, so it can neither
/// see nor touch anything the settings store owns — and the settings
/// store cannot see these. Opening happens on first use rather than at
/// startup, so somebody who never opens Cycle never has their cycle
/// dates read into memory at all.
class SharedPreferencesCycleStore implements CycleStore {
  SharedPreferencesCycleStore();

  static const _startsKey = 'cycle.periodStarts';
  static const _lengthKey = 'cycle.assumedCycleLength';

  /// Everything this store may read or write, and nothing else.
  static const keys = <String>{_startsKey, _lengthKey};

  Future<SharedPreferencesWithCache>? _opening;

  Future<SharedPreferencesWithCache> _open() =>
      _opening ??= SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(allowList: keys),
      );

  @override
  Future<CycleData> read() async {
    try {
      final preferences = await _open();
      return CycleData(
        periodStarts: parseStoredStarts(
          preferences.getStringList(_startsKey) ?? const [],
        ),
        assumedCycleLength:
            preferences.getInt(_lengthKey) ?? kDefaultCycleLength,
      );
    } on Object catch (error) {
      // The failure, never the data.
      debugPrint('Cycle data could not be read: ${error.runtimeType}');
      return CycleData.empty;
    }
  }

  @override
  Future<void> write(CycleData data) async {
    final preferences = await _open();
    await preferences.setStringList(_startsKey, encodeStarts(data));
    await preferences.setInt(_lengthKey, data.assumedCycleLength);
  }

  @override
  Future<void> deleteAll() async {
    final preferences = await _open();
    // Both keys, so nothing is left behind — not the dates, and not the
    // length that was chosen to estimate them with.
    for (final key in keys) {
      await preferences.remove(key);
    }
  }
}
