import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Quiet links onward to the rest of the app.
///
/// Only the four sections that already exist, and each one goes somewhere
/// real — this is not a grid of unbuilt features. They are small pills
/// rather than cards so they read as a footnote to the day, not as a
/// second navigation bar.
class ExploreLinks extends StatelessWidget {
  const ExploreLinks({super.key});

  static const _links = <({IconData icon, String label, String route})>[
    (
      icon: Icons.self_improvement_outlined,
      label: 'Wellbeing',
      route: kWellbeingRoute,
    ),
    (icon: Icons.brightness_3_outlined, label: 'Rhythms', route: kRhythmsRoute),
    (icon: Icons.forest_outlined, label: 'Nature', route: kNatureRoute),
    (icon: Icons.eco_outlined, label: 'Food', route: kFoodRoute),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Elsewhere'),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final link in _links)
              _Pill(
                icon: link.icon,
                label: link.label,
                onTap: () => context.go(link.route),
              ),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
    );

    return Material(
      color: palette.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          // Keeps every pill a comfortable tap target however short its
          // label is.
          constraints: const BoxConstraints(
            minHeight: AppDimens.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AppIconSize.sm, color: palette.icon),
                const SizedBox(width: AppSpacing.sm),
                Text(label, style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
