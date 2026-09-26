import 'dart:convert';

import '../domain/own_recipe.dart';

/// Keeps the user's own recipes on this device.
///
/// Its own store, its own key, its own delete — the same shape as the
/// Cycle's, the Garden's and the Nature Log's. A recipe somebody wrote
/// down is theirs; it has nothing to do with app preferences.
///
/// Local only. There is no remote implementation, no account and no
/// sync, and nothing here touches the network.
abstract interface class OwnRecipeStore {
  /// Reads what is stored. Returns nothing rather than throwing: a
  /// device that cannot read its own preferences should still show the
  /// Cookbook.
  Future<OwnRecipes> read();

  /// Persists [recipes]. Throws if it could not be written, so a caller
  /// never reports a save that did not happen.
  Future<void> write(OwnRecipes recipes);

  /// Removes every trace of the user's recipes from storage.
  Future<void> deleteAll();
}

/// A store that keeps recipes only for the lifetime of the process.
class InMemoryOwnRecipeStore implements OwnRecipeStore {
  InMemoryOwnRecipeStore([OwnRecipes? recipes])
    : _recipes = recipes ?? OwnRecipes.empty;

  OwnRecipes _recipes;

  @override
  Future<OwnRecipes> read() async => _recipes;

  @override
  Future<void> write(OwnRecipes recipes) async => _recipes = recipes;

  @override
  Future<void> deleteAll() async => _recipes = OwnRecipes.empty;
}

/// One recipe, as a single stored line of JSON.
///
/// JSON, like the Nature Log, because every field is free text. One
/// line per recipe, so a line that will not parse costs that recipe and
/// nothing more.
String encodeOwnRecipe(OwnRecipe recipe) => jsonEncode(
  <String, Object?>{
    'id': recipe.id,
    'order': recipe.order,
    'title': recipe.title,
    'ingredients': recipe.ingredients,
    'method': recipe.method,
    'note': recipe.note,
  }..removeWhere((_, value) => value == null),
);

/// Reads one stored line, or null if it cannot be trusted.
OwnRecipe? decodeOwnRecipe(String line) {
  final Object? parsed;
  try {
    parsed = jsonDecode(line);
  } on FormatException {
    return null;
  }
  if (parsed is! Map<String, dynamic>) return null;

  final id = parsed['id'];
  final order = parsed['order'];
  final title = parsed['title'];
  if (id is! String || id.isEmpty) return null;
  if (order is! int) return null;
  if (title is! String || title.trim().isEmpty) return null;

  List<String> lines(Object? value) => value is List
      ? [
          for (final line in value)
            if (line is String) line,
        ]
      : const [];

  final note = parsed['note'];
  return OwnRecipe(
    id: id,
    order: order,
    title: title,
    ingredients: lines(parsed['ingredients']),
    method: lines(parsed['method']),
    note: note is String && note.trim().isNotEmpty ? note : null,
  );
}

/// Reads a whole stored collection. Should two lines ever claim one id —
/// only possible if the file was damaged — the first is kept, so an edit
/// or a delete can never reach two recipes at once.
OwnRecipes decodeOwnRecipes(List<String> lines) {
  final seen = <String>{};
  return OwnRecipes([
    for (final line in lines)
      if (decodeOwnRecipe(line) case final recipe?)
        if (seen.add(recipe.id)) recipe,
  ]);
}

List<String> encodeOwnRecipes(OwnRecipes recipes) => [
  for (final recipe in recipes.recipes) encodeOwnRecipe(recipe),
];
