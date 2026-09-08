import '../../../core/environment/season.dart';
import '../../../core/time/date_words.dart';
import '../application/nature_log_providers.dart';

/// Everything the Nature Log says.
///
/// Gathered in one file like the rest of the app's copy, and with two
/// lines it must not cross: it never says anybody saw anything, and it
/// never says anything about eating, keeping or handling what they
/// noticed. `nature_content_test.dart` reads every string here and every
/// line of the Nature Book.
abstract final class NatureLogText {
  static const title = 'Nature Log';

  static const aroundNow = 'Around now';
  static const myObservations = 'My observations';
  static const recordSomething = 'Record something';

  static const aroundNowDescription =
      'What the guide says may be worth noticing.';
  static const myObservationsDescription = 'What you have noticed.';

  // Recording.
  static const whatDidYouNotice = 'What did you notice?';
  static const chooseFromBook = 'Choose from the Nature Book';
  static const writeYourOwn = 'Write your own';
  static const recordAnObservation = 'Record an observation';
  static const saveObservation = 'Save observation';
  static const saveChanges = 'Save changes';
  static const added = 'Added to your Nature Log.';
  static const nameLabel = 'What was it?';
  static const nameHint = 'Tiny green beetle';
  static const categoryLabel = 'Where does it belong?';
  static const noteLabel = 'A note';
  static const noteHint = 'Anything you want to remember.';
  static const placeLabel = 'Where were you?';
  static const placeHint = 'Back garden';
  static const dateLabel = 'When';
  static const changeDate = 'Change the date';

  // Empty states.
  static const nothingAroundNow =
      'Nothing in the Nature Book has a note for this month.';
  static const noGuideHere =
      'Your Nature Book does not know which regional guide applies here '
      'yet.';
  static const noGuideNote =
      'You can still record whatever you notice — the log is yours, '
      'wherever you are.';

  /// Said only when the reason is that no position was resolved. It
  /// explains; it does not ask, and there is no button beside it.
  static const noLocationNote =
      'Location is off, so seasonal species suggestions are not being '
      'shown.';

  /// Said where the whole book is on offer, so browsing a reference
  /// catalogue is never mistaken for being told these things are
  /// around you now.
  static const bookIsReference =
      'The whole Nature Book is here to read and record from, wherever '
      'you are.';
  static const logEmpty = 'Nothing noticed yet.';
  static const logEmptyNote =
      'Anything you record stays here, in the order you noticed it.';

  // Removing.
  static const removeTitle = 'Remove this observation?';
  static const removeBody = 'This removes it from your Nature Log.';
  static const remove = 'Remove';
  static const keep = 'Keep';
  static const clearAll = 'Clear my Nature Log';
  static const clearTitle = 'Clear your Nature Log?';
  static const clearBody =
      'Everything you have noticed will be removed from this device.';
  static const back = 'Back';
  static const saveFailed = 'That could not be saved on this device.';

  /// Said on the fungi shelf, and only there. It is not advice about
  /// eating anything — it is the app declining to be that.
  static const fungiNote =
      'This is a guide to noticing, not to foraging. It says nothing '
      'about which fungi are safe.';

  /// Where the log lives. Said on the screen, not only in a report.
  static const privacyNote =
      'Your Nature Log is kept on this device only. No place is recorded '
      'unless you write one.';

  /// "September · Spring".
  static String context(int month, Season season) =>
      '${monthName(month)} · ${season.label}';

  /// "Spring · New Zealand guide", the line under Around now.
  static String guideLine(NatureGuide guide, Season season) =>
      '${season.label} · ${guide.coverage.label}';

  /// "12 September", a date heading in the log.
  static String dateHeading(CalendarDate date) => formatDate(date);

  /// "Tūī. Bird. Recorded 12 September." — an observation, spoken.
  static String observationLabel(NatureObservation observation) =>
      '${observation.label}. ${observation.category.label}. '
      'Recorded ${formatShortDate(observation.date)}.';

  /// "5 things noticed this spring."
  ///
  /// One quiet line, and only when there is something to say. Not a
  /// total to beat, not a streak, and it disappears at zero.
  static String? seasonSummary(int count, Season season) {
    if (count == 0) return null;
    final things = count == 1 ? '1 thing' : '$count things';
    return '$things noticed this ${season.label.toLowerCase()}.';
  }

  /// Everything fixed in this file, for the content test to read.
  static List<String> get everythingSaid => [
    title,
    aroundNow,
    myObservations,
    recordSomething,
    aroundNowDescription,
    myObservationsDescription,
    whatDidYouNotice,
    chooseFromBook,
    writeYourOwn,
    recordAnObservation,
    saveObservation,
    saveChanges,
    added,
    nameLabel,
    nameHint,
    categoryLabel,
    noteLabel,
    noteHint,
    placeLabel,
    placeHint,
    dateLabel,
    changeDate,
    nothingAroundNow,
    noGuideHere,
    noGuideNote,
    noLocationNote,
    bookIsReference,
    logEmpty,
    logEmptyNote,
    removeTitle,
    removeBody,
    remove,
    keep,
    clearAll,
    clearTitle,
    clearBody,
    back,
    saveFailed,
    fungiNote,
    privacyNote,
    for (final category in NatureCategory.values) ...[
      category.label,
      category.plural,
    ],
    for (final kind in NatureNoteKind.values) kind.label,
    for (final coverage in NatureCoverage.values) coverage.label,
    ?seasonSummary(5, Season.spring),
  ];
}
