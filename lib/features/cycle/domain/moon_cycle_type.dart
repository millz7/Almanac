import '../../../core/environment/moon_phase.dart';

export '../../../core/environment/moon_phase.dart' show MoonPhase;

/// A reflective reading of which moon a period began under.
///
/// **What this is.** In some modern spiritual traditions the moon phase
/// a period begins under is given a name. That is a cultural practice,
/// and this is where the app implements it: the moon phase on the
/// recorded day 1, classified into one of four.
///
/// **What this is not.** Not a biological cycle type, not a diagnosis,
/// and not a description of a person. It is derived fresh from each
/// recorded period start, so somebody can be one this month and another
/// next month — which is ordinary, because the moon and a cycle run at
/// different lengths and drift past each other. Nothing about it is
/// persisted, and no type is better, healthier, more natural or more
/// spiritual than another. `cycle_content_test.dart` enforces the
/// absence of any ranking, and of any claim that one should aim for one.
enum MoonCycleType {
  white('White Moon cycle'),
  red('Red Moon cycle'),
  pink('Pink Moon cycle'),
  purple('Purple Moon cycle');

  const MoonCycleType(this.label);

  final String label;

  /// The moon a period began under, in the phase's own words.
  ///
  /// Uses the existing [MoonPhase] values exactly:
  ///
  /// * new moon → white
  /// * full moon → red
  /// * waxing crescent, first quarter, waxing gibbous → pink
  /// * waning gibbous, last quarter, waning crescent → purple
  static MoonCycleType forPhase(MoonPhase phase) => switch (phase) {
    MoonPhase.newMoon => MoonCycleType.white,
    MoonPhase.fullMoon => MoonCycleType.red,
    MoonPhase.waxingCrescent ||
    MoonPhase.firstQuarter ||
    MoonPhase.waxingGibbous => MoonCycleType.pink,
    MoonPhase.waningGibbous ||
    MoonPhase.lastQuarter ||
    MoonPhase.waningCrescent => MoonCycleType.purple,
  };

  /// The phases that produce this type, for the explanation and for the
  /// test that pins the classification both ways.
  List<MoonPhase> get phases => [
    for (final phase in MoonPhase.values)
      if (MoonCycleType.forPhase(phase) == this) phase,
  ];
}
