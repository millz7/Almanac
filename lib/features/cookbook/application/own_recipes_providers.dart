import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/own_recipe_store.dart';
import '../data/shared_preferences_own_recipe_store.dart';
import '../domain/own_recipe.dart';

export '../data/own_recipe_store.dart';
export '../domain/own_recipe.dart';

/// Where the user's own recipes are kept. Tests override it; the app
/// uses the preferences-backed store, opened lazily on first use.
final ownRecipeStoreProvider = Provider<OwnRecipeStore>(
  (ref) => SharedPreferencesOwnRecipeStore(),
);

/// The user's own recipes, and the only way to change them.
final ownRecipesProvider =
    AsyncNotifierProvider<OwnRecipesController, OwnRecipes>(
      OwnRecipesController.new,
    );

class OwnRecipesController extends AsyncNotifier<OwnRecipes> {
  @override
  Future<OwnRecipes> build() => ref.read(ownRecipeStoreProvider).read();

  OwnRecipes get _recipes => state.value ?? OwnRecipes.empty;

  /// Adds a recipe and returns its id, so the page can open it.
  ///
  /// Text is kept as written, apart from trimming: the app does not
  /// tidy, rename or "improve" anybody's recipe.
  Future<String> add({
    required String title,
    List<String> ingredients = const [],
    List<String> method = const [],
    String? note,
  }) async {
    final order = _recipes.nextOrder;
    // The order makes it unique without a random number or a clock.
    final id = 'own-$order';
    await _persist(
      _recipes.adding(
        OwnRecipe(
          id: id,
          order: order,
          title: title.trim(),
          ingredients: ingredients,
          method: method,
          note: _clean(note),
        ),
      ),
    );
    return id;
  }

  /// Replaces a recipe's words. A blank note clears it.
  Future<void> edit(
    String id, {
    required String title,
    required List<String> ingredients,
    required List<String> method,
    String? note,
  }) {
    final existing = _recipes.find(id);
    if (existing == null) return Future.value();
    final cleaned = _clean(note);
    return _persist(
      _recipes.updating(
        existing.copyWith(
          title: title.trim(),
          ingredients: ingredients,
          method: method,
          note: cleaned,
          clearNote: cleaned == null,
        ),
      ),
    );
  }

  Future<void> remove(String id) => _persist(_recipes.removing(id));

  /// Writes first, then updates what the screen shows, so the app never
  /// displays a change that was not stored.
  Future<void> _persist(OwnRecipes next) async {
    await ref.read(ownRecipeStoreProvider).write(next);
    state = AsyncData(next);
  }

  static String? _clean(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
