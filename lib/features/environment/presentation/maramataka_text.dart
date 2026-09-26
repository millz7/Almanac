import '../../../core/environment/maramataka.dart';
import '../../../core/environment/moon_phase.dart';

/// Everything the Moon page says about the Maramataka that is not the
/// published content itself. The content — names, notes, associations —
/// lives in [Maramataka], with its sources.
abstract final class MaramatakaText {
  static const heading = 'Maramataka';
  static const subheading = 'Māori lunar calendar';
  static const estimatedNight = 'Estimated Maramataka night';
  static const astronomicalRelationship = 'Astronomical relationship';
  static const aboutThisNight = 'About this night';
  static const associatedWith = 'Traditionally associated with';
  static const explore = 'Explore the lunar month';
  static const monthTitle = 'The lunar month';
  static const back = 'Back to the Moon';
  static const sources = 'Sources';
  static const background = 'Background';
  static const estimatedTonight = 'Estimated tonight';

  /// "Night 4 of 30".
  static String position(MaramatakaNight night) =>
      'Night ${night.order} of ${Maramataka.nights.length}';

  /// "The astronomical Moon: Waxing Crescent, 12% illuminated."
  static String relationship(MoonPhaseState moon) =>
      'The astronomical Moon: ${moon.phase.label}, '
      '${moon.illuminatedPercent}% illuminated.';

  /// "Moon about 2.9 to 3.9 days old."
  static String ageRange(MaramatakaNight night) {
    final range = Maramataka.ageRangeOf(night);
    return 'Moon about ${range.from.toStringAsFixed(1)} to '
        '${range.to.toStringAsFixed(1)} days old.';
  }

  /// "In the published reference used here: A good day for fishing."
  static String quoted(MaramatakaNight night) =>
      'In the published reference used here: ${night.about}';

  /// A night in the month, as a screen reader hears it.
  static String spokenNight(MaramatakaNight night, {required bool current}) => [
    position(night),
    night.name,
    if (current) estimatedTonight,
    ageRange(night),
    night.about,
    ...night.associations,
  ].join('. ');

  /// Every fixed string, for the content test to read.
  static List<String> get everythingSaid => [
    heading,
    subheading,
    estimatedNight,
    astronomicalRelationship,
    aboutThisNight,
    associatedWith,
    explore,
    monthTitle,
    back,
    sources,
    background,
    estimatedTonight,
    Maramataka.variationNote,
    Maramataka.estimateNote,
    ...Maramataka.background,
  ];
}
