import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/almanac_button.dart';
import '../../../app/navigation/widgets/almanac_doorway.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/context/almanac_context.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/festival.dart';
import '../domain/weather_festival_note.dart';

/// A small, restrained mark for each festival — the same spirit as the
/// Almanac's other line icons, never an occult symbol or a rune.
IconData _markFor(FestivalId id) => switch (id) {
  FestivalId.yule => Icons.ac_unit_outlined,
  FestivalId.imbolc => Icons.local_fire_department_outlined,
  FestivalId.ostara => Icons.egg_outlined,
  FestivalId.beltane => Icons.local_florist_outlined,
  FestivalId.litha => Icons.wb_sunny_outlined,
  FestivalId.lughnasadh => Icons.grass_outlined,
  FestivalId.mabon => Icons.eco_outlined,
  FestivalId.samhain => Icons.nights_stay_outlined,
};

/// One festival's own page: what it is, and ways someone might prepare
/// for it, celebrate it, cook for it, reflect on it and notice outside
/// because of it.
///
/// **Not every festival the same length.** The sections below are
/// omitted rather than padded when a festival genuinely has less to say
/// in one of them — none currently does, but the page does not assume
/// they must all match.
class FestivalDetailPage extends ConsumerWidget {
  const FestivalDetailPage({super.key, required this.id, required this.onBack});

  final FestivalId id;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final festival = WheelOfYear.byId(id);
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return AlmanacPage(
      title: festival.name,
      eyebrow: festival.seasonalPosition,
      onBack: onBack,
      trailing: const AlmanacButton(),
      children: [
        Column(
          children: [
            ExcludeSemantics(
              child: Icon(
                _markFor(id),
                size: AppIconSize.lg,
                color: palette.icon,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              festival.theme,
              textAlign: TextAlign.center,
              style: textTheme.journalLabel?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
        ),

        for (final paragraph in festival.about)
          Text(paragraph, style: textTheme.bodyText),

        _Section(
          heading: 'Prepare',
          lines: festival.prepare,
          textTheme: textTheme,
        ),

        _Section(
          heading: 'Celebrate',
          lines: festival.celebrate,
          textTheme: textTheme,
          doorway: AlmanacDoorway(
            label: 'Try a yoga practice',
            intent: FestivalYogaIntent(id),
          ),
        ),
        const _WeatherNote(),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AlmanacSectionLabel(label: 'Food & drink'),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "A few suggestion ideas, not full recipes — what they turn "
              'into is the Cookbook\'s own business.',
              style: textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _FoodLine(
              label: 'Meal',
              value: festival.food.meal,
              textTheme: textTheme,
            ),
            const SizedBox(height: AppSpacing.sm),
            _FoodLine(
              label: 'Treat',
              value: festival.food.treat,
              textTheme: textTheme,
            ),
            const SizedBox(height: AppSpacing.sm),
            _FoodLine(
              label: 'Drink',
              value: festival.food.drink,
              textTheme: textTheme,
            ),
            const SizedBox(height: AppSpacing.md),
            AlmanacDoorway(
              label: 'See it in the Cookbook',
              intent: FestivalCookbookIntent(id),
            ),
          ],
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AlmanacSectionLabel(label: 'Reflect'),
            const SizedBox(height: AppSpacing.sm),
            Text(festival.reflection, style: textTheme.journalNote),
            const SizedBox(height: AppSpacing.md),
            AlmanacDoorway(
              label: 'Try a meditation',
              intent: FestivalMeditationIntent(id),
            ),
          ],
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AlmanacSectionLabel(label: 'In nature'),
            const SizedBox(height: AppSpacing.sm),
            Text(festival.nature, style: textTheme.bodyText),
            const SizedBox(height: AppSpacing.md),
            AlmanacDoorway(
              label: 'Notice what is changing in the Garden',
              intent: FestivalGardenIntent(id),
            ),
            AlmanacDoorway(
              label: 'Notice what is changing outside',
              intent: FestivalNatureLogIntent(id),
            ),
          ],
        ),
      ],
    );
  }
}

/// A gentle nudge towards celebrating indoors or out, from today's
/// weather — never a change to which festival this is, its date, its
/// meaning, or its hemisphere. See `WeatherFestivalNotes`. Absent
/// entirely with no location, no network, or a day with nothing
/// distinctive about it.
class _WeatherNote extends ConsumerWidget {
  const _WeatherNote();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(currentWeatherProvider);
    if (weather == null) return const SizedBox.shrink();
    final cue = WeatherFestivalNotes.cueFor(weather.current);
    if (cue == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        WeatherFestivalNotes.noteFor(cue),
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: context.palette.textSecondary),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.heading,
    required this.lines,
    required this.textTheme,
    this.doorway,
  });

  final String heading;
  final List<String> lines;
  final TextTheme textTheme;
  final Widget? doorway;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AlmanacSectionLabel(label: heading),
        const SizedBox(height: AppSpacing.sm),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text('•  $line', style: textTheme.bodyText),
          ),
        if (doorway case final door?) ...[
          const SizedBox(height: AppSpacing.xs),
          door,
        ],
      ],
    );
  }
}

class _FoodLine extends StatelessWidget {
  const _FoodLine({
    required this.label,
    required this.value,
    required this.textTheme,
  });

  final String label;
  final String value;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.valueLabel?.copyWith(color: palette.textSecondary),
          ),
          Text(value, style: textTheme.bodyText),
        ],
      ),
    );
  }
}
