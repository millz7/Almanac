import '../../../core/time/calendar_date.dart';
import '../../../core/time/date_words.dart';
import '../domain/journal_entry.dart';

/// Every fixed word the Journal says.
abstract final class JournalText {
  static const title = 'Journal';
  static const today = 'Today';
  static const fieldLabel = "Today's page";
  static const fieldHint = 'Write whatever you would like to keep.';
  static const save = 'Save';
  static const saved = 'Saved on this device.';
  static const saveFailed =
      'That could not be saved on this device. Your words are still here — '
      'please try again.';
  static const previous = 'Previous journal entry';
  static const next = 'Next journal entry';
  static const contents = 'Contents';
  static const backToToday = 'Back to today';
  static const readOnly = 'A past page. It can be read, but not changed.';
  static const remove = 'Remove this page';
  static const removeTitle = 'Remove this page?';
  static const removeBody =
      'The words on this page will be removed from this device. This cannot '
      'be undone.';
  static const removeYes = 'Remove';
  static const removeNo = 'Keep';
  static const removeFailed =
      'That page could not be removed. Please try again.';
  static const contentsEmpty =
      'No pages yet. A page appears here once you write something on it.';
  static const private =
      'Kept only on this device. Nothing written here is shared, sent '
      'anywhere, or used by any other part of the Almanac.';
  static const midnight =
      'This page is still the day you began it on. Saving keeps it there; '
      'the new day\'s page opens once you leave this one.';

  /// "Saturday 26 September 2026".
  static String longDate(CalendarDate date) =>
      '${formatDate(date)} ${date.year}';

  /// "Waxing Gibbous · 83% illuminated".
  static String moon(JournalContext context) =>
      '${context.moonPhase} · ${context.illuminatedPercent}% illuminated';

  /// "Maramataka: Ōuenuku (estimated)".
  static String maramataka(JournalContext context) =>
      'Maramataka: ${context.maramatakaName} (estimated)';

  /// A saved page as a screen reader hears it in the contents.
  static String spokenRow(JournalEntry entry) => [
    longDate(entry.date),
    moon(entry.context),
    ?entry.context.festivalName,
  ].join('. ');

  /// A past page's header, as a screen reader hears it: the date, that
  /// it cannot be changed, and what surrounded the day.
  static String spokenReadOnly(JournalEntry entry) => [
    'Journal page for ${longDate(entry.date)}',
    'Read only',
    moon(entry.context),
    entry.context.season,
    ?entry.context.festivalName,
    if (entry.context.maramatakaName != null) maramataka(entry.context),
  ].join('. ');

  /// The writing field, as a screen reader hears it.
  static String spokenField(CalendarDate date) =>
      'Journal entry for ${longDate(date)}';
}
