import '../../../core/time/calendar_date.dart';
import 'cycle_data.dart';
import 'cycle_moment.dart';
import 'cycle_phase.dart';

export 'cycle_data.dart';
export 'cycle_moment.dart';
export 'cycle_phase.dart';

/// Works out where a cycle has got to.
///
/// A pure function of its arguments: [today] is passed in rather than
/// read from a clock, there is nothing random in here, and nothing is
/// stored or logged. The same three inputs always give the same
/// [CycleMoment], which is what makes the whole model testable a day at
/// a time.
///
/// It is safe on every shape of input the app can reach it with: no
/// records at all, records only in the future, a today before the first
/// recorded date, and a cycle running longer than the estimate.
///
/// **Cycle day comes from the latest recorded period start**, which is a
/// property the user set on a bleeding day. Spotting is never one, so a
/// month of spotting leaves the cycle exactly where it was — see
/// `BleedingLevel.canStartPeriod`.
///
/// **What is recorded and what is estimated stay apart.** The phase here
/// is estimated from the cycle day; it never invents a bleeding record,
/// and a day inside the estimated menstrual span is not claimed as
/// bleeding unless the user recorded it.
CycleMoment cycleMomentAt({
  required CalendarDate today,
  required CycleData data,
}) {
  final length = data.assumedCycleLength;

  // The current cycle is counted from the most recent start on or before
  // today. Anything recorded later than today belongs to a cycle that
  // has not begun, and is left out of this — though it is still shown on
  // the calendar, because the user put it there.
  CalendarDate? recordedStart;
  for (final start in data.periodStarts) {
    if (start.isOnOrBefore(today)) recordedStart = start;
  }

  if (recordedStart == null) {
    return CycleMoment(
      today: today,
      assumedCycleLength: length,
      recordedStart: null,
      currentDay: null,
      phase: null,
      manualPhase: data.manualPhase,
      estimatedNextStart: null,
      estimatedOvulatoryWindow: null,
      recordedLengths: data.recordedLengths,
      hasRecords: data.isNotEmpty,
      recordedToday: data.recordOn(today),
    );
  }

  // Day 1 is the recorded start itself, so the day the user taps
  // "Record today" they are on day 1, and the following day is day 2.
  final currentDay = today.daysSince(recordedStart) + 1;

  final window = phaseSpansFor(length)
      .firstWhere((span) => span.phase == CyclePhase.ovulatory);

  return CycleMoment(
    today: today,
    assumedCycleLength: length,
    recordedStart: recordedStart,
    currentDay: currentDay,
    phase: phaseForDay(currentDay, length),
    manualPhase: data.manualPhase,
    estimatedNextStart: recordedStart.addDays(length),
    estimatedOvulatoryWindow: DateRange(
      // Cycle day N is the recorded start plus N-1 days.
      recordedStart.addDays(window.firstDay - 1),
      recordedStart.addDays(window.lastDay - 1),
    ),
    recordedLengths: data.recordedLengths,
    hasRecords: true,
    recordedToday: data.recordOn(today),
  );
}

/// The approximate phase for a given cycle day.
///
/// A day past the end of the estimate stays luteal: the estimate has
/// simply run out, which is ordinary, and inventing a fifth phase for it
/// would be inventing meaning.
CyclePhase phaseForDay(int day, int length) {
  for (final span in phaseSpansFor(length)) {
    if (span.contains(day)) return span.phase;
  }
  return day < 1 ? CyclePhase.menstrual : CyclePhase.luteal;
}
