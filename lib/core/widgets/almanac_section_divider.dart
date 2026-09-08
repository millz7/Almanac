import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// A fine rule between passages on a paper page.
///
/// A hairline, inset from both edges and quiet enough to read as a pen
/// stroke rather than a border. Detail pages separate their sections with
/// these instead of boxing each one — see
/// `docs/almanac_visual_language.md`.
///
/// Decorative: a divider has nothing to say to a screen reader, and the
/// headings around it already say where one passage ends.
class AlmanacSectionDivider extends StatelessWidget {
  const AlmanacSectionDivider({super.key, this.spacing = AppSpacing.xl});

  /// Breathing room above and below.
  final double spacing;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: spacing),
      child: Center(
        child: SizedBox(
          width: 96,
          height: 1,
          child: ColoredBox(
            color: context.palette.textSecondary.withValues(alpha: 0.35),
          ),
        ),
      ),
    ),
  );
}
