/// Shared astronomical primitives.
///
/// The sun's position is needed twice over — once to find sunrise and
/// sunset, and once to work out how far the moon has moved away from the
/// sun — so it lives here rather than being written out twice with two
/// chances to be wrong.
///
/// Angles are in degrees unless a name says otherwise, and times are
/// Julian days in Terrestrial Time. The difference between TT and UTC is
/// about 70 seconds at present, which is far below the accuracy any of
/// this is claimed to have, so it is deliberately ignored.
library;

import 'dart:math' as math;

/// Julian Day of the Unix epoch (1970-01-01 00:00 UTC).
const julianDayOfUnixEpoch = 2440587.5;

/// Julian Day of J2000.0 (2000-01-01 12:00 TT).
const julianDayOfJ2000 = 2451545.0;

/// Days in a Julian century.
const daysPerJulianCentury = 36525.0;

/// The mean length of a lunation — new moon to new moon — in days.
const meanSynodicMonth = 29.530588861;

double radians(double degrees) => degrees * math.pi / 180.0;

double degrees(double radians) => radians * 180.0 / math.pi;

/// Wraps an angle into 0–360.
double wrap360(double value) {
  final wrapped = value % 360;
  return wrapped < 0 ? wrapped + 360 : wrapped;
}

double sinDegrees(double angle) => math.sin(radians(angle));

double cosDegrees(double angle) => math.cos(radians(angle));

/// The Julian Day of an instant.
double julianDayOf(DateTime instant) =>
    instant.toUtc().millisecondsSinceEpoch / Duration.millisecondsPerDay +
    julianDayOfUnixEpoch;

/// The Julian Day at 00:00 UTC on a calendar date.
double julianDayOfMidnightUtc(int year, int month, int day) =>
    julianDayOf(DateTime.utc(year, month, day));

/// The instant a Julian Day refers to.
DateTime utcOfJulianDay(double julianDay) =>
    DateTime.fromMillisecondsSinceEpoch(
      ((julianDay - julianDayOfUnixEpoch) * Duration.millisecondsPerDay)
          .round(),
      isUtc: true,
    );

/// Julian centuries since J2000.0.
double julianCenturyOf(double julianDay) =>
    (julianDay - julianDayOfJ2000) / daysPerJulianCentury;

/// Geometric mean longitude of the sun, in degrees.
double sunMeanLongitude(double t) =>
    wrap360(280.46646 + t * (36000.76983 + t * 0.0003032));

/// Geometric mean anomaly of the sun, in degrees.
double sunMeanAnomaly(double t) =>
    357.52911 + t * (35999.05029 - t * 0.0001537);

/// Eccentricity of the Earth's orbit.
double earthOrbitEccentricity(double t) =>
    0.016708634 - t * (0.000042037 + t * 0.0000001267);

/// The sun's equation of the centre, in degrees.
double sunEquationOfCentre(double t) {
  final m = sunMeanAnomaly(t);
  return sinDegrees(m) * (1.914602 - t * (0.004817 + t * 0.000014)) +
      sinDegrees(2 * m) * (0.019993 - t * 0.000101) +
      sinDegrees(3 * m) * 0.000289;
}

/// The sun's apparent ecliptic longitude, in degrees, corrected for
/// nutation and aberration.
///
/// Accurate to roughly 0.01°, which is a little under a minute of the
/// sun's own motion.
double sunApparentLongitude(double t) {
  final trueLongitude = sunMeanLongitude(t) + sunEquationOfCentre(t);
  return trueLongitude - 0.00569 - 0.00478 * sinDegrees(125.04 - 1934.136 * t);
}

/// Obliquity of the ecliptic, corrected for nutation, in degrees.
double eclipticObliquity(double t) {
  final seconds = 21.448 - t * (46.815 + t * (0.00059 - t * 0.001813));
  final mean = 23 + (26 + seconds / 60) / 60;
  return mean + 0.00256 * cosDegrees(125.04 - 1934.136 * t);
}

/// The sun's declination, in degrees.
double sunDeclination(double t) => degrees(
  math.asin(
    sinDegrees(eclipticObliquity(t)) * sinDegrees(sunApparentLongitude(t)),
  ),
);

/// The equation of time — apparent solar time minus mean solar time — in
/// minutes.
double equationOfTimeMinutes(double t) {
  final epsilon = radians(eclipticObliquity(t));
  final l0 = sunMeanLongitude(t);
  final e = earthOrbitEccentricity(t);
  final m = sunMeanAnomaly(t);

  final y = math.tan(epsilon / 2) * math.tan(epsilon / 2);

  final equation =
      y * sinDegrees(2 * l0) -
      2 * e * sinDegrees(m) +
      4 * e * y * sinDegrees(m) * cosDegrees(2 * l0) -
      0.5 * y * y * sinDegrees(4 * l0) -
      1.25 * e * e * sinDegrees(2 * m);

  return degrees(equation) * 4;
}
