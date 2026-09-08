import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/meditation_technique.dart';

/// The small contextual area Meditation shows when today is worth
/// mentioning.
///
/// **One Almanac, several views of the same day.** The Moon page and
/// Cycle Syncing are both looking at today; this is where Meditation
/// answers. Deliberately a quiet block above the usual choices, not a
/// redesign: the four practices below it are unchanged and all still
/// offered.
///
/// **Context-agnostic on purpose.** It is handed a heading, a practice
/// and a line — so the moon and the cycle use the same card and neither
/// context has a card of its own to drift from the other. Meditation may
/// show two of these at once; they are two observations and never one
/// claim.
///
/// The button selects one of the four practices that already exist. It
/// does not start a session, and it does not open a different screen.
class MoonContextCard extends StatelessWidget {
  const MoonContextCard({
    super.key,
    required this.heading,
    required this.technique,
    required this.invitation,
    required this.onBegin,
  });

  /// "For today's New Moon", "For your luteal phase", "New Moon".
  final String heading;

  /// One of the four practices that already exist.
  final MeditationTechnique technique;

  /// One line. An invitation, not a prescription.
  final String invitation;

  /// Selects the suggested practice, exactly as tapping it in the list
  /// below would.
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

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
        Text(invitation, style: textTheme.journalNote),
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
