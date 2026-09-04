import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme/app_theme.dart';
import '../core/environment/environment_providers.dart';
import '../core/environment/natural_environment.dart';
import '../core/environment/season.dart';
import '../core/widgets/widgets.dart';
import 'theme_preview.dart';

/// DEVELOPMENT ONLY — lets the eight seasonal palettes be inspected on
/// device without waiting for the real season or time of day to change.
///
/// Reached from a debug-only affordance on the Today screen and registered
/// on a debug-only route. It is not part of the production experience.
class ThemePreviewScreen extends ConsumerWidget {
  const ThemePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final preview = ref.watch(themePreviewProvider);
    final controller = ref.read(themePreviewProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Theme preview')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Text(
            'Developer tool. The app normally chooses the palette from the '
            'real season and the sun at your location.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Active palette', style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(palette.name, style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Season'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final season in Season.values)
                ChoiceChip(
                  label: Text(season.label),
                  selected: preview?.season == season,
                  onSelected: (_) => controller.selectSeason(season),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Time of day'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: const Text('Day'),
                selected: preview != null && !preview.isNight,
                onSelected: (_) => controller.selectNight(isNight: false),
              ),
              ChoiceChip(
                label: const Text('Night'),
                selected: preview != null && preview.isNight,
                onSelected: (_) => controller.selectNight(isNight: true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          OutlinedButton(
            onPressed: preview == null ? null : controller.clear,
            child: const Text('Use the real environment'),
          ),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Detected environment'),
          const SizedBox(height: AppSpacing.sm),
          const _DetectedEnvironmentCard(),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Semantic tokens'),
          const SizedBox(height: AppSpacing.sm),
          _TokenSwatches(palette: palette),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Components'),
          const SizedBox(height: AppSpacing.sm),
          const _ComponentSamples(),
        ],
      ),
    );
  }
}

/// Shows what the engine worked out from the real world, so the automatic
/// path can be verified as well as the overrides.
class _DetectedEnvironmentCard extends ConsumerWidget {
  const _DetectedEnvironmentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environment = ref.watch(naturalEnvironmentProvider);
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: environment.when(
        loading: () => Text('Resolving…', style: textTheme.bodyMedium),
        error: (error, _) =>
            Text('Could not resolve: $error', style: textTheme.bodyMedium),
        data: (data) {
          final nextChange = data.dayNight.nextChangeAt;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Row(label: 'Season', value: data.season.season.label),
              _Row(label: 'Phase', value: data.dayNight.phase.label),
              _Row(
                label: 'Daylight',
                value: data.dayNight.daylight.toStringAsFixed(2),
              ),
              _Row(label: 'Hemisphere', value: data.hemisphere.name),
              _Row(
                label: 'Hemisphere from',
                value: _sourceLabel(data.hemisphereSource),
              ),
              _Row(
                label: 'UTC offset',
                value: '${data.timeZone.utcOffset.inHours}h',
              ),
              _Row(
                label: 'Precise location',
                value: data.location?.toString() ?? 'not shared',
              ),
              _Row(
                label: 'Next change',
                value: nextChange == null
                    ? 'tomorrow'
                    : _formatLocalTime(data.timeZone.wallTimeAt(nextChange)),
              ),
              if (data.hemisphereSource == HemisphereSource.technicalFallback)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'No hemisphere has been chosen or derived yet, so this '
                    'is a technical fallback for the first frame only.',
                    style: textTheme.bodySmall,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _sourceLabel(HemisphereSource source) => switch (source) {
  HemisphereSource.derivedFromLocation => 'your location',
  HemisphereSource.userSelected => 'your choice',
  HemisphereSource.technicalFallback => 'fallback',
};

String _formatLocalTime(DateTime localWallTime) {
  final hour = localWallTime.hour.toString().padLeft(2, '0');
  final minute = localWallTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute local';
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          Text(value, style: textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _TokenSwatches extends StatelessWidget {
  const _TokenSwatches({required this.palette});

  final SeasonalPalette palette;

  @override
  Widget build(BuildContext context) {
    final swatches = <({String name, Color color, Color on})>[
      (name: 'background', color: palette.background, on: palette.textPrimary),
      (name: 'surface', color: palette.surface, on: palette.textPrimary),
      (
        name: 'surfaceElevated',
        color: palette.surfaceElevated,
        on: palette.textPrimary,
      ),
      (name: 'primary', color: palette.primary, on: palette.onPrimary),
      (
        name: 'primarySoft',
        color: palette.primarySoft,
        on: palette.onPrimarySoft,
      ),
      (name: 'secondary', color: palette.secondary, on: palette.onSecondary),
      (name: 'accent', color: palette.accent, on: palette.onAccent),
      (name: 'water', color: palette.water, on: palette.background),
      (name: 'earth', color: palette.earth, on: palette.background),
      (name: 'border', color: palette.border, on: palette.background),
      (name: 'icon', color: palette.icon, on: palette.background),
      (name: 'disabled', color: palette.disabled, on: palette.onDisabled),
      (name: 'error', color: palette.error, on: palette.onError),
    ];

    return Column(
      children: [
        for (final swatch in swatches)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: swatch.color,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              swatch.name,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: swatch.on),
            ),
          ),
      ],
    );
  }
}

class _ComponentSamples extends StatelessWidget {
  const _ComponentSamples();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Heading', style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Body text on a card, to check comfort and contrast in this '
                'palette.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('Secondary text', style: textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(label: 'Primary action', onPressed: () {}),
        const SizedBox(height: AppSpacing.sm),
        const PrimaryButton(label: 'Disabled action', onPressed: null),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(onPressed: () {}, child: const Text('Secondary action')),
        const SizedBox(height: AppSpacing.md),
        const EmptyState(
          icon: Icons.eco_outlined,
          title: 'Empty state',
          message: 'How a placeholder reads in this palette.',
        ),
      ],
    );
  }
}
