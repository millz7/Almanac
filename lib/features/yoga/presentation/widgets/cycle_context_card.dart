import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/yoga_practices.dart';

/// The small contextual area Yoga shows when today is worth mentioning.
///
/// **One Almanac, several views of the same day.** Cycle Syncing and the
/// Wheel of the Year may both be looking at today; this is where Yoga
/// answers. A quiet block above the usual choices, not a redesign: the
/// three practices below it are unchanged and all still offered.
///
/// **Context-agnostic on purpose.** It is handed a heading, a practice
/// and a line — so a cycle phase and a festival use the same card and
/// neither context has a card of its own to drift from the other. Yoga
/// may show more than one of these at once; they are separate
/// observations and never one claim.
///
/// The button selects one of the three practices that already exist. It
/// starts nothing and opens nothing new.
class CycleContextCard extends StatelessWidget {
  const CycleContextCard({
    super.key,
    required this.heading,
    required this.practice,
    required this.invitation,
    required this.onBegin,
  });

  /// "For your menstrual phase", "For today", "Beltane".
  final String heading;

  /// One of the three existing practices.
  final YogaPractice practice;

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
        Text(practice.name, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(invitation, style: textTheme.journalNote),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            container: true,
            button: true,
            label: 'Begin ${practice.name}',
            excludeSemantics: true,
            child: TextButton(
              onPressed: onBegin,
              child: Text('Begin ${practice.name}'),
            ),
          ),
        ),
        const AlmanacSectionDivider(spacing: AppSpacing.lg),
      ],
    );
  }
}
