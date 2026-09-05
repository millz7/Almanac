import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// A held place for tides.
///
/// There are deliberately no times here, and no chart. Tide prediction
/// needs harmonic constituents for a particular port, which this app does
/// not have yet, and a plausible-looking made-up tide is worse than no
/// tide at all — someone might plan a walk around it. So the section
/// exists, says plainly that it is not ready, and shows nothing.
class TidesCard extends StatelessWidget {
  const TidesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Tides'),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.waves_outlined,
                size: AppIconSize.md,
                color: palette.icon,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Not here yet', style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'High and low water for your nearest coast will '
                      'appear here. Until the app can look them up '
                      'properly, it would rather show nothing than a '
                      'guess.',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
