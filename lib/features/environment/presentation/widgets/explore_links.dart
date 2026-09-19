import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/features/feature_registry.dart';
import '../../../../app/navigation/navigation_labels.dart';
import '../../../../core/settings/settings_providers.dart';
import '../../../../core/widgets/widgets.dart';

/// Quiet links onward to the rest of the user's own Almanac.
///
/// Only the parts they have actually chosen, taken from the same
/// preferences the navigation bar reads, and absent entirely for somebody
/// who chose none — an empty "Elsewhere" heading would be worse than no
/// heading.
///
/// **And absent when the bar already shows them all.** On a wide screen
/// every destination is visible along the bottom, and listing the same
/// seven names again directly above it is duplication, not a way
/// onward. The bar is the navigation; this is a footnote for when the
/// bar has had to hide some of it behind a scroll.
class ExploreLinks extends ConsumerWidget {
  const ExploreLinks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = ref.watch(userSettingsProvider).chosenFeatures;
    if (chosen.isEmpty) return const SizedBox.shrink();

    // The bar carries the Environment plus every chosen feature. If it
    // can show them all at once, this section has nothing to add.
    final layout = resolveNavigationLayout(
      destinations: [FeatureRegistry.byId(FeatureId.environment), ...chosen],
      available: MediaQuery.sizeOf(context).width,
      style: Theme.of(context).textTheme.navigationLabel ?? const TextStyle(),
      textScaler: MediaQuery.textScalerOf(context),
    );
    if (!layout.scrollable) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AlmanacSectionLabel(label: 'Elsewhere in your Almanac'),
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
