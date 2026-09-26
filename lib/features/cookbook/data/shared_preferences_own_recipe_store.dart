import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/own_recipe.dart';
import 'own_recipe_store.dart';

/// The real store for the user's own recipes, backed by Android's shared
/// preferences — the same mechanism, and the same shape, as the Garden
/// and the Nature Log. No new dependency and no database.
///
/// Its own key under its own prefix, so it can neither see nor touch
/// anything another store owns. Opened on first use.
class SharedPreferencesOwnRecipeStore implements OwnRecipeStore {
  SharedPreferencesOwnRecipeStore();

  static const _recipesKey = 'cookbook.ownRecipes';

  /// Everything this store may read or write, and nothing else.
  static const keys = <String>{_recipesKey};

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
  Future<OwnRecipes> read() async {
    try {
      final preferences = await _open();
      final lines = preferences.getStringList(_recipesKey) ?? const [];
      final value = decodeOwnRecipes(lines);
      _unread = [
        for (final line in lines)
          if (decodeOwnRecipe(line) == null) line,
      ];
      _unreadable = false;
      return value;
    } on Object catch (error) {
      // The failure, never the contents.
      debugPrint('Own recipes could not be read: ${error.runtimeType}');
      _unreadable = true;
      return OwnRecipes.empty;
    }
  }

  @override
  Future<void> write(OwnRecipes recipes) async {
    if (_unreadable) {
      throw StateError('Stored own recipes could not be read; not overwriting');
    }
    final preferences = await _open();
    await preferences.setStringList(_recipesKey, [
      ...encodeOwnRecipes(recipes),
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
