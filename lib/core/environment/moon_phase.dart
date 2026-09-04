import 'package:flutter/foundation.dart';

/// The eight moon phases in the traditional cycle.
///
/// The cycle is divided into eight equal parts, each spanning 45° of the
/// moon's elongation from the sun — about 3.7 days. So "Full Moon" means
/// "in the full-moon eighth of the cycle" rather than "exactly full to
/// the minute"; [MoonPhaseState.illuminatedFraction] is there when a
/// finer answer is wanted.
enum MoonPhase {
  newMoon('New Moon'),
  waxingCrescent('Waxing Crescent'),
  firstQuarter('First Quarter'),
  waxingGibbous('Waxing Gibbous'),
  fullMoon('Full Moon'),
  waningGibbous('Waning Gibbous'),
  lastQuarter('Last Quarter'),
  waningCrescent('Waning Crescent');

  const MoonPhase(this.label);

  final String label;

  /// Whether the lit part is growing. Waxing runs from new to full.
  bool get isWaxing => switch (this) {
    MoonPhase.waxingCrescent ||
    MoonPhase.firstQuarter ||
    MoonPhase.waxingGibbous => true,
    MoonPhase.newMoon ||
    MoonPhase.fullMoon ||
    MoonPhase.waningGibbous ||
    MoonPhase.lastQuarter ||
    MoonPhase.waningCrescent => false,
  };
}

/// Where the moon is in its cycle at one moment.
@immutable
class MoonPhaseState {
  const MoonPhaseState({
    required this.phase,
    required this.elongationDegrees,
    required this.illuminatedFraction,
  });

  final MoonPhase phase;

  /// How far the moon has moved away from the sun, 0–360°. 0 is new,
  /// 180 is full. This is what the phase and the illumination are both
  /// derived from.
  final double elongationDegrees;

  /// How much of the moon's disc is lit, 0.0–1.0. Used for drawing the
  /// moon and for saying something more precise than the phase name.
  final double illuminatedFraction;

  /// Rough age of the moon in days since the last new moon. Useful for
  /// display; not precise enough to schedule anything by.
  double get ageInDays => elongationDegrees / 360 * 29.530588861;

  /// Illumination as a whole percentage, for display.
  int get illuminatedPercent => (illuminatedFraction * 100).round();

  @override
  String toString() =>
      'MoonPhaseState(${phase.label}, $illuminatedPercent% lit, '
      'elongation ${elongationDegrees.toStringAsFixed(1)}°)';
}
