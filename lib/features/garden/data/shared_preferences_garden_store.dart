import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/my_garden.dart';
import 'garden_store.dart';

/// The real garden store, backed by Android's shared preferences.
///
/// No new dependency and no database: My Garden is a short list of
/// lines, which preferences hold perfectly well. It has its own key
/// under its own prefix, so it can neither see nor touch anything the
/// settings or cycle stores own.
///
/// Opened on first use rather than at startup, so somebody who never
/// opens Garden never has their garden read into memory.
class SharedPreferencesGardenStore implements GardenStore {
  SharedPreferencesGardenStore();

  static const _plantsKey = 'garden.plants';

  /// Everything this store may read or write, and nothing else.
  static const keys = <String>{_plantsKey};

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
  Future<MyGarden> read() async {
    try {
      final preferences = await _open();
      final lines = preferences.getStringList(_plantsKey) ?? const [];
      final value = decodeGarden(lines);
      _unread = [
        for (final line in lines)
          if (decodeGardenPlant(line) == null) line,
      ];
      _unreadable = false;
      return value;
    } on Object catch (error) {
      // The failure, never the contents.
      debugPrint('Garden could not be read: ${error.runtimeType}');
      _unreadable = true;
      return MyGarden.empty;
    }
  }

  @override
  Future<void> write(MyGarden garden) async {
    if (_unreadable) {
      throw StateError('Stored garden could not be read; not overwriting');
    }
    final preferences = await _open();
    await preferences.setStringList(_plantsKey, [
      ...encodeGarden(garden),
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
