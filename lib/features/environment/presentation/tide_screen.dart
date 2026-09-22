import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/almanac_button.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/context/almanac_context.dart';
import '../../../core/environment/environment_providers.dart';
import '../../../core/environment/natural_environment.dart';
import '../../../core/environment/tide_extrema.dart';
import '../../../core/widgets/widgets.dart';
import 'environment_text.dart';
import 'tide_text.dart';
import 'widgets/location_invitation.dart';

/// The tide, in more detail than the Environment page's fact strip has
/// room for.
///
/// **It belongs to the Environment**, the same way the Moon does: not a
/// feature, not a tab, and reached only by tapping the Tides fact —
/// see `kTidesRoute`.
///
/// **One curve, several honest answers.** Unlike the Moon, a tide
/// reading has more than one reason to be missing — no location shared,
/// a position the marine model has nothing for, or a provider that
/// could not be reached — and each gets its own quiet explanation rather
/// than a single generic "not available".
class TideScreen extends ConsumerWidget {
  const TideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tide = ref.watch(currentTideProvider);
    final environment = ref.watch(naturalEnvironmentProvider).value;

    return AlmanacPage(
      title: TideText.title,
      onBack: () => context.pop(),
      backLabel: TideText.back,
      trailing: const AlmanacButton(),
      children: [
        switch (tide) {
          null => const _Settling(),
          TideLocationRequired() => const _Explanation(
            heading: TideText.locationNeeded,
            body: TideText.locationNeededExplanation,
            offer: LocationInvitation(),
          ),
          TideUnavailableForLocation() => const _Explanation(
            heading: TideText.unavailableHere,
            body: TideText.unavailableHereExplanation,
          ),
          TideProviderUnavailable() => const _Explanation(
            heading: TideText.notAvailableNow,
            body: TideText.providerUnavailableExplanation,
          ),
          TideAvailable(:final snapshot) =>
            environment == null
                ? const _Settling()
                : _Facts(snapshot: snapshot, environment: environment),
        },
      ],
    );
  }
}

/// Before the environment — and so the local clock the tide needs to be
/// read against — has resolved once. Brief and wordless, the same
/// restraint as the Environment page's own first frame.
class _Settling extends StatelessWidget {
  const _Settling();

  @override
  Widget build(BuildContext context) => const SizedBox(height: AppSpacing.xl);
}

/// One of the three states that are not a real reading: a heading, a
/// line explaining why, and — only for the one state it can help —
/// the same location offer the rest of the Environment page makes.
class _Explanation extends StatelessWidget {
  const _Explanation({required this.heading, required this.body, this.offer});

  final String heading;
  final String body;
  final Widget? offer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: textTheme.chapterTitle),
        const SizedBox(height: AppSpacing.md),
        Text(body, style: textTheme.bodyLarge),
        if (offer case final widget?) ...[
          const SizedBox(height: AppSpacing.lg),
          widget,
        ],
      ],
    );
  }
}

/// What the tide is actually doing: the current direction, and the
/// upcoming highs and lows, read from the same curve the Environment
/// fact strip already summarised.
class _Facts extends StatelessWidget {
  const _Facts({required this.snapshot, required this.environment});

  final TideSnapshot snapshot;
  final NaturalEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final zone = environment.timeZone;
    final now = environment.resolvedAt;

    final direction = tideDirectionAt(
      snapshot.samples,
      now,
      extrema: snapshot.extrema,
    );
    final nextHigh = nextTideExtreme(
      snapshot.extrema,
      now,
      TideExtremeType.high,
    );
    final nextLow = nextTideExtreme(snapshot.extrema, now, TideExtremeType.low);
    final followingHigh = nextHigh == null
        ? null
        : nextTideExtreme(
            snapshot.extrema,
            nextHigh.time,
            TideExtremeType.high,
          );
    final followingLow = nextLow == null
        ? null
        : nextTideExtreme(snapshot.extrema, nextLow.time, TideExtremeType.low);

    String at(TideExtreme extreme) =>
        formatClockTime(context, zone.wallTimeAt(extreme.time));

    return Semantics(
      container: true,
      label: TideText.spokenFacts(
        direction: direction,
        nextHigh: nextHigh == null ? null : at(nextHigh),
        nextLow: nextLow == null ? null : at(nextLow),
      ),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FactLine(
            label: TideText.currentLabel,
            value: TideText.directionLabel(direction),
            textTheme: textTheme,
            palette: palette,
          ),
          const AlmanacSectionDivider(spacing: AppSpacing.lg),
          if (nextHigh case final extreme?)
            _FactLine(
              label: TideText.nextHighLabel,
              value: at(extreme),
              textTheme: textTheme,
              palette: palette,
            ),
          if (nextLow case final extreme?) ...[
            const SizedBox(height: AppSpacing.md),
            _FactLine(
              label: TideText.nextLowLabel,
              value: at(extreme),
              textTheme: textTheme,
              palette: palette,
            ),
          ],
          if (followingHigh case final extreme?) ...[
            const SizedBox(height: AppSpacing.md),
            _FactLine(
              label: TideText.followingHighLabel,
              value: at(extreme),
              textTheme: textTheme,
              palette: palette,
            ),
          ],
          if (followingLow case final extreme?) ...[
            const SizedBox(height: AppSpacing.md),
            _FactLine(
              label: TideText.followingLowLabel,
              value: at(extreme),
              textTheme: textTheme,
              palette: palette,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          // Said once, quietly — never a warning banner, and never
          // implying more precision than a modelled curve can honestly
          // offer.
          Text(
            TideText.nonNavigationNote,
            style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FactLine extends StatelessWidget {
  const _FactLine({
    required this.label,
    required this.value,
    required this.textTheme,
    required this.palette,
  });

  final String label;
  final String value;
  final TextTheme textTheme;
  final SeasonalPalette palette;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: textTheme.valueLabel?.copyWith(color: palette.textSecondary),
      ),
      Text(value, style: textTheme.chapterTitle),
    ],
  );
}
