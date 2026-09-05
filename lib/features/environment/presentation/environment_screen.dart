import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/almanac_button.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/environment/environment_providers.dart';
import '../../../core/environment/natural_environment.dart';
import '../../../core/widgets/widgets.dart';
import 'environment_text.dart';
import 'widgets/explore_links.dart';
import 'widgets/moon_card.dart';
import 'widgets/sky_hero.dart';
import 'widgets/sun_card.dart';
import 'widgets/tides_card.dart';

/// The Environment screen: what the world outside is doing, right now.
///
/// The order of the page is the point. The date and the season come
/// first, then a large wordless picture of the sky, and only then the few
/// facts worth knowing — when the sun rises and sets, and what the moon
/// is doing. There is no score, no streak and no chart, because none of
/// those would be about the world; they would be about the user.
///
/// Everything on it comes from [naturalEnvironmentProvider], which is
/// already resolving season, daylight, sunrise and moon on its own
/// schedule. This screen adds no clock of its own and no timer.
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

/// The title bar every state of this screen shares: today's real date,
/// with the way into settings.
class _AlmanacHeader {
  const _AlmanacHeader._();

  static String date(WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    return formatLongDate(ref.watch(timeZoneProvider).wallTimeAt(now));
  }

  static Widget actions(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
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
  );
}

class _EnvironmentView extends StatelessWidget {
  const _EnvironmentView({required this.environment});

  final NaturalEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final local = environment.timeZone.wallTimeAt(environment.resolvedAt);

    return AppScaffold(
      title: formatLongDate(local),
      subtitle: describeSeason(environment.season, environment.resolvedAt),
      trailing: _AlmanacHeader.actions(context),
      body: [
        _SkyBlock(environment: environment),
        SunCard(environment: environment),
        MoonCard(environment: environment),
        const TidesCard(),
        const ExploreLinks(),
      ],
    );
  }
}

/// The hero, and the two quiet lines that go with it.
///
/// Grouped into one block so the words sit close under the picture
/// instead of being spaced out like separate sections.
class _SkyBlock extends StatelessWidget {
  const _SkyBlock({required this.environment});

  final NaturalEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkyHero(environment: environment),
        const SizedBox(height: AppSpacing.md),
        Text(describeLight(environment), style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          describeNextSeason(environment.season, environment.resolvedAt),
          style: textTheme.bodySmall,
        ),
      ],
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
    return AppScaffold(
      title: _AlmanacHeader.date(ref),
      trailing: _AlmanacHeader.actions(context),
      body: [
        Semantics(
          label: 'Looking outside',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: ColoredBox(color: context.palette.surface),
            ),
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
    return AppScaffold(
      title: _AlmanacHeader.date(ref),
      trailing: _AlmanacHeader.actions(context),
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
