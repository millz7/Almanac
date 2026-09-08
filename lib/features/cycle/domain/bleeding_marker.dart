import 'package:flutter/foundation.dart';

import 'bleeding_record.dart';

export 'bleeding_record.dart' show BleedingLevel, CycleDayRecord;

/// How a bleeding level is drawn — once, for everywhere it is drawn.
///
/// **One symbol language.** The wheel, the legend and the calendar all
/// read these numbers, so a mark cannot mean one thing in one widget and
/// something else in another. That was worth a value type rather than
/// three sets of magic numbers: a legend that disagrees with the chart it
/// explains is worse than no legend.
///
/// The three marks, and the exact relationships between them:
///
/// * **Spotting** — one small dot, *visibly smaller* than bleeding.
/// * **Bleeding** — one medium dot.
/// * **Heavy** — the **same** medium dot as bleeding, plus **one** thin
///   outer ring. Heavy differs from bleeding by the ring and by nothing
///   else, so the eye reads "more" rather than "different".
///
/// Sizes are fractions of the mark's own box, so the same spec draws a
/// legend swatch and a mark on a calendar day without a second set of
/// numbers.
@immutable
class BleedingMarkerSpec {
  const BleedingMarkerSpec({
    required this.level,
    required this.innerRadiusFraction,
    required this.outlineCount,
  });

  final BleedingLevel level;

  /// The filled dot's radius, as a fraction of half the box.
  final double innerRadiusFraction;

  /// How many thin outer rings the mark has. Exactly 0 or 1 today, and
  /// the count is the test's handle on "heavy has one extra outline".
  final int outlineCount;

  /// The gap between the dot and the ring, when there is one.
  static const outlineGapFraction = 0.26;

  /// The ring's stroke, as a fraction of half the box.
  static const outlineStrokeFraction = 0.09;

  /// The outer ring's radius, or null when the mark has no ring.
  double? get outlineRadiusFraction =>
      outlineCount == 0 ? null : innerRadiusFraction + outlineGapFraction;

  /// The whole mark's extent, so a widget can size itself to what it
  /// actually draws.
  double get extentFraction =>
      (outlineRadiusFraction ?? innerRadiusFraction) + outlineStrokeFraction;

  @override
  bool operator ==(Object other) =>
      other is BleedingMarkerSpec &&
      other.level == level &&
      other.innerRadiusFraction == innerRadiusFraction &&
      other.outlineCount == outlineCount;

  @override
  int get hashCode => Object.hash(level, innerRadiusFraction, outlineCount);

  @override
  String toString() => 'BleedingMarkerSpec(${level.name})';
}

/// The three marks. The only place their geometry is written down.
abstract final class BleedingMarkers {
  static const spotting = BleedingMarkerSpec(
    level: BleedingLevel.spotting,
    // Visibly smaller than bleeding: a bit over half its radius, so the
    // difference survives a small calendar cell.
    innerRadiusFraction: 0.30,
    outlineCount: 0,
  );

  static const bleeding = BleedingMarkerSpec(
    level: BleedingLevel.bleeding,
    innerRadiusFraction: 0.52,
    outlineCount: 0,
  );

  static const heavy = BleedingMarkerSpec(
    level: BleedingLevel.heavy,
    // Deliberately identical to bleeding. Heavy is bleeding plus a ring.
    innerRadiusFraction: 0.52,
    outlineCount: 1,
  );

  static const all = <BleedingMarkerSpec>[spotting, bleeding, heavy];

  /// The spec for a level. Total: every [BleedingLevel] has one.
  static BleedingMarkerSpec of(BleedingLevel level) =>
      all.firstWhere((spec) => spec.level == level);
}
