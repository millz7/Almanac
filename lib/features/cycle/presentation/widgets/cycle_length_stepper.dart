import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/cycle_calculator.dart';
import '../cycle_text.dart';

/// How long a cycle to estimate with.
///
/// A minus, a number and a plus — the same control as Meditation's
/// duration, for the same reasons: no slider to fiddle with, and the
/// number on its own line so a large text size has somewhere to go.
///
/// This changes estimates and nothing else. The note underneath says so,
/// because "will this rewrite my dates?" is the first thing anybody would
/// reasonably wonder.
class CycleLengthStepper extends StatelessWidget {
  const CycleLengthStepper({
    super.key,
    required this.length,
    required this.onChanged,
  });

  final int length;
  final ValueChanged<int> onChanged;

  bool get _canShorten => length > kMinCycleLength;
  bool get _canLengthen => length < kMaxCycleLength;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(CycleText.lengthHeading, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),

        Center(
          child: Semantics(
            container: true,
            // Announced as it changes, because the change is the answer
            // to the button just pressed.
            liveRegion: true,
            child: Text(
              CycleText.days(length),
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _canShorten ? () => onChanged(length - 1) : null,
              icon: const Icon(Icons.remove),
              tooltip: 'A day shorter',
            ),
            const SizedBox(width: AppSpacing.xl),
            IconButton(
              onPressed: _canLengthen ? () => onChanged(length + 1) : null,
              icon: const Icon(Icons.add),
              tooltip: 'A day longer',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        Text(CycleText.lengthNote, style: textTheme.bodySmall),
      ],
    );
  }
}
