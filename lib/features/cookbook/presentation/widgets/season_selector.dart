import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/recipe_catalogue.dart';
import '../cookbook_text.dart';

/// Four seasons to browse, with the user's own marked.
///
/// The chosen one is carried by four things at once — a filled ground, a
/// heavier border, a tick, and the selected state a screen reader reads —
/// so colour is never doing the work on its own. The user's actual season
/// says "Your season" in words for the same reason.
///
/// Browsing another season is only browsing: it changes what this screen
/// lists and nothing else in the app.
class SeasonSelector extends StatelessWidget {
  const SeasonSelector({
    super.key,
    required this.selected,
    required this.current,
    required this.onSelected,
  });

  /// The season being browsed.
  final Season selected;

  /// The season the Environment resolved for the user.
  final Season current;

  final ValueChanged<Season> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final season in Season.values)
          _SeasonChip(
            season: season,
            selected: season == selected,
            isCurrent: season == current,
            onTap: () => onSelected(season),
          ),
      ],
    );
  }
}

class _SeasonChip extends StatelessWidget {
  const _SeasonChip({
    required this.season,
    required this.selected,
    required this.isCurrent,
    required this.onTap,
  });

  final Season season;
  final bool selected;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: CookbookText.seasonLabel(season, isCurrent: isCurrent),
      excludeSemantics: true,
      child: Material(
        color: selected ? palette.primarySoft : palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: selected ? palette.primary : palette.border,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimens.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A second, non-colour signal that this is the one
                  // being browsed.
                  if (selected) ...[
                    Icon(
                      Icons.check,
                      size: AppIconSize.sm,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        season.label,
                        style: textTheme.labelLarge?.copyWith(
                          color: selected
                              ? palette.onPrimarySoft
                              : palette.textPrimary,
                        ),
                      ),
                      // Said in words, so nobody has to notice a tint to
                      // know which season is theirs.
                      if (isCurrent)
                        Text(
                          CookbookText.yourSeason,
                          style: textTheme.bodySmall?.copyWith(
                            color: selected
                                ? palette.onPrimarySoft
                                : palette.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
