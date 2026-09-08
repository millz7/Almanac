import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/almanac_button.dart';
import '../../../app/navigation/widgets/almanac_doorway.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/context/almanac_context.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/date_words.dart';
import '../../../core/widgets/widgets.dart';
import '../application/cycle_providers.dart';
import '../domain/cycle_syncing.dart';
import 'cycle_text.dart';
import 'widgets/bleeding_marker.dart';
import 'widgets/cycle_length_stepper.dart';
import 'widgets/cycle_month_calendar.dart';
import 'widgets/cycle_moon_wheel.dart';

/// Where in the Cycle feature the user is.
sealed class CyclePage {
  const CyclePage();
}

/// The wheel, and the two ways deeper.
final class CycleHome extends CyclePage {
  const CycleHome();
}

/// Recording bleeding, month by month.
final class CycleCalendarPage extends CyclePage {
  const CycleCalendarPage();
}

/// The current phase, explored.
final class CycleSyncingPage extends CyclePage {
  const CycleSyncingPage();
}

/// The reflective moon-cycle explanation.
final class CycleMoonTypePage extends CyclePage {
  const CycleMoonTypePage();
}

/// Changing the assumed length, and deleting everything.
final class CycleAdjustPage extends CyclePage {
  const CycleAdjustPage();
}

/// A private record of a cycle, and what the moon happened to be doing.
///
/// **Three layers, and they stay apart.** Home observes the current
/// cycle beside the real moon. The Calendar records bleeding, which is
/// the only factual thing in here. Cycle Syncing explores the current
/// phase, which is partly estimated and which the user may correct.
///
/// **An inner page of the Almanac**, so it is written on paper: the same
/// warm cream in every season and at every hour, no landscape, and no
/// dark version after dark. The Environment outside is the living
/// painting; this is the book.
///
/// **Moon data is astronomy; bleeding is the user's record.** They are
/// drawn together and never conflated. Nothing here says the moon moves
/// a cycle, that a cycle should match the moon, or that one alignment is
/// better than another.
class CycleScreen extends ConsumerStatefulWidget {
  const CycleScreen({super.key});

  @override
  ConsumerState<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends ConsumerState<CycleScreen> {
  final List<CyclePage> _stack = [const CycleHome()];

  /// The month the calendar and the wheel are showing. Null means the
  /// month today is in.
  CalendarDate? _browsing;

  bool _saveFailed = false;

  CyclePage get _page => _stack.last;

  void _open(CyclePage page) => setState(() {
    _stack.add(page);
    _saveFailed = false;
  });

  void _back() => setState(() {
    if (_stack.length > 1) _stack.removeLast();
    _saveFailed = false;
  });

  void _toHome() => setState(() {
    _stack
      ..clear()
      ..add(const CycleHome());
    _saveFailed = false;
  });

  CycleController get _cycle => ref.read(cycleDataProvider.notifier);

  Future<void> _saving(Future<void> Function() change) async {
    try {
      await change();
      if (mounted) setState(() => _saveFailed = false);
    } on Object {
      if (mounted) setState(() => _saveFailed = true);
    }
  }

  /// Opens the editor for one day, and stays on the Calendar afterwards
  /// so several days in a row can be entered without navigating back in
  /// each time.
  Future<void> _editDay(CalendarDate date) async {
    final data = ref.read(cycleDataProvider).value ?? CycleData.empty;
    final result = await showModalBottomSheet<_DayEdit>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DayEditor(
        date: date,
        existing: data.recordOn(date),
        // The default only: the toggle stays visible and the user
        // decides.
        defaultIsStart: data.looksLikeNewEpisode(date),
      ),
    );
    if (result == null || !mounted) return;

    await _saving(() async {
      if (result.level == null) {
        await _cycle.clearDay(date);
      } else {
        await _cycle.record(
          date,
          result.level!,
          isPeriodStart: result.isPeriodStart,
        );
      }
    });
  }

  Future<void> _deleteEverything() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(CycleText.deleteAllTitle),
        content: const Text(CycleText.deleteAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(CycleText.delete),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(CycleText.keep),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _saving(_cycle.deleteEverything);
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    final today = ref.watch(todayProvider);
    final season = ref.watch(currentSeasonProvider);
    final month = _browsing ?? today;

    return AlmanacPaperSurface(
      child: AppScaffold(
        title: switch (page) {
          CycleHome() => CycleText.title,
          CycleCalendarPage() => CycleText.calendar,
          CycleSyncingPage() => CycleText.syncing,
          CycleMoonTypePage() => CycleText.moonCycleHeading,
          CycleAdjustPage() => CycleText.adjust,
        },
        subtitle: switch (page) {
          CycleHome() => CycleText.context(today.month, season),
          CycleCalendarPage() => formatMonth(month),
          _ => null,
        },
        trailing: const AlmanacButton(),
        body: [
          // Above the content: a way back at the far end of a long page
          // is a way back nobody reaches.
          if (page is! CycleHome)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _stack.length > 2 ? _back : _toHome,
                child: const Text(CycleText.back),
              ),
            ),

          switch (page) {
            CycleHome() => _Home(
              month: month,
              onCalendar: () => _open(const CycleCalendarPage()),
              onSyncing: () => _open(const CycleSyncingPage()),
              onMoonType: () => _open(const CycleMoonTypePage()),
              onAdjust: () => _open(const CycleAdjustPage()),
            ),

            CycleCalendarPage() => _CalendarPage(
              month: month,
              onMonth: (next) => setState(() => _browsing = next),
              onOpenDay: _editDay,
            ),

            CycleSyncingPage() => _SyncingPage(
              onChoosePhase: (phase) =>
                  _saving(() => _cycle.setDisplayedPhase(phase)),
            ),

            CycleMoonTypePage() => const _MoonTypePage(),

            CycleAdjustPage() => _AdjustPage(
              onLength: (length) =>
                  _saving(() => _cycle.setAssumedLength(length)),
              onDeleteAll: _deleteEverything,
            ),
          },

          if (_saveFailed)
            Semantics(
              container: true,
              liveRegion: true,
              child: Text(
                CycleText.saveFailed,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: context.palette.error),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cycle home: the wheel, and two ways deeper. Deliberately little else.
///
/// No food, no recipes, no movement, no meditation copy, no statistics
/// and no history chart. Those belong in Cycle Syncing, and there is a
/// test that they are not here.
class _Home extends ConsumerWidget {
  const _Home({
    required this.month,
    required this.onCalendar,
    required this.onSyncing,
    required this.onMoonType,
    required this.onAdjust,
  });

  final CalendarDate month;
  final VoidCallback onCalendar;
  final VoidCallback onSyncing;
  final VoidCallback onMoonType;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final moment = ref.watch(cycleMomentProvider);
    final data = ref.watch(cycleDataProvider).value ?? CycleData.empty;
    final moons = ref.watch(monthMoonsProvider(month));
    final moon = ref.watch(currentMoonProvider);
    final hemisphere = ref.watch(resolvedHemisphereProvider).hemisphere;
    final moonType = ref.watch(moonCycleTypeProvider);

    final thisMonth = [
      for (final record in data.records)
        if (record.date.year == month.year && record.date.month == month.month)
          record,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // One summary rather than thirty decorative moons.
        Semantics(
          container: true,
          label: CycleText.wheelSummary(
            today: today,
            moon: moon.phase,
            moment: moment,
            recordsThisMonth: thisMonth,
          ),
          excludeSemantics: true,
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: CycleMoonWheel(
                month: month,
                today: today,
                moons: moons,
                records: {
                  for (final record in thisMonth) record.date.day: record,
                },
                hemisphere: hemisphere,
                // Grows with the text, so the three lines in the middle
                // have room at 2x instead of being shrunk to fit.
                size: cycleWheelSizeFor(context, constraints.maxWidth),
                centre: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (moment.currentDay case final day?) ...[
                      Text(
                        CycleText.dayLine(day),
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (moment.displayedPhase case final phase?)
                        Text(
                          phase.label,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium,
                        ),
                    ] else
                      Text(
                        CycleText.noCycleYet,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall,
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    // The lunar line, quieter than the cycle above it.
                    Text(
                      moon.phase.label,
                      textAlign: TextAlign.center,
                      style: textTheme.labelMedium?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // The reflective reading, secondary and tappable — not the whole
        // explanation, which lives on its own page.
        if (moonType != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Semantics(
              container: true,
              button: true,
              label: '${moonType.label}. ${CycleText.moonCycleLine(moonType)}',
              excludeSemantics: true,
              child: InkWell(
                onTap: onMoonType,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppDimens.minTouchTarget,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(moonType.label, style: textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          CycleText.moonCycleLine(moonType),
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        _RouteCard(
          title: CycleText.calendar,
          description: CycleText.calendarDescription,
          onTap: onCalendar,
        ),
        const SizedBox(height: AppSpacing.md),
        _RouteCard(
          title: CycleText.syncing,
          description: CycleText.syncingDescription,
          onTap: onSyncing,
        ),

        if (moment.estimatedNextStart case final next?) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(CycleText.nextPeriodAround(next), style: textTheme.bodySmall),
        ],

        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onAdjust,
            child: const Text(CycleText.adjust),
          ),
        ),
        Text(CycleText.privacyNote, style: textTheme.bodySmall),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      button: true,
      label: '$title. $description',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimens.minTouchTarget,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(description, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Calendar: a month, and a tap to record a day.
class _CalendarPage extends ConsumerWidget {
  const _CalendarPage({
    required this.month,
    required this.onMonth,
    required this.onOpenDay,
  });

  final CalendarDate month;
  final ValueChanged<CalendarDate> onMonth;
  final ValueChanged<CalendarDate> onOpenDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final data = ref.watch(cycleDataProvider).value ?? CycleData.empty;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => onMonth(month.addMonths(-1)),
              icon: const Icon(Icons.chevron_left),
              tooltip: CycleText.previousMonth,
            ),
            Expanded(
              child: Text(
                formatMonth(month),
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: () => onMonth(month.addMonths(1)),
              icon: const Icon(Icons.chevron_right),
              tooltip: CycleText.nextMonth,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        CycleMonthCalendar(
          month: month,
          today: today,
          records: {
            for (final record in data.records)
              if (record.date.year == month.year &&
                  record.date.month == month.month)
                record.date.day: record,
          },
          onOpenDay: onOpenDay,
        ),
        const AlmanacSectionDivider(spacing: AppSpacing.lg),
        const BleedingLegend(),
        const SizedBox(height: AppSpacing.lg),
        Text(CycleText.privacyNote, style: textTheme.bodySmall),
      ],
    );
  }
}

/// What the day editor came back with. A null [level] means "nothing
/// recorded", which is the absence of a record rather than a level.
class _DayEdit {
  const _DayEdit({this.level, this.isPeriodStart = false});

  final BleedingLevel? level;
  final bool isPeriodStart;
}

/// One day, edited.
///
/// Four choices — none, spotting, bleeding, heavy — and, for the two
/// that can be a day 1, one visible toggle. Spotting never offers it:
/// somebody may spot at any point in a month, and treating that as day 1
/// would silently restart their cycle.
class _DayEditor extends StatefulWidget {
  const _DayEditor({
    required this.date,
    required this.existing,
    required this.defaultIsStart,
  });

  final CalendarDate date;
  final CycleDayRecord? existing;

  /// What the toggle starts at for a day with no record yet. A
  /// convenience, and the user can always say otherwise.
  final bool defaultIsStart;

  @override
  State<_DayEditor> createState() => _DayEditorState();
}

class _DayEditorState extends State<_DayEditor> {
  late BleedingLevel? _level = widget.existing?.level;
  late bool _isStart = widget.existing?.isPeriodStart ?? widget.defaultIsStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;

    return AlmanacPaperSurface(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatDate(widget.date), style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              Text(
                CycleText.bleedingHeading,
                style: textTheme.journalLabel?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              _LevelChoice(
                // Keyed, because "Bleeding" is also the heading above
                // these choices and a label alone is ambiguous.
                key: const ValueKey('level-none'),
                label: CycleText.nothingRecorded,
                selected: _level == null,
                onTap: () => setState(() => _level = null),
              ),
              for (final level in BleedingLevel.values)
                _LevelChoice(
                  key: ValueKey('level-${level.name}'),
                  label: level.label,
                  level: level,
                  selected: _level == level,
                  onTap: () => setState(() {
                    _level = level;
                    // Spotting can never be a day 1, so the flag goes
                    // with the choice rather than lingering invisibly.
                    if (!level.canStartPeriod) _isStart = false;
                  }),
                ),

              // Only for a level that can actually begin a cycle.
              if (_level?.canStartPeriod ?? false) ...[
                const SizedBox(height: AppSpacing.md),
                _PeriodStartToggle(
                  value: _isStart,
                  onChanged: (value) => setState(() => _isStart = value),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  // Flexible, because the button sizes itself to its
                  // label and a Row hands its children unbounded width.
                  Flexible(
                    child: PrimaryButton(
                      label: CycleText.save,
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(_DayEdit(level: _level, isPeriodStart: _isStart)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(CycleText.cancel),
                  ),
                ],
              ),
              if (widget.existing != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(const _DayEdit()),
                    child: const Text(CycleText.remove),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "First day of period", as a switch with its label beside it.
///
/// A plain row rather than a `SwitchListTile`: a list tile paints its
/// own background onto the nearest Material, which on a paper page is
/// the wrong surface — Flutter says so out loud in debug.
class _PeriodStartToggle extends StatelessWidget {
  const _PeriodStartToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      toggled: value,
      label: CycleText.firstDayOfPeriod,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimens.minTouchTarget,
          ),
          child: Row(
            children: [
              Switch(value: value, onChanged: onChanged),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  CycleText.firstDayOfPeriod,
                  style: textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelChoice extends StatelessWidget {
  const _LevelChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.level,
  });

  final String label;
  final BleedingLevel? level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimens.minTouchTarget,
          ),
          child: Row(
            children: [
              // A second, non-colour signal.
              Icon(
                selected ? Icons.check : null,
                size: AppIconSize.sm,
                color: palette.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              if (level case final marked?)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: BleedingMarker(
                    level: marked,
                    size: BleedingLegend.swatchSize,
                  ),
                ),
              Expanded(
                child: Text(
                  label,
                  style: selected ? textTheme.titleMedium : textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cycle Syncing: the current phase, explored.
class _SyncingPage extends ConsumerWidget {
  const _SyncingPage({required this.onChoosePhase});

  /// Null sets the phase back to the automatic estimate.
  final ValueChanged<CyclePhase?> onChoosePhase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final moment = ref.watch(cycleMomentProvider);
    final phase = moment.displayedPhase;

    if (phase == null) {
      // No cycle to count from, and nothing chosen. The four phases are
      // offered to read about rather than one being guessed at.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(CycleText.chooseAPhase, style: textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          _PhaseChoices(selected: null, onChoose: onChoosePhase),
        ],
      );
    }

    final guide = PhaseGuides.forPhase(phase);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${phase.label} phase', style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        if (moment.phaseIsManual)
          Text(CycleText.phaseIsYours, style: textTheme.bodySmall)
        else if (moment.currentDay case final day?)
          Text(CycleText.dayLineEstimated(day), style: textTheme.bodySmall),

        const SizedBox(height: AppSpacing.md),
        Text(
          CycleText.notQuiteRight,
          style: textTheme.journalLabel?.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        _PhaseChoices(
          selected: moment.manualPhase,
          onChoose: onChoosePhase,
          showAutomatic: true,
        ),

        const AlmanacSectionDivider(spacing: AppSpacing.lg),

        _Section(heading: CycleText.focusHeading, lines: [guide.focus]),
        _Section(heading: CycleText.aboutHeading, lines: [guide.about]),

        // The guidance is here whatever the Almanac contains. Only the
        // doorway under it depends on a feature being switched on.
        _Section(
          heading: CycleText.foodHeading,
          lines: guide.food,
          doorway: AlmanacDoorway(
            label: CycleText.seeRecipes,
            intent: CycleCookbookIntent(phase),
          ),
        ),
        _Section(
          heading: CycleText.movementHeading,
          lines: guide.movement,
          doorway: AlmanacDoorway(
            label: CycleText.tryYoga,
            intent: CycleYogaIntent(phase),
          ),
        ),
        _Section(
          heading: CycleText.mindHeading,
          lines: [guide.reflection],
          doorway: AlmanacDoorway(
            label: CycleText.tryMeditation,
            intent: CycleMeditationIntent(phase),
          ),
        ),
        _Section(heading: CycleText.durationHeading, lines: [guide.duration]),

        Text(kExperienceMayDiffer, style: textTheme.bodySmall),
      ],
    );
  }
}

/// One passage of Cycle Syncing: a journal label, some lines, and — when
/// the destination is part of the Almanac — one doorway.
class _Section extends StatelessWidget {
  const _Section({required this.heading, required this.lines, this.doorway});

  final String heading;
  final List<String> lines;
  final Widget? doorway;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: textTheme.journalLabel?.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(line, style: textTheme.journalNote),
            ),
          if (doorway case final door?)
            Align(alignment: Alignment.centerLeft, child: door),
        ],
      ),
    );
  }
}

/// The four phases, and a way back to the estimate.
class _PhaseChoices extends StatelessWidget {
  const _PhaseChoices({
    required this.selected,
    required this.onChoose,
    this.showAutomatic = false,
  });

  final CyclePhase? selected;
  final ValueChanged<CyclePhase?> onChoose;
  final bool showAutomatic;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (final phase in CyclePhase.values)
        _Chip(
          label: phase.label,
          selected: phase == selected,
          onTap: () => onChoose(phase),
        ),
      if (showAutomatic)
        _Chip(
          label: CycleText.automaticEstimate,
          selected: selected == null,
          onTap: () => onChoose(null),
        ),
    ],
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? palette.primarySoft : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: selected ? palette.primary : palette.border,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimens.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    Icon(
                      Icons.check,
                      size: AppIconSize.sm,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  // Flexible, so a long label — "Use automatic
                  // estimate" — wraps inside the chip instead of
                  // overflowing it, at any text size.
                  Flexible(child: Text(label, style: textTheme.labelLarge)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The reflective moon-cycle reading, in full.
class _MoonTypePage extends ConsumerWidget {
  const _MoonTypePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final type = ref.watch(moonCycleTypeProvider);
    if (type == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(CycleText.moonCycleFraming, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        Text(type.label, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          CycleText.moonCycleThemes(type).join(' · '),
          style: textTheme.journalLabel?.copyWith(color: palette.primary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(CycleText.moonCycleAbout(type), style: textTheme.journalNote),
        const SizedBox(height: AppSpacing.lg),
        Text(CycleText.moonCycleLine(type), style: textTheme.bodyMedium),
        const AlmanacSectionDivider(spacing: AppSpacing.lg),
        Text(CycleText.moonCycleChanges, style: textTheme.bodySmall),
      ],
    );
  }
}

/// The assumed length, and the way to delete everything.
class _AdjustPage extends ConsumerWidget {
  const _AdjustPage({required this.onLength, required this.onDeleteAll});

  final ValueChanged<int> onLength;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final data = ref.watch(cycleDataProvider).value ?? CycleData.empty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(CycleText.lengthHeading, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        CycleLengthStepper(
          length: data.assumedCycleLength,
          onChanged: onLength,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(CycleText.lengthNote, style: textTheme.bodySmall),
        const AlmanacSectionDivider(spacing: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onDeleteAll,
            child: const Text(CycleText.deleteAll),
          ),
        ),
        Text(CycleText.privacyNote, style: textTheme.bodySmall),
      ],
    );
  }
}
