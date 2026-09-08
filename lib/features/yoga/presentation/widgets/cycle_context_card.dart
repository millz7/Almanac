import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/cycle_yoga.dart';
import '../../domain/yoga_practices.dart';

/// The small contextual area Yoga shows when a cycle phase is worth
/// mentioning.
///
/// **One Almanac, two views of the same day.** Cycle Syncing and Yoga
/// are looking at the same phase; this is where Yoga answers. A quiet
/// block above the usual choices, not a redesign: the three practices
/// below it are unchanged and all still offered.
///
/// Two ways in, one widget. Arrived from Cycle Syncing, the heading
/// names the phase, because that is what the user just tapped. Opened
/// normally, the same suggestion appears headed "For today", so the
/// context is mentioned rather than announced.
///
/// The button selects one of the three practices that already exist. It
/// starts nothing and opens nothing new.
class CycleContextCard extends StatelessWidget {
  const CycleContextCard({
    super.key,
    required this.heading,
    required this.suggestion,
    required this.onBegin,
  });

  /// "For your menstrual phase", or "For today".
  final String heading;

  final CycleYogaSuggestion suggestion;

  /// Selects the suggested practice, exactly as tapping it in the list
  /// below would.
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final practice = YogaPractices.byId(suggestion.practice);

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
        Text(suggestion.invitation, style: textTheme.journalNote),
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
