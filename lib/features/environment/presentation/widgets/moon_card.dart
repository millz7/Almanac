import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/environment/geo_location.dart';
import '../../../../core/environment/natural_environment.dart';
import '../../../../core/widgets/widgets.dart';
import '../moon_text.dart';
import 'moon_disc.dart';

/// Tonight's moon: the drawn disc, its phase in words, and how much of it
/// is lit.
///
/// The phase needs no position and no permission, so this section is the
/// same whether or not the user has shared their location — it is the one
/// piece of the sky the app can always tell them about.
///
/// **And now a way in.** The card opens the Moon detail page: the
/// Environment has hidden depth, and this is the first of it. That tap is
/// the only change here — the composition of the Environment screen is
/// settled, so nothing moved to make room for it.
class MoonCard extends StatelessWidget {
  const MoonCard({super.key, required this.environment});

  final NaturalEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final moon = environment.moon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'The moon'),
        const SizedBox(height: AppSpacing.md),
        // One node, so a screen reader hears the moon as a sentence and
        // is told it can be opened, rather than three fragments that
        // happen to sit inside a tappable box.
        Semantics(
          container: true,
          button: true,
          label: MoonText.spokenFacts(moon),
          excludeSemantics: true,
          child: AppCard(
            onTap: () => context.push(kMoonRoute),
            child: Row(
              children: [
                MoonDisc(
                  moon: moon,
                  size: AppIconSize.xl + AppSpacing.md,
                  litColor: palette.textPrimary,
                  unlitColor: palette.textPrimary.withValues(alpha: 0.12),
                  // Which way round the light falls depends on where you
                  // are standing on the planet.
                  mirrored: environment.hemisphere == Hemisphere.southern,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(moon.phase.label, style: textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${moon.illuminatedPercent}% lit',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
