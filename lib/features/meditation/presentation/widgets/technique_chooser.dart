import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/meditation_technique.dart';

/// The four practices, offered plainly.
///
/// Four doors into the same quiet room, so they are four identical
/// choices rather than four sales pitches: a name, one line, and nothing
/// else. No timings on the face of them — "four in, seven held, eight
/// out" is in Sleep's line because that *is* what Sleep is, not because
/// the numbers are the point.
class TechniqueChooser extends StatelessWidget {
  const TechniqueChooser({super.key, required this.onChosen});

  final ValueChanged<MeditationTechnique> onChosen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose a practice', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.lg),

        for (final technique in MeditationTechniques.all) ...[
          ChoiceCard(
            title: technique.name,
            description: technique.description,
            onPressed: () => onChosen(technique),
          ),
          if (technique != MeditationTechniques.all.last)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
