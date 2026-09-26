import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/context/almanac_context.dart';
import '../../../core/widgets/widgets.dart';
import 'maramataka_text.dart';

/// The Māori lunar calendar on the Moon page — only when the user has
/// chosen to include it.
///
/// Kept apart from the astronomy above it: the astronomical phase keeps
/// its own name, and the Maramataka night is shown as a separate thing,
/// never as a renaming of the phase.
class MaramatakaSection extends ConsumerWidget {
  const MaramatakaSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final night = ref.watch(currentMaramatakaProvider);
    // Off: nothing at all, not even a heading.
    if (night == null) return const SizedBox.shrink();

    final moon = ref.watch(currentMoonProvider);
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final label = textTheme.journalLabel?.copyWith(
      color: palette.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AlmanacSectionDivider(spacing: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text(MaramatakaText.heading, style: textTheme.headlineSmall),
        ),
        Text(
          MaramatakaText.subheading,
          style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(MaramatakaText.estimatedNight, style: label),
        const SizedBox(height: AppSpacing.xs),
        Text(night.name, style: textTheme.titleLarge),
        Text(
          MaramatakaText.position(night),
          style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
        ),

        const SizedBox(height: AppSpacing.lg),
        Text(MaramatakaText.astronomicalRelationship, style: label),
        const SizedBox(height: AppSpacing.xs),
        Text(MaramatakaText.relationship(moon), style: textTheme.bodyMedium),

        const SizedBox(height: AppSpacing.lg),
        Text(MaramatakaText.aboutThisNight, style: label),
        const SizedBox(height: AppSpacing.xs),
        Text(MaramatakaText.quoted(night), style: textTheme.journalNote),

        if (night.associations.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(MaramatakaText.associatedWith, style: label),
          const SizedBox(height: AppSpacing.xs),
          for (final association in night.associations)
            Text(association, style: textTheme.bodyMedium),
        ],

        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.push(kMaramatakaRoute),
            child: const Text(MaramatakaText.explore),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const MaramatakaNotes(),
      ],
    );
  }
}

/// The quiet notes that go wherever Maramataka content does: that
/// traditions vary, that the night is an estimate, and whose words these
/// are.
class MaramatakaNotes extends StatelessWidget {
  const MaramatakaNotes({super.key, this.withBackground = false});

  /// Whether to include Te Papa's general background too.
  final bool withBackground;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final quiet = textTheme.bodySmall?.copyWith(color: palette.textSecondary);
    final label = textTheme.journalLabel?.copyWith(
      color: palette.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Maramataka.variationNote, style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(Maramataka.estimateNote, style: quiet),
        if (withBackground) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(MaramatakaText.background, style: label),
          const SizedBox(height: AppSpacing.xs),
          for (final line in Maramataka.background)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(line, style: textTheme.bodyMedium),
            ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(MaramatakaText.sources, style: label),
        const SizedBox(height: AppSpacing.xs),
        for (final source in MaramatakaSource.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text('${source.name}. ${source.detail}', style: quiet),
          ),
      ],
    );
  }
}
