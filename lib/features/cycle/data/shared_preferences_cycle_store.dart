import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/context/cycle_phase.dart';
import '../domain/cycle_data.dart';
import 'cycle_store.dart';

/// The real cycle store, backed by Android's shared preferences.
///
/// No new dependency, and no database: the whole of this feature's data
/// is a short list of `YYYY-MM-DD|level|start` lines, an integer and an
/// optional word. Adding SQLite for that would be a larger decision than
/// the data justifies.
///
/// It has its **own** keys and its own allow-list, so it can neither see
/// nor touch anything the settings store owns — and the settings store
/// cannot see these. Opening happens on first use rather than at
/// startup, so somebody who never opens Cycle never has their cycle
/// dates read into memory at all.
///
/// **Migration from Step 11.** An installation may hold
/// `cycle.periodStarts`, which recorded only the days a period began.
/// [read] turns each of those into one day of recorded bleeding marked
/// as that period's day 1 — see [migrateLegacyStarts] — writes the new
/// key, and clears the old one. Because the old key is removed as part
/// of the same write, the migration happens once and re-reading finds
/// nothing left to migrate. If the write fails the old key survives, so
/// the next launch tries again rather than losing the data.
class SharedPreferencesCycleStore implements CycleStore {
  SharedPreferencesCycleStore();

  /// Step 11's key. Read for migration, then removed; never written.
  static const _legacyStartsKey = 'cycle.periodStarts';

  static const _recordsKey = 'cycle.dayRecords';
  static const _lengthKey = 'cycle.assumedCycleLength';
  static const _manualPhaseKey = 'cycle.manualPhase';

  /// Everything this store may read or write, and nothing else. The
  /// legacy key is in here because migrating it means reading and
  /// removing it.
  static const keys = <String>{
    _legacyStartsKey,
    _recordsKey,
    _lengthKey,
    _manualPhaseKey,
  };

  Future<SharedPreferencesWithCache>? _opening;

  Future<SharedPreferencesWithCache> _open() =>
      _opening ??= SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(allowList: keys),
      );

  @override
  Future<CycleData> read() async {
    try {
      final preferences = await _open();
      final length = preferences.getInt(_lengthKey) ?? kDefaultCycleLength;
      final manual = preferences.getString(_manualPhaseKey);

      final stored = preferences.getStringList(_recordsKey);
      final legacy = preferences.getStringList(_legacyStartsKey);

      // Nothing to migrate: the ordinary path, and the one every launch
      // after the first takes.
      if (legacy == null || legacy.isEmpty) {
        return CycleData(
          records: decodeRecords(stored ?? const []),
          assumedCycleLength: length,
          manualPhase: manual == null ? null : CyclePhase.tryParse(manual),
        );
      }

      final migrated = CycleData(
        records: [
          ...decodeRecords(stored ?? const []),
          ...migrateLegacyStarts(parseStoredStarts(legacy)),
        ],
        assumedCycleLength: length,
        manualPhase: manual == null ? null : CyclePhase.tryParse(manual),
      );
      await _write(preferences, migrated);
      // Only now, so a failure above leaves the old data to try again.
      await preferences.remove(_legacyStartsKey);
      return migrated;
    } on Object catch (error) {
      // The failure, never the data.
      debugPrint('Cycle data could not be read: ${error.runtimeType}');
      return CycleData.empty;
    }
  }

  @override
  Future<void> write(CycleData data) async => _write(await _open(), data);

  Future<void> _write(
    SharedPreferencesWithCache preferences,
    CycleData data,
  ) async {
    await preferences.setStringList(_recordsKey, encodeRecords(data));
    await preferences.setInt(_lengthKey, data.assumedCycleLength);
    final manual = data.manualPhase;
    if (manual == null) {
      await preferences.remove(_manualPhaseKey);
    } else {
      await preferences.setString(_manualPhaseKey, manual.name);
    }
  }

  @override
  Future<void> deleteAll() async {
    final preferences = await _open();
    // Every key, new and legacy, so nothing is left behind — not the
    // records, not the length they were estimated with, not a chosen
    // phase, and not a migration waiting to happen.
    for (final key in keys) {
      await preferences.remove(key);
    }
  }
}
