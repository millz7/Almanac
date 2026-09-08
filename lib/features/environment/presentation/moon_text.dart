import '../../../core/context/almanac_context.dart';
import '../domain/moon_reflection.dart';

/// Everything the Moon page says.
///
/// Gathered in one file like the rest of the app's copy, with one line it
/// must not cross: nothing here claims the moon does anything to
/// anybody. `moon_content_test.dart` reads every string in this file and
/// every line of [MoonReflections].
abstract final class MoonText {
  static const title = 'The Moon';
  static const back = 'Back to the day';

  /// The heading over the reflective half of the page.
  static const forThisMoon = 'For this moon';

  static const practices = 'You might';

  /// Said once, quietly, under the reflective passage. Not a disclaimer
  /// repeated beside every line — one honest sentence about what kind of
  /// writing this is.
  static const framing =
      'Lunar reflection is a spiritual and cultural practice, not a '
      'physical effect. The moon lights the sky; what you do with the '
      'month is yours.';

  /// The one doorway out of the page, when Meditation is part of the
  /// user's Almanac.
  static const tryAMeditation = 'Try a meditation';

  /// What a doorway to [destination] says, or null where the Moon has no
  /// pathway there yet. A switch rather than a fallback derived from the
  /// feature's name, so a new doorway has to be given real words.
  static String? doorwayLabel(FeatureId destination) => switch (destination) {
    FeatureId.meditation => tryAMeditation,
    _ => null,
  };

  /// "34% illuminated".
  static String illumination(int percent) => '$percent% illuminated';

  /// "Waxing" or "Waning" — which way the light is going.
  static String direction(MoonPhase phase) =>
      phase.isWaxing ? 'Waxing' : 'Waning';

  /// "Waxing crescent. 34 percent illuminated. Waxing." — the factual
  /// layer as a screen reader hears it, in one node rather than three.
  static String spokenFacts(MoonPhaseState moon) =>
      '${moon.phase.label}. ${moon.illuminatedPercent} percent '
      'illuminated. ${direction(moon.phase)}.';

  /// Every fixed string here, for the content test to read.
  static List<String> get everythingSaid => [
    title,
    back,
    forThisMoon,
    practices,
    framing,
    tryAMeditation,
    illumination(34),
    for (final phase in MoonPhase.values) direction(phase),
  ];
}
