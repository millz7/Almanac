import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/almanac_button.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/date_words.dart';
import '../../../core/widgets/widgets.dart';
import '../application/cycle_providers.dart';
import 'cycle_text.dart';
import 'widgets/cycle_calendar.dart';
import 'widgets/cycle_length_stepper.dart';
import 'widgets/cycle_wheel.dart';

/// Which of the feature's pages is showing.
enum CycleView {
  /// Where the cycle has got to — or, with nothing recorded yet, the
  /// invitation to record something.
  cycle,

  /// A month at a time, recorded dates and estimated ones.
  calendar,

  /// The estimate length, and the recorded dates themselves.
  adjust,
}

/// How many estimated period starts to work out ahead of the recorded
/// one. Enough to browse a couple of years of calendar; they cost
/// nothing, and the calendar only draws the ones in the month on screen.
const _estimatesAhead = 24;

/// Notice where you are in your cycle.
///
/// **What this is careful not to be.** It records one thing — the first
/// day of a period — and does arithmetic on it. It does not predict
/// fertility, does not calculate any probability, does not diagnose
/// anything and does not tell anybody how they will feel. The estimated
/// phases are labelled "approximate" everywhere they appear, and the
/// recorded dates are always stated more prominently than anything
/// derived from them.
///
/// **Privacy.** Cycle dates are the most sensitive thing the app holds.
/// They live in their own store, on this device, behind their own keys,
/// with their own delete-everything. Nothing here reaches the network,
/// nothing is logged, and nothing about a cycle is shown anywhere else in
/// the app.
///
/// **No clock of its own.** Today arrives through [todayProvider] and the
/// calculation is a pure function of it, so there is no ticker, no timer
/// and no immersive mode. The only animation is a one-shot arrival.
class CycleScreen extends ConsumerStatefulWidget {
  const CycleScreen({super.key});

  @override
  ConsumerState<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends ConsumerState<CycleScreen> {
  CycleView _view = CycleView.cycle;

  /// The month the calendar is showing. Null until it is opened, so it
  /// always starts on today's month.
  CalendarDate? _month;

  bool _saveFailed = false;

  void _show(CycleView view) => setState(() {
    _view = view;
    _saveFailed = false;
  });

  /// Runs a change to stored data, and says so if it could not be saved.
  ///
  /// The controller writes before it updates what the screen shows, so a
  /// failure here means nothing changed — and the user is told rather
  /// than left with a screen that disagrees with the disk.
  Future<void> _saving(Future<void> Function() change) async {
    try {
      await change();
      if (mounted) setState(() => _saveFailed = false);
    } on Object {
      if (mounted) setState(() => _saveFailed = true);
    }
  }

  CycleController get _cycle => ref.read(cycleDataProvider.notifier);

  /// Asks for a date, offering nothing later than today.
  ///
  /// The bound is the picker's own [showDatePicker.lastDate], so a future
  /// date cannot be chosen at all rather than being chosen and then
  /// refused. The controller refuses one as well, for anything that
  /// reaches it another way.
  Future<CalendarDate?> _askForDate({CalendarDate? initial}) async {
    final today = ref.read(todayProvider);
    final start = initial ?? today;

    final picked = await showDatePicker(
      context: context,
      initialDate: start.toLocalDateTime(),
      // Three years is plenty of history for a feature that records one
      // date at a time, and keeps the picker from being a long scroll.
      firstDate: DateTime(today.year - 3),
      lastDate: today.toLocalDateTime(),
      helpText: 'First day of your period',
    );

    return picked == null ? null : CalendarDate.from(picked);
  }

  Future<bool> _confirmDeletion({
    required String title,
    required String body,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          // Keeping is the safe answer, so it is the one on the right,
          // where the affirmative usually sits.
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
    return confirmed ?? false;
  }

  Future<void> _recordToday() =>
      _saving(() => _cycle.recordStart(ref.read(todayProvider)));

  Future<void> _recordAnotherDate() async {
    final date = await _askForDate();
    if (date == null) return;
    await _saving(() => _cycle.recordStart(date));
  }

  Future<void> _editDate(CalendarDate date) async {
    final replacement = await _askForDate(initial: date);
    if (replacement == null || replacement == date) return;
    await _saving(() => _cycle.editStart(date, replacement));
  }

  Future<void> _deleteDate(CalendarDate date) async {
    final confirmed = await _confirmDeletion(
      title: CycleText.deleteOneTitle,
      body: CycleText.deleteOneBody,
    );
    if (!confirmed) return;
    await _saving(() => _cycle.deleteStart(date));
  }

  Future<void> _deleteEverything() async {
    final confirmed = await _confirmDeletion(
      title: CycleText.deleteAllTitle,
      body: CycleText.deleteAllBody,
    );
    if (!confirmed) return;
    await _saving(_cycle.deleteEverything);
    // Nothing is left to adjust, so this is a first use again.
    if (mounted) _show(CycleView.cycle);
  }

  /// Opening a recorded date from the calendar. An estimate cannot be
  /// opened, because there is nothing there to change.
  Future<void> _openRecordedDate(CalendarDate date) async {
    final action = await showDialog<_DateAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(formatDate(date)),
        content: const Text(CycleText.recordedLegend),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_DateAction.edit),
            child: const Text(CycleText.editDate),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_DateAction.delete),
            child: const Text(CycleText.deleteDate),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(CycleText.close),
          ),
        ],
      ),
    );

    switch (action) {
      case null:
        return;
      case _DateAction.edit:
        await _editDate(date);
      case _DateAction.delete:
        await _deleteDate(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(cycleDataProvider);
    final moment = ref.watch(cycleMomentProvider);

    return AppScaffold(
      title: CycleText.title,
      subtitle: switch (_view) {
        CycleView.cycle => null,
        CycleView.calendar => CycleText.calendar,
        CycleView.adjust => CycleText.adjust,
      },
      trailing: const AlmanacButton(),
      body: [
        // Nothing at all until the store has answered: flashing "Your
        // cycle, noticed." at somebody who has been using this for
        // months would be its own small betrayal.
        if (data.isLoading)
          const SizedBox.shrink()
        else
          switch (_view) {
            CycleView.cycle when !moment.hasRecords => _FirstUse(
              onRecordToday: _recordToday,
              onChooseDate: _recordAnotherDate,
            ),
            CycleView.cycle => _CurrentCycle(
              moment: moment,
              onCalendar: () => _show(CycleView.calendar),
              onAdjust: () => _show(CycleView.adjust),
            ),
            CycleView.calendar => _Calendar(
              moment: moment,
              recorded: (data.value ?? CycleData.empty).periodStarts.toSet(),
              month: _month ?? moment.today.firstOfMonth,
              onMonth: (month) => setState(() => _month = month),
              onTapRecorded: _openRecordedDate,
              onBack: () => _show(CycleView.cycle),
            ),
            CycleView.adjust => _Adjust(
              moment: moment,
              recorded: (data.value ?? CycleData.empty).periodStarts,
              onLength: (length) =>
                  _saving(() => _cycle.setAssumedLength(length)),
              onRecord: _recordAnotherDate,
              onEdit: _editDate,
              onDelete: _deleteDate,
              onDeleteAll: _deleteEverything,
              onBack: () => _show(CycleView.cycle),
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
    );
  }
}

enum _DateAction { edit, delete }

/// Nothing recorded yet.
class _FirstUse extends StatelessWidget {
  const _FirstUse({required this.onRecordToday, required this.onChooseDate});

  final VoidCallback onRecordToday;
  final VoidCallback onChooseDate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(CycleText.introHeading, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        Text(CycleText.introBody, style: textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.xl),

        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(
            label: CycleText.recordToday,
            onPressed: onRecordToday,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onChooseDate,
            child: const Text(CycleText.chooseAnotherDate),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        // Said here, before anything is recorded, rather than buried in
        // a settings page afterwards.
        Text(CycleText.privacyNote, style: textTheme.bodySmall),
      ],
    );
  }
}

/// Where the cycle has got to.
class _CurrentCycle extends StatefulWidget {
  const _CurrentCycle({
    required this.moment,
    required this.onCalendar,
    required this.onAdjust,
  });

  final CycleMoment moment;
  final VoidCallback onCalendar;
  final VoidCallback onAdjust;

  @override
  State<_CurrentCycle> createState() => _CurrentCycleState();
}

class _CurrentCycleState extends State<_CurrentCycle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // With motion turned off the wheel is simply already drawn. Nothing
    // about what it says changes.
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moment = widget.moment;
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final phase = moment.phase;
    final start = moment.recordedStart;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _entrance,
          builder: (context, _) => CycleWheel(
            moment: moment,
            entrance: Curves.easeOut.transform(_entrance.value),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // The number, and the phase under it. Said as one thing to a
        // screen reader, because that is one thought.
        Semantics(
          container: true,
          label: CycleText.cycleSummary(moment),
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(moment.dayLine, style: textTheme.displaySmall),
              if (phase != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(phase.heading, style: textTheme.titleMedium),
              ],
            ],
          ),
        ),

        if (start != null) ...[
          const SizedBox(height: AppSpacing.md),
          // The one thing here that is not an estimate, so it is stated
          // plainly and before any of them.
          Text(
            '${CycleText.recordedStartLabel}: ${formatDate(start)}',
            style: textTheme.bodyLarge,
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          CycleText.estimateBasis(moment.assumedCycleLength),
          style: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        ),

        if (phase != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(phase.reflection, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CycleText.experienceMayDiffer,
            style: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
          ),
        ],

        if (moment.pastEstimate) ...[
          const SizedBox(height: AppSpacing.md),
          Text(CycleText.pastEstimate, style: textTheme.bodyMedium),
        ],

        // Everything derived, gathered in one quieter place so it can
        // never be mistaken for something that was recorded.
        if (moment.hasCurrentCycle) ...[
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(CycleText.estimatesHeading, style: textTheme.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                if (moment.estimatedOvulatoryWindow case final window?)
                  Text(
                    CycleText.estimatedWindow(window),
                    style: textTheme.bodyMedium,
                  ),
                if (moment.estimatedNextStart case final next?) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    CycleText.estimatedNextStart(next),
                    style: textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(CycleText.estimateCaution, style: textTheme.bodySmall),
                if (moment.unusualForModel) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(CycleText.unusualLength, style: textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],

        if (moment.recordedLengths.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _RecentCycles(lengths: moment.recordedLengths),
        ],

        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          children: [
            TextButton(
              onPressed: widget.onCalendar,
              child: const Text(CycleText.calendar),
            ),
            TextButton(
              onPressed: widget.onAdjust,
              child: const Text(CycleText.adjust),
            ),
          ],
        ),
      ],
    );
  }
}

/// The gaps between recorded dates, as observations and nothing else.
///
/// No average, no judgement, nothing called normal. A list of what
/// happened.
class _RecentCycles extends StatelessWidget {
  const _RecentCycles({required this.lengths});

  final List<int> lengths;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Most recent first, and only a handful: this is a glance, not a
    // history screen.
    final recent = lengths.reversed.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: CycleText.recentCyclesHeading),
        const SizedBox(height: AppSpacing.sm),
        for (final length in recent)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              '${CycleText.recordedLengthLabel}: ${CycleText.days(length)}',
              style: textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
}

/// A month at a time.
class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.moment,
    required this.recorded,
    required this.month,
    required this.onMonth,
    required this.onTapRecorded,
    required this.onBack,
  });

  final CycleMoment moment;
  final Set<CalendarDate> recorded;
  final CalendarDate month;
  final ValueChanged<CalendarDate> onMonth;
  final ValueChanged<CalendarDate> onTapRecorded;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CycleCalendar(
          month: month,
          today: moment.today,
          recorded: recorded,
          // Only ever forwards from the recorded date. With one date
          // recorded there is no history to estimate, and none is
          // invented.
          estimated: moment.estimatedStarts(_estimatesAhead).toSet(),
          onPrevious: () => onMonth(month.addMonths(-1)),
          onNext: () => onMonth(month.addMonths(1)),
          onTapRecorded: onTapRecorded,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(CycleText.estimateCaution, style: textTheme.bodySmall),

        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onBack,
            child: const Text(CycleText.back),
          ),
        ),
      ],
    );
  }
}

/// The estimate length, and the recorded dates themselves.
class _Adjust extends StatelessWidget {
  const _Adjust({
    required this.moment,
    required this.recorded,
    required this.onLength,
    required this.onRecord,
    required this.onEdit,
    required this.onDelete,
    required this.onDeleteAll,
    required this.onBack,
  });

  final CycleMoment moment;
  final List<CalendarDate> recorded;
  final ValueChanged<int> onLength;
  final VoidCallback onRecord;
  final ValueChanged<CalendarDate> onEdit;
  final ValueChanged<CalendarDate> onDelete;
  final VoidCallback onDeleteAll;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CycleLengthStepper(
          length: moment.assumedCycleLength,
          onChanged: onLength,
        ),
        const SizedBox(height: AppSpacing.lg),

        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(
            label: CycleText.recordAnother,
            onPressed: onRecord,
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: CycleText.recordedDatesHeading),
        const SizedBox(height: AppSpacing.sm),
        if (recorded.isEmpty)
          Text(CycleText.noCycleYet, style: textTheme.bodyMedium)
        else
          // Most recent first: the date somebody wants to correct is
          // almost always the last one they entered.
          for (final date in recorded.reversed)
            _RecordedRow(
              date: date,
              onEdit: () => onEdit(date),
              onDelete: () => onDelete(date),
            ),

        const SizedBox(height: AppSpacing.xl),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onDeleteAll,
            child: const Text(CycleText.deleteAll),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(CycleText.privacyNote, style: textTheme.bodySmall),

        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onBack,
            child: const Text(CycleText.back),
          ),
        ),
      ],
    );
  }
}

class _RecordedRow extends StatelessWidget {
  const _RecordedRow({
    required this.date,
    required this.onEdit,
    required this.onDelete,
  });

  final CalendarDate date;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(formatDate(date), style: textTheme.bodyLarge)),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_calendar_outlined),
            // The date is in the label, so a screen reader moving
            // through a list of these always knows which one it is on.
            tooltip: '${CycleText.editDate}, ${formatDate(date)}',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: '${CycleText.deleteDate}, ${formatDate(date)}',
          ),
        ],
      ),
    );
  }
}
