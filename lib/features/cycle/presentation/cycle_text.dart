import '../../../core/time/calendar_date.dart';
import '../../../core/time/date_words.dart';
import '../domain/cycle_calculator.dart';

/// Everything the Cycle feature says.
///
/// Gathered in one file for the same reason the Environment's wording is:
/// so the phrasing can be read as prose and reviewed as a whole. Here it
/// matters more than anywhere else in the app. Cycle wording has to stay
/// on the right side of a line — it describes what the user recorded and
/// what simple arithmetic estimates from it, and it never diagnoses,
/// never promises, and never tells anybody how they will feel.
///
/// `cycle_content_test.dart` reads every string in this file.
abstract final class CycleText {
  static const title = 'Cycle';

  // First use.
  static const introHeading = 'Your cycle, noticed.';
  static const introBody =
      'Record the first day of your period to begin noticing your cycle.';
  static const recordToday = 'Record today';
  static const chooseAnotherDate = 'Choose another date';

  // The current cycle.
  static const noCycleYet = 'No cycle recorded yet';
  static const recordedStartLabel = 'Recorded start';
  static const estimatesHeading = 'Estimated from that date';
  static const estimateCaution =
      'Estimates are drawn from the cycle length you chose. They are not a '
      'prediction, and any cycle can be shorter or longer.';
  static const pastEstimate =
      'This cycle is longer than the estimate so far. That is simply what '
      'has been recorded.';
  static const unusualLength =
      'At this length the estimate is a very rough guide indeed.';
  static const experienceMayDiffer = kExperienceMayDiffer;

  // History.
  static const recentCyclesHeading = 'Recent cycles';
  static const recordedLengthLabel = 'Recorded cycle length';

  // The calendar.
  static const calendar = 'Calendar';
  static const recordedLegend = 'Recorded by you';
  static const estimatedLegend = 'Estimated';
  static const previousMonth = 'Previous month';
  static const nextMonth = 'Next month';
  static const today = 'Today';

  // Adjusting.
  static const adjust = 'Adjust';
  static const lengthHeading = 'Assumed cycle length';
  static const lengthNote =
      'Changing this changes the estimates only. Your recorded dates stay '
      'exactly as you entered them.';
  static const recordAnother = 'Record a period start';
  static const recordedDatesHeading = 'Recorded dates';
  static const editDate = 'Edit date';
  static const deleteDate = 'Delete this date';
  static const deleteAll = 'Delete all cycle data';
  static const back = 'Back';
  static const close = 'Close';

  // Deleting.
  static const deleteAllTitle = 'Delete your cycle history?';
  static const deleteAllBody =
      'Your recorded cycle dates will be removed from this device.';
  static const deleteOneTitle = 'Delete this recorded date?';
  static const deleteOneBody = 'It will be removed from this device.';
  static const delete = 'Delete';
  static const keep = 'Keep';

  // When storage will not co-operate.
  static const saveFailed = 'That could not be saved on this device.';

  // Where the data lives. Said on the screen, not only in a report.
  static const privacyNote =
      'Your cycle dates are kept on this device only. Nothing is sent '
      'anywhere, and you can delete them at any time.';

  /// "Cycle day 12" — the number this screen is about.
  static String dayLine(int day) => 'Cycle day $day';

  /// "Using a 28-day estimate".
  static String estimateBasis(int length) => 'Using a $length-day estimate';

  /// "Estimated next start: Tuesday 12 August".
  static String estimatedNextStart(CalendarDate date) =>
      'Estimated next start: ${formatDate(date)}';

  /// "Estimated ovulatory window: 28 to 30 July". A window, never a day,
  /// and never a claim that it happened.
  static String estimatedWindow(DateRange range) =>
      'Estimated ovulatory window: ${formatShortDate(range.from)} '
      'to ${formatShortDate(range.to)}';

  /// "28 days".
  static String days(int count) => '$count ${count == 1 ? 'day' : 'days'}';

  /// What a screen reader hears in place of the drawing.
  static String cycleSummary(CycleMoment moment) {
    final day = moment.currentDay;
    if (day == null) return noCycleYet;
    return '${dayLine(day)}. ${moment.phase!.heading}. '
        '${estimateBasis(moment.assumedCycleLength)}.';
  }

  /// A recorded date on the calendar, as a screen reader hears it.
  static String recordedDateLabel(CalendarDate date, {required bool isToday}) =>
      '${formatDate(date)}.${isToday ? ' $today.' : ''} '
      'Recorded period start. Open to edit or delete.';

  /// An estimated date on the calendar. Says "estimated" out loud, so
  /// nothing depends on seeing the difference.
  static String estimatedDateLabel(
    CalendarDate date, {
    required bool isToday,
  }) =>
      '${formatDate(date)}.${isToday ? ' $today.' : ''} '
      'Estimated period start.';

  static String plainDateLabel(CalendarDate date, {required bool isToday}) =>
      '${formatDate(date)}.${isToday ? ' $today.' : ''}';

  /// Everything in the file, for the content test to read.
  static List<String> get everythingSaid => [
    title,
    introHeading,
    introBody,
    recordToday,
    chooseAnotherDate,
    noCycleYet,
    recordedStartLabel,
    estimatesHeading,
    estimateCaution,
    pastEstimate,
    unusualLength,
    experienceMayDiffer,
    recentCyclesHeading,
    recordedLengthLabel,
    calendar,
    recordedLegend,
    estimatedLegend,
    previousMonth,
    nextMonth,
    today,
    adjust,
    lengthHeading,
    lengthNote,
    recordAnother,
    recordedDatesHeading,
    editDate,
    deleteDate,
    deleteAll,
    back,
    close,
    deleteAllTitle,
    deleteAllBody,
    deleteOneTitle,
    deleteOneBody,
    delete,
    keep,
    saveFailed,
    privacyNote,
    dayLine(12),
    estimateBasis(28),
    days(28),
    for (final phase in CyclePhase.values) ...[
      phase.label,
      phase.heading,
      phase.reflection,
    ],
  ];
}
