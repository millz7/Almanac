import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/environment/environment_providers.dart';
import '../../../../core/environment/natural_environment.dart';
import '../../../../core/environment/solar_service.dart';
import '../../../../core/widgets/widgets.dart';
import '../today_text.dart';

/// Today's sunrise and sunset, in the user's own local time.
///
/// Three genuinely different situations, none of which is dressed up as
/// another:
///
/// * There are times, so they are shown — real instants from
///   [SolarService], converted to the user's zone for display only.
/// * The sun does not cross the horizon here today, so it says that.
/// * No position has been shared, so it says what it needs and offers to
///   ask for it. Deliberately not styled as an error: declining location
///   is a perfectly good answer and the rest of the app works without it.
class SunCard extends StatelessWidget {
  const SunCard({super.key, required this.environment});

  final NaturalEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final events = environment.solarEvents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'The sun today'),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: switch (events.kind) {
            SolarDayKind.sunNeverSets => const _PolarNote(
              icon: Icons.wb_sunny_outlined,
              text: 'The sun stays above the horizon all day where you are.',
            ),
            SolarDayKind.sunNeverRises => const _PolarNote(
              icon: Icons.nights_stay_outlined,
              text: 'The sun stays below the horizon all day where you are.',
            ),
            SolarDayKind.risesAndSets =>
              events.hasTimes
                  ? _Times(environment: environment)
                  : const _LocationInvitation(),
          },
        ),
      ],
    );
  }
}

class _Times extends StatelessWidget {
  const _Times({required this.environment});

  final NaturalEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final zone = environment.timeZone;
    final events = environment.solarEvents;
    final dayLength = events.dayLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _Moment(
                label: 'Sunrise',
                icon: Icons.wb_twilight_outlined,
                time: formatClockTime(
                  context,
                  zone.wallTimeAt(events.sunrise!),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _Moment(
                label: 'Sunset',
                icon: Icons.wb_shade_outlined,
                time: formatClockTime(context, zone.wallTimeAt(events.sunset!)),
              ),
            ),
          ],
        ),
        if (dayLength != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text('${formatSpan(dayLength)} of light', style: textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _Moment extends StatelessWidget {
  const _Moment({required this.label, required this.icon, required this.time});

  final String label;
  final IconData icon;
  final String time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      // One node with one label, so it is read as "Sunrise 6:12 am"
      // rather than as a stray icon followed by a number.
      container: true,
      label: '$label $time',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppIconSize.sm, color: context.palette.icon),
              const SizedBox(width: AppSpacing.xs),
              // Flexible so the word wraps at a large text scale instead
              // of running out of the card.
              Flexible(child: Text(label, style: theme.textTheme.labelLarge)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(time, style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _PolarNote extends StatelessWidget {
  const _PolarNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppIconSize.md, color: context.palette.icon),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}

/// The no-location state. An invitation, not a warning.
class _LocationInvitation extends ConsumerWidget {
  const _LocationInvitation();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(locationStateProvider);
    final controller = ref.read(locationStateProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect location to see sunrise and sunset where you are.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Read on this device only, and never sent anywhere. Everything '
          'else here works without it.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        // A quiet text action rather than a filled button: this is an
        // offer, and "no" stays a first-class answer.
        Align(
          alignment: Alignment.centerLeft,
          child: state.canRequest
              ? TextButton(
                  onPressed: controller.requestAccess,
                  child: const Text('Enable location'),
                )
              : TextButton(
                  // Android will not prompt again once it has been
                  // permanently denied, so the only honest offer left is
                  // a route to the place that can change it.
                  onPressed: controller.openSystemSettings,
                  child: const Text('Open device settings'),
                ),
        ),
      ],
    );
  }
}
