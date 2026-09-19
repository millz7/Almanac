import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/almanac_button.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/environment/environment_providers.dart';
import '../../../core/environment/natural_environment.dart';
import '../../../core/environment/season.dart';
import '../../../core/environment/solar_service.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/environment_artwork.dart';
import 'environment_text.dart';
import 'widgets/environment_artwork_view.dart';
import 'widgets/environment_facts.dart';
import 'widgets/location_invitation.dart';

/// The Environment screen: what the world outside is doing, right now.
///
/// **The artwork is the scene; the page is the book.** The landscape is
/// sixteen approved painted plates — one per season at each of the four
/// light states — and the app selects one and crossfades between them.
/// Nothing draws over them: no plants, no mountains, no stars, and no
/// second sun or moon. The code-drawn landscape that used to be here was
/// retired when the paintings arrived, and its classes were deleted
/// rather than left switched off underneath.
///
/// The page around the painting is the Almanac's own paper, stable in
/// every season and at every hour. Only the artwork changes.
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
///
/// A journal label, a fine rule and a written line — the Step 17 section
/// language — rather than the raised white rectangle the first pass put
/// here. Nothing to press: there is no page behind it to go to.
class _Today extends StatelessWidget {
  const _Today({required this.environment});

  final NaturalEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AlmanacRule(spacing: AppSpacing.xs),
        const SizedBox(height: AppSpacing.md),
        Text(
          EnvironmentText.today,
          style: textTheme.eyebrow?.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(describeLight(environment), style: textTheme.journalNote),
        const SizedBox(height: AppSpacing.xs),
        AlmanacAnnotation(
          describeNextSeason(environment.season, environment.resolvedAt),
        ),
      ],
    );
  }
}

class _EnvironmentView extends StatefulWidget {
  const _EnvironmentView({required this.environment});

  final NaturalEnvironment environment;

  @override
  State<_EnvironmentView> createState() => _EnvironmentViewState();
}

class _EnvironmentViewState extends State<_EnvironmentView> {
  String? _warmed;

  Season get _season => widget.environment.season.season;
  EnvironmentLightState get _light =>
      EnvironmentLightState.of(widget.environment.dayNight);

  /// The plate for right now: the real season, and the real day/night
  /// state, mapped onto the four the artwork is painted for.
  String get _artwork =>
      EnvironmentArtwork.forState(season: _season, light: _light);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Keep the next plate warm, and only that one: two images decoded,
    // never a gallery of sixteen.
    final current = _artwork;
    if (_warmed == current) return;
    _warmed = current;
    precacheAdjacentArtwork(context, season: _season, light: _light);
  }

  @override
  Widget build(BuildContext context) {
    final environment = widget.environment;
    final local = environment.timeZone.wallTimeAt(environment.resolvedAt);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return AlmanacPaperSurface(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              // The artwork is allowed a wider column than the words: a
              // wider Almanac page on a tablet, rather than a phone
              // layout stranded in the middle of one.
              constraints: const BoxConstraints(maxWidth: _artworkColumn),
              child: ListView(
                padding: EdgeInsets.only(
                  // Clear of the navigation bar and the home indicator,
                  // so the last line of the page is never sliced.
                  bottom: AppDimens.navBarHeight + bottomInset + AppSpacing.xl,
                ),
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

                  EnvironmentArtworkView(asset: _artwork),

                  const SizedBox(height: AppSpacing.lg),
                  _Column(child: EnvironmentFacts(environment: environment)),
                  const SizedBox(height: AppSpacing.lg),
                  _Column(child: _Today(environment: environment)),

                  // The offer, only when there is genuinely nothing to
                  // show. Never a prompt the app raised by itself.
                  if (!environment.solarEvents.hasTimes &&
                      environment.solarEvents.kind ==
                          SolarDayKind.risesAndSets) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const _Column(child: LocationInvitation()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// How wide the painting may run. Wider than a reading column, so a
/// tablet gets a larger picture rather than a wider paragraph.
const _artworkColumn = 900.0;

/// The reading column the words keep, centred under the wider artwork.
class _Column extends StatelessWidget {
  const _Column({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppDimens.maxContentWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: child,
      ),
    ),
  );
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
            aspectRatio: EnvironmentArtworkView.aspectRatio,
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
