import 'astronomy.dart';
import 'moon_phase.dart';

/// Calculates the moon's phase.
///
/// The phase is the angle between the moon and the sun as seen from
/// Earth — its *elongation*. At 0° the moon sits with the sun and is new;
/// at 180° it is opposite the sun and full. So the calculation is simply
/// the moon's apparent ecliptic longitude minus the sun's.
///
/// The sun's longitude comes from `astronomy.dart`, shared with the
/// sunrise calculation. The moon's comes from the largest periodic terms
/// of the lunar theory in Jean Meeus, *Astronomical Algorithms*, chapter
/// 47 — the same series a full implementation uses, truncated to the
/// terms that matter at this accuracy.
///
/// **Accuracy.** The truncated series gives the moon's longitude to
/// within roughly 0.02°. The moon's elongation changes by about 0.5° an
/// hour, so the phase is right to within a couple of minutes, and the
/// dates of new and full moon land within about that. That is far more
/// than an app which draws a small moon and names its phase requires.
///
/// **Limitations.** This is the *phase* only. It says nothing about
/// where the moon is in the sky, when it rises or sets, or whether it is
/// visible from a particular place — all of which need the observer's
/// position and are not implemented. Libration, parallax and the moon's
/// physical ephemeris are ignored.
abstract final class MoonCalculator {
  /// The moon's phase at [instant].
  static MoonPhaseState phaseAt(DateTime instant) {
    final t = julianCenturyOf(julianDayOf(instant));

    final elongation = wrap360(
      _moonApparentLongitude(t) - sunApparentLongitude(t),
    );

    return MoonPhaseState(
      phase: _phaseForElongation(elongation),
      elongationDegrees: elongation,
      // The illuminated fraction of a sphere lit from the side, which for
      // the moon's near-circular orbit is close enough to use the
      // elongation directly as the phase angle.
      illuminatedFraction: ((1 - cosDegrees(elongation)) / 2).clamp(0.0, 1.0),
    );
  }

  /// Splits the cycle into eight equal 45° parts, each centred on its
  /// named phase — so "New Moon" spans 22.5° either side of 0°.
  static MoonPhase _phaseForElongation(double elongation) {
    // Shifting by half an octant before dividing makes each phase
    // centred on its exact angle rather than starting there.
    final octant = (wrap360(elongation + 22.5) / 45).floor() % 8;

    return switch (octant) {
      0 => MoonPhase.newMoon,
      1 => MoonPhase.waxingCrescent,
      2 => MoonPhase.firstQuarter,
      3 => MoonPhase.waxingGibbous,
      4 => MoonPhase.fullMoon,
      5 => MoonPhase.waningGibbous,
      6 => MoonPhase.lastQuarter,
      _ => MoonPhase.waningCrescent,
    };
  }

  /// The moon's apparent ecliptic longitude, in degrees.
  static double _moonApparentLongitude(double t) {
    // Mean elements, Meeus 47.1–47.5.
    final meanLongitude = wrap360(
      218.3164477 +
          481267.88123421 * t -
          0.0015786 * t * t +
          t * t * t / 538841 -
          t * t * t * t / 65194000,
    );
    final meanElongation = wrap360(
      297.8501921 +
          445267.1114034 * t -
          0.0018819 * t * t +
          t * t * t / 545868 -
          t * t * t * t / 113065000,
    );
    final sunAnomaly = wrap360(
      357.5291092 + 35999.0502909 * t - 0.0001536 * t * t,
    );
    final moonAnomaly = wrap360(
      134.9633964 +
          477198.8675055 * t +
          0.0087414 * t * t +
          t * t * t / 69699 -
          t * t * t * t / 14712000,
    );
    final argumentOfLatitude = wrap360(
      93.2720950 +
          483202.0175233 * t -
          0.0036539 * t * t -
          t * t * t / 3526000 +
          t * t * t * t / 863310000,
    );

    // The largest terms of the longitude series, Meeus table 47.A, in
    // units of 1e-6 degrees. Transcribed in descending order of size;
    // the omitted terms are all below about 0.008°.
    final d = meanElongation;
    final m = sunAnomaly;
    final mp = moonAnomaly;
    final f = argumentOfLatitude;

    final sum =
        6288774 * sinDegrees(mp) +
        1274027 * sinDegrees(2 * d - mp) +
        658314 * sinDegrees(2 * d) +
        213618 * sinDegrees(2 * mp) +
        -185116 * sinDegrees(m) +
        -114332 * sinDegrees(2 * f) +
        58793 * sinDegrees(2 * d - 2 * mp) +
        57066 * sinDegrees(2 * d - m - mp) +
        53322 * sinDegrees(2 * d + mp) +
        45758 * sinDegrees(2 * d - m) +
        -40923 * sinDegrees(m - mp) +
        -34720 * sinDegrees(d) +
        -30383 * sinDegrees(m + mp) +
        15327 * sinDegrees(2 * d - 2 * f) +
        -12528 * sinDegrees(mp + 2 * f) +
        10980 * sinDegrees(mp - 2 * f) +
        10675 * sinDegrees(4 * d - mp) +
        10034 * sinDegrees(3 * mp) +
        8548 * sinDegrees(4 * d - 2 * mp) +
        -7888 * sinDegrees(2 * d + m - mp) +
        -6766 * sinDegrees(2 * d + m) +
        -5163 * sinDegrees(d - mp) +
        4987 * sinDegrees(d + m) +
        4036 * sinDegrees(2 * d - m + mp) +
        3994 * sinDegrees(2 * d + 2 * mp) +
        3861 * sinDegrees(4 * d) +
        3665 * sinDegrees(2 * d - 3 * mp);

    return wrap360(meanLongitude + sum / 1000000);
  }
}
