import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/moon_meditation.dart';

/// The small contextual area Meditation shows when today's moon is worth
/// mentioning.
///
/// **One Almanac, two views of the same evening.** The Moon page and the
/// Meditation page are looking at the same phase; this is where
/// Meditation says so. It is deliberately a quiet block above the usual
/// choices, not a redesign: the four practices below it are unchanged
/// and all still offered.
///
/// Two ways in, one widget:
///
/// * **Arrived from the Moon** — the heading names the phase, because
///   that is what the user just tapped.
/// * **Opened normally** — the same suggestion, headed "For today", so
///   the moon is mentioned rather than announced.
///
/// The button selects one of the four practices that already exist. It
/// does not start a session, and it does not open a different screen.
class MoonContextCard extends StatelessWidget {
  const MoonContextCard({
    super.key,
    required this.heading,
    required this.suggestion,
    required this.onBegin,
  });

  /// "For today's New Moon", or "For today".
  final String heading;

  final MoonMeditation suggestion;

  /// Selects the suggested practice, exactly as tapping it in the list
  /// below would.
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final technique = MoonMeditations.techniqueFor(suggestion.phase);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: textTheme.journalLabel?.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(technique.name, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(suggestion.invitation, style: textTheme.journalNote),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            container: true,
            button: true,
            label: 'Begin ${technique.name}',
            excludeSemantics: true,
            child: TextButton(
              onPressed: onBegin,
              child: Text('Begin ${technique.name}'),
            ),
          ),
        ),
        const AlmanacSectionDivider(spacing: AppSpacing.lg),
      ],
    );
  }
}
