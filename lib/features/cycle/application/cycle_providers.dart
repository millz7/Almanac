import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/context/almanac_context.dart';
import '../../../core/environment/environment_providers.dart';
import '../../../core/environment/local_time_zone.dart';
import '../../../core/environment/moon_service.dart';
import '../../../core/time/calendar_date.dart';
import '../data/cycle_store.dart';
import '../data/shared_preferences_cycle_store.dart';
import '../domain/cycle_calculator.dart';
import '../domain/moon_cycle_type.dart';

export '../../../core/time/clock_providers.dart' show todayProvider;
export '../data/cycle_store.dart';
export '../domain/cycle_calculator.dart';
export '../domain/moon_cycle_type.dart';

/// Where cycle data is kept. Tests override it; the app uses the
/// preferences-backed store, opened lazily on first use.
final cycleStoreProvider = Provider<CycleStore>(
  (ref) => SharedPreferencesCycleStore(),
);

/// What the user recorded, their chosen estimate length, and any phase
/// they chose to display.
///
/// Read from the store on first use — which is also where Step 11's data
/// is migrated — and written back on every change. Nothing here leaves
/// the device.
final cycleDataProvider = AsyncNotifierProvider<CycleController, CycleData>(
  CycleController.new,
);

class CycleController extends AsyncNotifier<CycleData> {
  @override
  Future<CycleData> build() => ref.read(cycleStoreProvider).read();

  CycleData get _data => state.value ?? CycleData.empty;

  /// Records or replaces one day's bleeding.
  ///
  /// Refuses a date in the future: the calendar cannot offer one, but the
  /// rule belongs here too, because nothing can have been noticed on a
  /// day that has not happened.
  ///
  /// [isPeriodStart] is the user's answer, taken from the editor. A
  /// spotting day's flag is dropped by [CycleData] — spotting never
  /// begins a cycle.
  ///
  /// **A new period start clears a stale phase override.** If the user
  /// had told Cycle Syncing which phase to show, that answer was about
  /// the cycle that has just ended, so it is let go rather than carried
  /// into the new one.
  Future<void> record(
    CalendarDate date,
    BleedingLevel level, {
    bool isPeriodStart = false,
  }) async {
    if (date.isAfter(ref.read(todayProvider))) return;

    final next = _data.recording(date, level, isPeriodStart: isPeriodStart);
    final startsNewCycle =
        isPeriodStart && level.canStartPeriod && !_data.isPeriodStart(date);
    await _persist(startsNewCycle ? next.withManualPhase(null) : next);
  }

  /// Removes a day's record. "Nothing recorded" is the absence of a
  /// record, so this is how a day goes back to nothing.
  Future<void> clearDay(CalendarDate date) => _persist(_data.clearing(date));

  /// Changes which bleeding day counts as cycle day 1.
  ///
  /// Never erases a bleeding record: only the flag moves, and the day
  /// stays recorded exactly as the user entered it. Marking a new day 1
  /// clears a stale override for the same reason [record] does.
  Future<void> setPeriodStart(CalendarDate date, {required bool isStart}) {
    final next = _data.markingPeriodStart(date, isStart: isStart);
    return _persist(
      isStart && !_data.isPeriodStart(date) ? next.withManualPhase(null) : next,
    );
  }

  /// Changes what the estimates are drawn with — and only that. The
  /// recorded days are passed through untouched.
  Future<void> setAssumedLength(int length) =>
      _persist(_data.withAssumedLength(length));

  /// Sets the phase Cycle Syncing shows, or clears it back to the
  /// automatic estimate.
  ///
  /// Touches nothing factual: no record, no date, no day 1.
  Future<void> setDisplayedPhase(CyclePhase? phase) =>
      _persist(_data.withManualPhase(phase));

  /// Removes everything, from memory and from storage.
  Future<void> deleteEverything() async {
    await ref.read(cycleStoreProvider).deleteAll();
    state = AsyncData(CycleData.empty);
  }

  /// Writes first, then updates what the screen shows, so the app never
  /// displays a change that was not stored. A failure propagates to the
  /// caller, which tells the user rather than pretending.
  Future<void> _persist(CycleData next) async {
    await ref.read(cycleStoreProvider).write(next);
    state = AsyncData(next);
  }
}

/// Where the cycle has got to today.
final cycleMomentProvider = Provider<CycleMoment>((ref) {
  final data = ref.watch(cycleDataProvider).value ?? CycleData.empty;
  return cycleMomentAt(today: ref.watch(todayProvider), data: data);
});

/// The phase Cycle shows: the user's own answer if they gave one,
/// otherwise the estimate. Null when there is neither.
final displayedCyclePhaseProvider = Provider<CyclePhase?>(
  (ref) => ref.watch(cycleMomentProvider).displayedPhase,
);

/// A reflective reading of which moon the latest period began under.
///
/// Null when there is no recorded day 1 — the type is derived from one,
/// and there is nothing to derive it from.
///
/// **The instant the phase is read at.** Bleeding records are dates, not
/// instants, so this asks the existing moon service for the phase at
/// **midday in the user's own time zone** on that date. Midday because
/// it is the furthest point from either midnight, so a date's phase does
/// not hinge on which side of a boundary a rounding fell; local because
/// the date is the user's local date, and using midnight UTC would move
/// somebody in Auckland to the previous afternoon.
final moonCycleTypeProvider = Provider<MoonCycleType?>((ref) {
  final start = ref.watch(cycleMomentProvider).recordedStart;
  if (start == null) return null;

  return MoonCycleType.forPhase(
    ref
        .watch(moonServiceProvider)
        .phaseAt(localNoonOf(start, ref.watch(timeZoneProvider)))
        .phase,
  );
});

/// Midday, in the user's own time zone, on a recorded date.
///
/// **Why this instant.** A bleeding record is a *date*, and the moon
/// service wants an *instant*. Midday is the furthest point from either
/// midnight, so which phase a date falls in never hinges on which side
/// of a boundary a rounding landed. And it is local midday, through the
/// existing time-zone seam, because the date the user wrote down was
/// their local date — midnight UTC would put somebody in Auckland on
/// the previous afternoon.
DateTime localNoonOf(CalendarDate date, LocalTimeZone zone) =>
    zone.instantAtLocal(date.year, date.month, date.day, 12);

/// The moon for every day of a month, for the wheel.
///
/// Reads the existing [moonServiceProvider] once per date, at the same
/// local midday [moonCycleTypeProvider] uses, so the wheel and the moon
/// cycle type can never disagree about what a date's moon was. There is
/// no second lunar calculation anywhere in this feature.
final monthMoonsProvider = Provider.family<List<MoonPhaseState>, CalendarDate>((
  ref,
  month,
) {
  final zone = ref.watch(timeZoneProvider);
  final service = ref.watch(moonServiceProvider);
  final first = CalendarDate(month.year, month.month, 1);

  return [
    for (var day = 0; day < month.daysInMonth; day++)
      service.phaseAt(localNoonOf(first.addDays(day), zone)),
  ];
});
