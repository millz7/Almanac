import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/features/feature_registry.dart';
import '../../../../core/settings/settings_providers.dart';
import '../../../../core/widgets/widgets.dart';

/// Quiet links onward to the rest of the user's own Almanac.
///
/// Only the parts they have actually chosen, taken from the same
/// preferences the navigation bar reads, and absent entirely for somebody
/// who chose none — an empty "Elsewhere" heading would be worse than no
/// heading. They are small pills rather than cards so they read as a
/// footnote to the day, not as a second navigation bar.
class ExploreLinks extends ConsumerWidget {
  const ExploreLinks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = ref.watch(userSettingsProvider).chosenFeatures;
    if (chosen.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Elsewhere in your Almanac'),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final feature in chosen)
              _Pill(feature: feature, onTap: () => context.go(feature.route)),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.feature, required this.onTap});

  final FeatureDefinition feature;
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
                Icon(feature.icon, size: AppIconSize.sm, color: palette.icon),
                const SizedBox(width: AppSpacing.sm),
                // The full name: there is room here, unlike in the bar.
                Text(
                  feature.name,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
