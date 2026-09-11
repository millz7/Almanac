import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/almanac_button.dart';
import '../../../app/navigation/widgets/almanac_doorway.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/context/almanac_context.dart';
import '../../../core/environment/geo_location.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/moon_reflection.dart';
import 'moon_text.dart';
import 'widgets/moon_disc.dart';

/// The moon, in more detail than the Environment page has room for.
///
/// **It belongs to the Environment.** Not a feature, not a tab, not a
/// choice in onboarding, and not in [FeatureId] — hidden information
/// reached by tapping the moon on the Environment page, and Back returns
/// there.
///
/// **Paper, not scenery.** The detail-page rule from
/// `docs/almanac_visual_language.md`: a paper ground, one illustration,
/// fine rules between passages, and mostly space. No landscape, no
/// flowers around the moon, no botanical wreath, no forest, and no
/// seasonal background painting. Environment is the app's living
/// painting; this is a page in the same notebook. There is a test for
/// each of those absences, because "one central illustration" is the
/// rule that stops the app needing four seasonal paintings and two
/// day/night versions of every screen it ever adds.
///
/// **Two layers, in this order.** What the moon is actually doing, from
/// the astronomy the app already calculates. Then what somebody might do
/// with that, offered rather than prescribed.
class MoonScreen extends ConsumerWidget {
  const MoonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The same moon the Environment page is showing, from the same
    // provider. Not a second calculation and not a second clock.
    final moon = ref.watch(currentMoonProvider);
    final hemisphere = ref.watch(resolvedHemisphereProvider).hemisphere;
    final reflection = MoonReflections.forPhase(moon.phase);

    return AlmanacPage(
      title: MoonText.title,
      onBack: () => context.pop(),
      backLabel: MoonText.back,
      trailing: const AlmanacButton(),
      children: [
        _Facts(moon: moon, hemisphere: hemisphere),
        const AlmanacSectionDivider(spacing: AppSpacing.lg),
        _Reflection(reflection: reflection),
      ],
    );
  }
}

/// What the moon is doing: the title, the drawn moon, and the numbers.
///
/// Every value is calculated. Nothing here is rounded up into a claim,
/// and the timing of the next major phase is deliberately absent — the
/// existing astronomy resolves a phase at an instant rather than
/// searching for the instant a phase begins, and inventing a date would
/// be worse than leaving it out.
class _Facts extends StatelessWidget {
  const _Facts({required this.moon, required this.hemisphere});

  final MoonPhaseState moon;
  final Hemisphere hemisphere;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The one illustration on the page, and the only thing on it
        // that is allowed to be big.
        Center(
          child: MoonDisc(
            moon: moon,
            size: 220,
            litColor: palette.textPrimary,
            unlitColor: palette.textPrimary.withValues(alpha: 0.10),
            // Which way round the light falls depends on where you are
            // standing on the planet.
            mirrored: hemisphere == Hemisphere.southern,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // One node for a screen reader: the phase, the percentage and
        // the direction read as a sentence rather than three fragments.
        Semantics(
          container: true,
          label: MoonText.spokenFacts(moon),
          excludeSemantics: true,
          child: Column(
            children: [
              Text(
                moon.phase.label,
                textAlign: TextAlign.center,
                style: textTheme.chapterTitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              // The measured fact, set as a value rather than as a
              // sentence: small and letter-spaced under the name, as in
              // the reference. The words themselves are left alone —
              // a typographic effect is not a reason to change what the
              // page actually says.
              Text(
                MoonText.illumination(moon.illuminatedPercent),
                textAlign: TextAlign.center,
                style: textTheme.eyebrow?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                MoonText.direction(moon.phase),
                textAlign: TextAlign.center,
                style: textTheme.journalNote?.copyWith(
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// What somebody might do with this moon, and the one way out of the
/// page.
class _Reflection extends StatelessWidget {
  const _Reflection({required this.reflection});

  final MoonReflection reflection;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          MoonText.forThisMoon,
          style: textTheme.journalLabel?.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        // The tradition named once, here, so every phase underneath can
        // simply be written. Not a disclaimer at the foot of the page.
        Text(
          MoonText.reflectiveFraming,
          style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(reflection.theme, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          reflection.wordLine,
          style: textTheme.journalLabel?.copyWith(color: palette.primary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(reflection.explanation, style: textTheme.journalNote),

        const SizedBox(height: AppSpacing.xl),
        Text(
          MoonText.practices,
          style: textTheme.journalLabel?.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Real text, always, whatever the user's Almanac contains. The
        // guidance never depends on the destination existing — only the
        // doorway below does.
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            for (final practice in reflection.practices)
              Text(practice.label, style: textTheme.journalNote),
          ],
        ),

        // One doorway per feature these practices could open, and each
        // one renders itself away when that feature is not part of the
        // Almanac. Meditation is the only destination the Moon has so
        // far; a second needs a practice with a destination, not an edit
        // here.
        for (final destination in reflection.destinations)
          if (MoonText.doorwayLabel(destination) case final label?)
            if (_intentFor(destination, reflection.phase) case final intent?)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: AlmanacInset(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AlmanacDoorway(label: label, intent: intent),
                  ),
                ),
              ),

        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  /// The intent for a doorway out of the Moon.
  ///
  /// Null for a destination the Moon has nothing to say to yet, so a
  /// practice can name a feature before the pathway to it is built
  /// rather than the two having to land in the same change.
  static AlmanacIntent? _intentFor(FeatureId destination, MoonPhase phase) =>
      switch (destination) {
        FeatureId.meditation => MoonMeditationIntent(phase),
        _ => null,
      };
}
