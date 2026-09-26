import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/almanac_button.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/context/almanac_context.dart';
import '../../../core/widgets/widgets.dart';
import 'maramataka_section.dart';
import 'maramataka_text.dart';

/// Every night of the reference sequence, to read at leisure.
///
/// Educational browsing, so — unlike the Journal — not tied to today:
/// all thirty nights are here, in order, with the one estimated for
/// tonight marked in words as well as by a check mark. Reached only from
/// the Moon page, and only while the Maramataka is switched on.
class MaramatakaScreen extends ConsumerWidget {
  const MaramatakaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Switched off while this page is open: back to the Moon. (Reached
    // by `go` rather than from the Moon, the router's redirect does the
    // same.)
    ref.listen(currentMaramatakaProvider, (_, next) {
      if (next != null) return;
      // After the frame: the router is re-checking its routes for the
      // same change, and a pop in the middle of that would be undone.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
    });
    final tonight = ref.watch(currentMaramatakaProvider);
    if (tonight == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;

    return AlmanacPage(
      title: MaramatakaText.monthTitle,
      onBack: () => context.pop(),
      backLabel: MaramatakaText.back,
      trailing: const AlmanacButton(),
      children: [
        Text(MaramatakaText.subheading, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.md),
        Text(Maramataka.variationNote, style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        for (final night in Maramataka.nights) ...[
          _NightRow(night: night, current: night == tonight),
          const AlmanacRule(spacing: AppSpacing.xs),
        ],
        const SizedBox(height: AppSpacing.lg),
        const MaramatakaNotes(withBackground: true),
      ],
    );
  }
}

class _NightRow extends StatelessWidget {
  const _NightRow({required this.night, required this.current});

  final MaramatakaNight night;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final quiet = textTheme.bodySmall?.copyWith(color: palette.textSecondary);

    return Semantics(
      container: true,
      selected: current,
      label: MaramatakaText.spokenNight(night, current: current),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppDimens.minTouchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: AppSpacing.xl,
                child: Text('${night.order}', style: quiet),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(night.name, style: textTheme.titleMedium),
                        // Said in words, not only by a mark or a colour.
                        if (current) ...[
                          Icon(
                            Icons.check,
                            size: AppIconSize.sm,
                            color: palette.primary,
                          ),
                          Text(
                            MaramatakaText.estimatedTonight,
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                    Text(MaramatakaText.ageRange(night), style: quiet),
                    const SizedBox(height: AppSpacing.xs),
                    Text(night.about, style: textTheme.bodyMedium),
                    for (final association in night.associations)
                      Text(association, style: quiet),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
