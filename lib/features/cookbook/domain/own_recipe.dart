import 'package:flutter/foundation.dart';

/// A recipe the user keeps for themselves.
///
/// **Deliberately smaller than a catalogue [Recipe].** It has no season,
/// no timings and no serving count, because nobody writing down the soup
/// they always make should have to invent any of that to save it. A
/// name, what goes in, what to do, and anything worth remembering.
///
/// It is never mixed into the seasonal collections: those are the
/// Almanac's own sixteen, chosen for the season, and a user's recipe is
/// theirs whatever the time of year.
@immutable
class OwnRecipe {
  const OwnRecipe({
    required this.id,
    required this.order,
    required this.title,
    this.ingredients = const [],
    this.method = const [],
    this.note,
  });

  /// Stable identity, so an edit changes this recipe and no other.
  final String id;

  /// When it was added, relative to the others: the newest is shown
  /// first. A counter rather than a clock reading, so two recipes can
  /// never share a place.
  final int order;

  final String title;

  /// One line per ingredient, exactly as written.
  final List<String> ingredients;

  /// One line per step, exactly as written.
  final List<String> method;

  final String? note;

  OwnRecipe copyWith({
    String? title,
    List<String>? ingredients,
    List<String>? method,
    String? note,
    bool clearNote = false,
  }) => OwnRecipe(
    id: id,
    order: order,
    title: title ?? this.title,
    ingredients: ingredients ?? this.ingredients,
    method: method ?? this.method,
    note: clearNote ? null : (note ?? this.note),
  );

  @override
  bool operator ==(Object other) =>
      other is OwnRecipe &&
      other.id == id &&
      other.order == order &&
      other.title == title &&
      listEquals(other.ingredients, ingredients) &&
      listEquals(other.method, method) &&
      other.note == note;

  @override
  int get hashCode => Object.hash(
    id,
    order,
    title,
    Object.hashAll(ingredients),
    Object.hashAll(method),
    note,
  );
}

/// Everything the user has written down. A value: every change returns
/// a new one.
@immutable
class OwnRecipes {
  const OwnRecipes(this.recipes);

  static const empty = OwnRecipes([]);

  final List<OwnRecipe> recipes;

  bool get isEmpty => recipes.isEmpty;
  int get length => recipes.length;

  /// Most recently added first.
  List<OwnRecipe> get newestFirst =>
      [...recipes]..sort((a, b) => b.order.compareTo(a.order));

  /// The place the next recipe takes.
  int get nextOrder =>
      recipes.fold(-1, (max, r) => r.order > max ? r.order : max) + 1;

  OwnRecipe? find(String id) {
    for (final recipe in recipes) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  OwnRecipes adding(OwnRecipe recipe) => OwnRecipes([...recipes, recipe]);

  OwnRecipes updating(OwnRecipe recipe) => OwnRecipes([
    for (final existing in recipes)
      existing.id == recipe.id ? recipe : existing,
  ]);

  OwnRecipes removing(String id) => OwnRecipes([
    for (final r in recipes)
      if (r.id != id) r,
  ]);
}

/// Text typed one item per line, as a list: each line trimmed, and blank
/// lines dropped, so an extra return between steps is not an empty step.
List<String> linesOf(String text) => [
  for (final line in text.split('\n'))
    if (line.trim() case final trimmed when trimmed.isNotEmpty) trimmed,
];
