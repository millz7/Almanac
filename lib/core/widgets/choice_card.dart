import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// A large, calm, tappable choice.
///
/// Built for decisions that deserve room to breathe rather than a row of
/// radio buttons — currently the hemisphere choice in onboarding.
///
/// Accessibility notes: the whole card is one button with a single
/// semantic label, its height clears the minimum touch target several
/// times over, and the selected state is carried by a border, a fill and
/// a check icon, never by colour alone.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    required this.onPressed,
    this.description,
    this.icon,
    this.selected = false,
    this.enabled = true,
  });

  final String title;

  /// A short supporting line. Kept optional so the control can stay bare.
  final String? description;

  final IconData? icon;
  final VoidCallback onPressed;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    final foreground = enabled ? palette.textPrimary : palette.onDisabled;
    // Unselected options are the page itself with a hairline round them;
    // only the chosen one is tinted. A page of filled boxes is a
    // settings app, and the difference between "an option" and "the
    // option you picked" should be the loudest thing here.
    final background = selected ? palette.primarySoft : Colors.transparent;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: description == null ? title : '$title. $description',
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(
            color: selected
                ? palette.primary
                : palette.border.withValues(alpha: 0.6),
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppIconSize.lg, color: palette.icon),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.chapterTitle?.copyWith(
                          fontSize: 20,
                          color: foreground,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(description!, style: textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                // A second, non-colour signal that this option is chosen.
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: palette.primary,
                      size: AppIconSize.md,
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
