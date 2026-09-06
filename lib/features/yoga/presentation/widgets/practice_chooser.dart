import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/yoga_practices.dart';

/// The three practices, offered plainly.
///
/// A name, a line, and roughly how long — enough to choose by. No search,
/// no filters and no library, because there are three of them.
class PracticeChooser extends StatelessWidget {
  const PracticeChooser({super.key, required this.onChosen});

  final ValueChanged<YogaPractice> onChosen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose a practice', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.lg),

        for (final practice in YogaPractices.all) ...[
          ChoiceCard(
            title: practice.name,
            description:
                '${practice.description}  '
                '${practice.approximateMinutes} minutes.',
            onPressed: () => onChosen(practice),
          ),
          if (practice != YogaPractices.all.last)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
