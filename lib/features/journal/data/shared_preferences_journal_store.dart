import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/journal_entry.dart';
import 'journal_store.dart';

/// The real Journal store, backed by Android's shared preferences.
///
/// No new dependency and no database: the Journal is a list of short
/// JSON lines under its own key, so it can neither see nor touch what
/// any other store owns. Opened on first use rather than at startup.
class SharedPreferencesJournalStore implements JournalStore {
  SharedPreferencesJournalStore();

  static const _entriesKey = 'journal.entries';

  /// Everything this store may read or write, and nothing else.
  static const keys = <String>{_entriesKey};

  Future<SharedPreferencesWithCache>? _opening;

  /// Set when what is stored could not be read at all. While it is set,
  /// [write] refuses: the screen is showing nothing, and saving that
  /// would overwrite every page still on the device.
  bool _unreadable = false;

  /// Stored lines this version could not read. Never shown, but written
  /// back untouched, so saving today's page can never quietly delete one
  /// the app merely did not understand.
  List<String> _unread = const [];

  Future<SharedPreferencesWithCache> _open() =>
      _opening ??= SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(allowList: keys),
      );

  @override
  Future<JournalBook> read() async {
    try {
      final preferences = await _open();
      final lines = preferences.getStringList(_entriesKey) ?? const [];
      final value = decodeJournal(lines);
      _unread = [
        for (final line in lines)
          if (decodeJournalEntry(line) == null) line,
      ];
      _unreadable = false;
      return value;
    } on Object catch (error) {
      // The kind of failure, never the contents.
      debugPrint('Journal could not be read: ${error.runtimeType}');
      _unreadable = true;
      return JournalBook.empty;
    }
  }

  @override
  Future<void> write(JournalBook book) async {
    if (_unreadable) {
      throw StateError('Stored journal could not be read; not overwriting');
    }
    final preferences = await _open();
    await preferences.setStringList(_entriesKey, [
      ...encodeJournal(book),
      ..._unread,
    ]);
  }

  @override
  Future<void> deleteAll() async {
    final preferences = await _open();
    for (final key in keys) {
      await preferences.remove(key);
    }
    _unreadable = false;
    _unread = const [];
  }
}
