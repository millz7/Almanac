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

  Future<SharedPreferencesWithCache> _open() =>
      _opening ??= SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(allowList: keys),
      );

  @override
  Future<MyGarden> read() async {
    try {
      final preferences = await _open();
      return decodeGarden(preferences.getStringList(_plantsKey) ?? const []);
    } on Object catch (error) {
      // The failure, never the contents.
      debugPrint('Garden could not be read: ${error.runtimeType}');
      return MyGarden.empty;
    }
  }

  @override
  Future<void> write(MyGarden garden) async {
    final preferences = await _open();
    await preferences.setStringList(_plantsKey, encodeGarden(garden));
  }

  @override
  Future<void> deleteAll() async {
    final preferences = await _open();
    for (final key in keys) {
      await preferences.remove(key);
    }
  }
}
