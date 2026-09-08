/// The words the Meditation screen uses that are worth reading in one
/// place — the ones with a number in them, and the one contextual
/// heading.
abstract final class MeditationText {
  /// The heading over the moon suggestion when Meditation was opened
  /// normally rather than through the Moon's doorway. Deliberately
  /// quieter than the intent's own heading: it mentions today, it does
  /// not announce it.
  static const forToday = 'For today';
}

const _numbers = [
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
  'eleven',
  'twelve',
  'thirteen',
  'fourteen',
  'fifteen',
  'sixteen',
  'seventeen',
  'eighteen',
  'nineteen',
  'twenty',
];

/// "four", "twelve". Falls back to digits above the range the session
/// length can reach, so this can never be the thing that breaks.
String spellNumber(int value) =>
    (value >= 0 && value < _numbers.length) ? _numbers[value] : '$value';

/// "Four quiet minutes." — the whole of what is said at the end.
///
/// Words rather than a figure: a number would read as a measurement, and
/// there is nothing here to measure.
String describeSessionLength(int minutes) {
  final spelled = spellNumber(minutes);
  final capitalised = spelled[0].toUpperCase() + spelled.substring(1);
  return '$capitalised quiet ${minutes == 1 ? 'minute' : 'minutes'}.';
}
