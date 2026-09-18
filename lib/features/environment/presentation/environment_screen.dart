import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/almanac_button.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/environment/environment_providers.dart';
import '../../../core/environment/natural_environment.dart';
import '../../../core/environment/solar_service.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/landscape_appearance.dart';
import 'environment_text.dart';
import 'widgets/almanac_landscape_view.dart';
import 'widgets/environment_facts.dart';
import 'widgets/explore_links.dart';
import 'widgets/location_invitation.dart';

/// The Environment screen: what the world outside is doing, right now.
///
/// **ENVIRONMENT IS OUTSIDE. DETAIL PAGES ARE THE BOOK.** This is the
/// exception in the app — the one immersive surface, and the only screen
/// with a landscape on it. It is deliberately *not* on
/// `AlmanacPaper.ground`: its ground is the season's own, and it follows
/// the sky from dawn to dark while every inner page stays cream.
///
/// The composition follows the approved Home reference, top to bottom:
/// the masthead; the date and the season with the standing line beside
/// them; the painting; the four things the Almanac knows; one line about
/// today; and the way on into the rest of the book.
///
/// Everything on it comes from [naturalEnvironmentProvider], which is
/// already resolving season, daylight, sunrise and moon on its own
/// schedule. This screen adds no clock, no timer and no second sun, and
/// it never asks for a location.
class EnvironmentScreen extends ConsumerWidget {
  const EnvironmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environment = ref.watch(naturalEnvironmentProvider);

    // hasValue first, so a refresh in the background keeps showing the
    // day rather than blanking the screen.
    if (environment.hasValue) {
      return _EnvironmentView(environment: environment.requireValue);
    }
    if (environment.hasError) return const _EnvironmentUnavailable();
    return const _EnvironmentSettling();
  }
}

/// The masthead: the book's name, its standing rule, and the way into the
/// user's own Almanac.
class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    EnvironmentText.masthead,
                    style: textTheme.pageTitle?.copyWith(fontSize: 36),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    EnvironmentText.mastheadRule,
                    style: textTheme.eyebrow?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Debug builds only: a way into the seasonal theme preview.
          // Absent from release builds, where the route does not exist.
          if (kDebugMode)
            IconButton(
              onPressed: () => context.push(kThemePreviewRoute),
              icon: const Icon(Icons.palette_outlined),
              tooltip: 'Theme preview (debug)',
            ),
          const AlmanacButton(),
        ],
      ),
    );
  }
}

/// The date and season on the left, the standing line on the right — the
/// reference's two-column opening.
class _DateLine extends StatelessWidget {
  const _DateLine({required this.date, this.season});

  final String date;
  final String? season;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: textTheme.chapterTitle),
                if (season case final line?) ...[
                  const SizedBox(height: AppSpacing.xs),
                  // The season as the app describes it — "Early summer",
                  // not "EARLY SUMMER". The letter-spacing carries the
                  // reference's treatment; changing the words to get a
                  // typographic effect would change what the page says.
                  Text(
                    line,
                    style: textTheme.eyebrow?.copyWith(
                      color: palette.textSecondary,
                      letterSpacing: 2.2,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                ExcludeSemantics(
                  child: SizedBox(
                    width: 32,
                    height: 1,
                    child: ColoredBox(color: palette.border),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: Text(
              EnvironmentText.tagline,
              textAlign: TextAlign.right,
              style: textTheme.journalNote?.copyWith(
                fontSize: 15,
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One line about today, in the page's own voice, under the strip.
class _Today extends StatelessWidget {
  const _Today({required this.environment});

  final NaturalEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AlmanacInset(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              EnvironmentText.today,
              style: textTheme.eyebrow?.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(describeLight(environment), style: textTheme.journalNote),
            const SizedBox(height: AppSpacing.xs),
            Text(
              describeNextSeason(environment.season, environment.resolvedAt),
              style: textTheme.annotation?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnvironmentView extends StatelessWidget {
  const _EnvironmentView({required this.environment});

  final NaturalEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final local = environment.timeZone.wallTimeAt(environment.resolvedAt);
    final appearance = LandscapeAppearance.resolve(
      season: environment.season.season,
      dayNight: environment.dayNight,
      palette: context.palette,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimens.maxContentWidth,
            ),
            // The page scrolls with no horizontal padding of its own, so
            // the painting can run to both edges the way the reference
            // has it while the words keep their margins.
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                const _Masthead(),
                _DateLine(
                  date: formatLongDate(local),
                  season: describeSeason(
                    environment.season,
                    environment.resolvedAt,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AlmanacLandscapeView(
                  environment: environment,
                  appearance: appearance,
                ),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: EnvironmentFacts(environment: environment),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Today(environment: environment),

                // The offer, only when there is genuinely nothing to
                // show. Never a prompt the app raised by itself.
                if (!environment.solarEvents.hasTimes &&
                    environment.solarEvents.kind ==
                        SolarDayKind.risesAndSets) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: LocationInvitation(),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: ExploreLinks(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The first moment of the app's life, before sunrise and sunset have
/// resolved. Deliberately quiet: a soft shape where the sky will be,
/// rather than a spinner.
class _EnvironmentSettling extends ConsumerWidget {
  const _EnvironmentSettling();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    return AppScaffold(
      title: formatLongDate(ref.watch(timeZoneProvider).wallTimeAt(now)),
      trailing: const AlmanacButton(),
      body: [
        Semantics(
          label: 'Looking outside',
          child: AspectRatio(
            aspectRatio: AlmanacLandscapeView.aspectRatio,
            child: ColoredBox(color: context.palette.surface),
          ),
        ),
      ],
    );
  }
}

/// The environment could not be resolved at all. Rare, and not the user's
/// fault, so it says what happened without alarm.
class _EnvironmentUnavailable extends ConsumerWidget {
  const _EnvironmentUnavailable();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    return AppScaffold(
      title: formatLongDate(ref.watch(timeZoneProvider).wallTimeAt(now)),
      trailing: const AlmanacButton(),
      body: [
        EmptyState(
          icon: Icons.cloud_outlined,
          title: 'The day is out of reach',
          message:
              'The app could not work out where the day has got to. '
              'Reopening it usually settles this.',
          action: PrimaryButton(
            label: 'Try again',
            onPressed: () => ref.invalidate(naturalEnvironmentProvider),
          ),
        ),
      ],
    );
  }
}
