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

  Future<SharedPreferencesWithCache> _open() =>
      _opening ??= SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(allowList: keys),
      );

  @override
  Future<OwnRecipes> read() async {
    try {
      final preferences = await _open();
      return decodeOwnRecipes(
        preferences.getStringList(_recipesKey) ?? const [],
      );
    } on Object catch (error) {
      // The failure, never the contents.
      debugPrint('Own recipes could not be read: ${error.runtimeType}');
      return OwnRecipes.empty;
    }
  }

  @override
  Future<void> write(OwnRecipes recipes) async {
    final preferences = await _open();
    await preferences.setStringList(_recipesKey, encodeOwnRecipes(recipes));
  }

  @override
  Future<void> deleteAll() async {
    final preferences = await _open();
    for (final key in keys) {
      await preferences.remove(key);
    }
  }
}
