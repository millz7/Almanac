import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/recipe_catalogue.dart';
import '../cookbook_text.dart';
import 'season_sprig.dart';

/// One recipe, on a card the colour of its season.
///
/// A recipe card, not a photograph in a grid: a small drawn sprig, the
/// name, one line about it, and roughly how long it takes. The ground is
/// the season's own wash — see [seasonWash], which backs the tint off
/// until body text on it is comfortably legible — so a winter recipe
/// still feels like winter in midsummer.
///
/// One semantic button, labelled with everything the card shows: "Pumpkin
/// soup. Autumn recipe. A simple warming soup, smooth and golden."
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.variant,
    required this.growth,
    required this.onTap,
  });

  final Recipe recipe;

  /// Which of the four in its collection this is, so the sprigs differ.
  final int variant;

  /// How far the sprig has grown in.
  final double growth;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final wash = seasonWash(palette, recipe.season);

    return Semantics(
      button: true,
      label: recipe.cardLabel,
      excludeSemantics: true,
      child: Material(
        color: wash,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SeasonSprig(
                  season: recipe.season,
                  variant: variant,
                  growth: growth,
                ),
                const SizedBox(width: AppSpacing.md),
                // The words take whatever room is left and wrap, so a
                // recipe name is never shortened.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipe.name, style: textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(recipe.description, style: textTheme.bodyMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        CookbookText.totalTime(recipe),
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
