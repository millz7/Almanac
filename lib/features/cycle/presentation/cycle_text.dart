import '../../../core/environment/season.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/date_words.dart';
import '../domain/cycle_calculator.dart';
import '../domain/moon_cycle_type.dart';

/// Everything the Cycle feature says.
///
/// Gathered in one file for the same reason the Environment's wording
/// is: so the phrasing can be read as prose and reviewed as a whole.
/// Here it matters more than anywhere else in the app. Cycle wording has
/// to stay on the right side of a line — it describes what the user
/// recorded and what simple arithmetic estimates from it, and it never
/// diagnoses, never promises, and never tells anybody how they will
/// feel.
///
/// It also does not plaster the screen with disclaimers. "Estimated" is
/// said where a value is genuinely estimated; the medical claims are
/// kept out of the content rather than apologised for.
///
/// `cycle_content_test.dart` reads every string in this file.
abstract final class CycleText {
  static const title = 'Cycle';

  // Cycle home.
  static const calendar = 'Calendar';
  static const calendarDescription = 'Record bleeding';
  static const syncing = 'Cycle Syncing';
  static const syncingDescription = 'Explore your current phase';

  static const noCycleYet = 'Record your period to see your cycle here.';
  static const estimated = 'estimated';

  /// The reflective moon-cycle line on home, and its page.
  static const moonCycleHeading = 'Moon cycle';
  static const moonCycleFraming =
      'In some modern spiritual traditions, the moon a period begins '
      'under is given a name.';
  static const moonCycleChanges =
      'It is derived from each period you record, so it can be different '
      'next month. None of the four is better than another.';

  // The calendar.
  static const previousMonth = 'Previous month';
  static const nextMonth = 'Next month';
  static const today = 'Today';
  static const legend = 'Legend';
  static const firstDayOfPeriod = 'First day of period';
  static const firstDayShort = 'Day 1';
  static const bleedingHeading = 'Bleeding';
  static const nothingRecorded = 'None';
  static const save = 'Save';
  static const remove = 'Remove this day';
  static const cancel = 'Cancel';
  static const back = 'Back';
  static const close = 'Close';

  // Cycle Syncing.
  static const focusHeading = 'Focus';
  static const aboutHeading = 'About this phase';
  static const foodHeading = 'Food';
  static const movementHeading = 'Movement';
  static const mindHeading = 'Mind';
  static const durationHeading = 'Duration';
  static const adjustPhase = 'Adjust phase';
  static const notQuiteRight = 'Not quite right?';
  static const automaticEstimate = 'Use automatic estimate';
  static const phaseIsYours =
      'Showing the phase you chose. Your recorded dates are unchanged.';
  static const chooseAPhase =
      'There is no cycle to count from yet. Choose a phase to read about '
      'it.';
  static const seeRecipes = 'See recipes';
  static const tryYoga = 'Try a yoga practice';
  static const tryMeditation = 'Try a meditation';

  // Adjusting the estimate.
  static const adjust = 'Adjust';
  static const lengthHeading = 'Assumed cycle length';
  static const lengthNote =
      'Changing this changes the estimates only. Your recorded dates stay '
      'exactly as you entered them.';
  static const deleteAll = 'Delete all cycle data';
  static const deleteAllTitle = 'Delete your cycle history?';
  static const deleteAllBody =
      'Your recorded cycle dates will be removed from this device.';
  static const delete = 'Delete';
  static const keep = 'Keep';

  static const saveFailed = 'That could not be saved on this device.';

  /// Where the data lives. Said on the screen, not only in a report.
  static const privacyNote =
      'Your cycle records are kept on this device only. Nothing is sent '
      'anywhere, and you can delete them at any time.';

  /// "September · Spring" — the context line under the title.
  static String context(int month, Season season) =>
      '${monthName(month)} · ${season.label}';

  /// "Cycle day 12".
  static String dayLine(int day) => 'Cycle day $day';

  /// "Cycle day 12 · estimated".
  static String dayLineEstimated(int day) => '${dayLine(day)} · $estimated';

  /// "Using a 28-day estimate".
  static String estimateBasis(int length) => 'Using a $length-day estimate';

  /// "Next period around 24 September · estimated".
  static String nextPeriodAround(CalendarDate date) =>
      'Next period around ${formatShortDate(date)} · $estimated';

  /// "Your last period began during the waxing moon."
  static String moonCycleLine(MoonCycleType type) => switch (type) {
    MoonCycleType.white => 'Your last period began around the new moon.',
    MoonCycleType.red => 'Your last period began around the full moon.',
    MoonCycleType.pink => 'Your last period began during the waxing moon.',
    MoonCycleType.purple => 'Your last period began during the waning moon.',
  };

  /// The reflective description of a moon cycle type.
  static String moonCycleAbout(MoonCycleType type) => switch (type) {
    MoonCycleType.white =>
      'In some modern spiritual traditions, bleeding around the new moon '
          'is called a White Moon cycle, and associated with turning '
          'inward, rest, reflection and renewal.',
    MoonCycleType.red =>
      'In some modern spiritual traditions, bleeding around the full '
          'moon is called a Red Moon cycle, and associated with '
          'expression, creativity, outward energy and sharing.',
    MoonCycleType.pink =>
      'In some modern spiritual traditions, bleeding during the waxing '
          'moon is called a Pink Moon cycle, and associated with '
          'transition, growth, discovery and emerging energy.',
    MoonCycleType.purple =>
      'In some modern spiritual traditions, bleeding during the waning '
          'moon is called a Purple Moon cycle, and associated with '
          'transition, intuition, release and turning inward.',
  };

  /// The four words a type is associated with.
  static List<String> moonCycleThemes(MoonCycleType type) => switch (type) {
    MoonCycleType.white => ['Inward', 'Rest', 'Reflection', 'Renewal'],
    MoonCycleType.red => ['Expression', 'Creativity', 'Outward', 'Sharing'],
    MoonCycleType.pink => ['Transition', 'Growth', 'Discovery', 'Emerging'],
    MoonCycleType.purple => ['Transition', 'Intuition', 'Release', 'Inward'],
  };

  /// "28 days".
  static String days(int count) => '$count ${count == 1 ? 'day' : 'days'}';

  /// What a screen reader hears in place of the month wheel.
  ///
  /// One summary rather than thirty decorative nodes: the month, today,
  /// today's moon, where the cycle has got to, and which days carry a
  /// record.
  static String wheelSummary({
    required CalendarDate today,
    required MoonPhase moon,
    required CycleMoment moment,
    required List<CycleDayRecord> recordsThisMonth,
  }) {
    final parts = <String>[
      '${monthName(today.month)} lunar calendar.',
      'Today is ${formatShortDate(today)}.',
      '${moon.label}.',
      if (moment.currentDay case final day?)
        '${dayLine(day)}.'
      else
        'No cycle recorded.',
      if (moment.displayedPhase case final phase?) '${phase.label} phase.',
    ];

    for (final level in BleedingLevel.values) {
      final days = [
        for (final record in recordsThisMonth)
          if (record.level == level) '${record.date.day}',
      ];
      if (days.isNotEmpty) {
        parts.add('${level.label} recorded on ${_list(days)}.');
      }
    }
    return parts.join(' ');
  }

  /// A calendar day, as a screen reader hears it.
  ///
  /// "4 September. Heavy bleeding. First day of period." — the record
  /// and its meaning in words, so nothing depends on seeing a dot.
  static String calendarDayLabel({
    required CalendarDate date,
    required CycleDayRecord? record,
    required bool isToday,
  }) {
    final parts = <String>[
      formatShortDate(date),
      if (isToday) today,
      if (record != null) record.level.label,
      if (record?.isPeriodStart ?? false) firstDayOfPeriod,
    ];
    return '${parts.join('. ')}.';
  }

  /// "2, 3 and 4".
  static String _list(List<String> items) {
    if (items.length == 1) return items.single;
    return '${items.take(items.length - 1).join(', ')} and ${items.last}';
  }

  /// Everything fixed in the file, for the content test to read.
  static List<String> get everythingSaid => [
    title,
    calendar,
    calendarDescription,
    syncing,
    syncingDescription,
    noCycleYet,
    estimated,
    moonCycleHeading,
    moonCycleFraming,
    moonCycleChanges,
    previousMonth,
    nextMonth,
    today,
    legend,
    firstDayOfPeriod,
    firstDayShort,
    bleedingHeading,
    nothingRecorded,
    save,
    remove,
    cancel,
    back,
    close,
    focusHeading,
    aboutHeading,
    foodHeading,
    movementHeading,
    mindHeading,
    durationHeading,
    adjustPhase,
    notQuiteRight,
    automaticEstimate,
    phaseIsYours,
    chooseAPhase,
    seeRecipes,
    tryYoga,
    tryMeditation,
    adjust,
    lengthHeading,
    lengthNote,
    deleteAll,
    deleteAllTitle,
    deleteAllBody,
    delete,
    keep,
    saveFailed,
    privacyNote,
    dayLine(12),
    dayLineEstimated(12),
    estimateBasis(28),
    days(28),
    kExperienceMayDiffer,
    for (final level in BleedingLevel.values) level.label,
    for (final phase in CyclePhase.values) ...[
      phase.label,
      phase.heading,
      phase.phrase,
      phase.reflection,
    ],
    for (final type in MoonCycleType.values) ...[
      type.label,
      moonCycleLine(type),
      moonCycleAbout(type),
      ...moonCycleThemes(type),
    ],
  ];
}
