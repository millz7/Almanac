import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/yoga_practice.dart';

/// What to do, while you are doing it.
///
/// Yoga cannot be a wordless orb: a movement has to be described before
/// anybody can follow it. So the words stay — but they stay quiet, and
/// they stay below the figure, which is the thing being asked for.
///
/// One semantic node for the whole block, announced once when the
/// movement changes. The countdown is deliberately outside it: a number
/// that changes every second is worth glancing at and not worth being
/// told.
class StepGuidance extends StatelessWidget {
  const StepGuidance({
    super.key,
    required this.moment,
    required this.secondsRemaining,
  });

  final YogaMoment moment;

  /// Passed in rather than read from [moment] so this rebuilds once a
  /// second rather than once a frame.
  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final cue = moment.breathCue;

    return Column(
      children: [
        // Where you are in the sequence. Quiet, and never a bar that
        // fills up.
        Text(
          '${moment.stepNumber} of ${moment.totalSteps}',
          style: textTheme.labelMedium?.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),

        Semantics(
          // The pose, what to do, and the breath, said once when the
          // movement changes — everything a screen reader needs, since
          // the drawn figure gives it nothing.
          container: true,
          liveRegion: true,
          label: moment.spokenInstruction,
          excludeSemantics: true,
          child: Column(
            children: [
              Text(
                moment.name,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                moment.instruction,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
            ],
          ),
        ),

        if (cue != null) ...[
          const SizedBox(height: AppSpacing.md),
          // The breath cue changes within a movement on the flowing
          // steps, so it is its own node and announced as it changes.
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(
              cue,
              textAlign: TextAlign.center,
              style: textTheme.titleSmall?.copyWith(color: palette.primary),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.md),
        Text(
          '${secondsRemaining}s',
          style: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        ),
      ],
    );
  }
}
