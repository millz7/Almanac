import 'dart:math' as math;

/// The four points that bound the astronomical seasons.
///
/// Named after the month they fall in rather than after a season, because
/// which season each one *starts* depends on the user's hemisphere.
enum SolarTerm {
  marchEquinox,
  juneSolstice,
  septemberEquinox,
  decemberSolstice,
}

/// Calculates the instant of an equinox or solstice.
///
/// Implements Jean Meeus, *Astronomical Algorithms* (2nd ed.), chapter 27:
/// a mean-time polynomial (table 27.B, valid for years 1000–3000) plus a
/// periodic correction (table 27.C). Accurate to roughly a minute, which is
/// far more than the app needs — but it means the season really does turn at
/// the astronomical moment rather than on the 1st of a month.
///
/// The result is a UTC instant. Strictly the algorithm yields Terrestrial
/// Dynamical Time, which currently runs about 70 seconds ahead of UTC; that
/// difference is immaterial for deciding which season a moment falls in, so
/// it is deliberately ignored.
DateTime solarTermInstant(int year, SolarTerm term) {
  final meanJde = _meanJde(year, term);
  final t = (meanJde - _j2000) / 36525.0;
  final w = _radians(35999.373 * t - 2.47);
  final deltaLambda = 1 + 0.0334 * math.cos(w) + 0.0007 * math.cos(2 * w);

  var periodicSum = 0.0;
  for (final row in _periodicTerms) {
    periodicSum += row.amplitude * math.cos(_radians(row.phase + row.rate * t));
  }

  final jde = meanJde + (0.00001 * periodicSum) / deltaLambda;
  return _julianDayToUtc(jde);
}

/// Julian Ephemeris Day of the *mean* equinox/solstice — Meeus table 27.B.
double _meanJde(int year, SolarTerm term) {
  final y = (year - 2000) / 1000.0;
  final y2 = y * y;
  final y3 = y2 * y;
  final y4 = y3 * y;

  return switch (term) {
    SolarTerm.marchEquinox =>
      2451623.80984 +
          365242.37404 * y +
          0.05169 * y2 -
          0.00411 * y3 -
          0.00057 * y4,
    SolarTerm.juneSolstice =>
      2451716.56767 +
          365241.62603 * y +
          0.00325 * y2 +
          0.00888 * y3 -
          0.00030 * y4,
    SolarTerm.septemberEquinox =>
      2451810.21715 +
          365242.01767 * y -
          0.11575 * y2 +
          0.00337 * y3 +
          0.00078 * y4,
    SolarTerm.decemberSolstice =>
      2451900.05952 +
          365242.74049 * y -
          0.06223 * y2 -
          0.00823 * y3 +
          0.00032 * y4,
  };
}

/// Julian Day of 2000-01-01 12:00 TT, the epoch the polynomials count from.
const _j2000 = 2451545.0;

/// Julian Day of the Unix epoch (1970-01-01 00:00 UTC).
const _unixEpochJulianDay = 2440587.5;

DateTime _julianDayToUtc(double julianDay) =>
    DateTime.fromMillisecondsSinceEpoch(
      ((julianDay - _unixEpochJulianDay) * Duration.millisecondsPerDay).round(),
      isUtc: true,
    );

double _radians(double degrees) => degrees * math.pi / 180.0;

/// One row of Meeus table 27.C. [phase] and [rate] are in degrees.
class _PeriodicTerm {
  const _PeriodicTerm(this.amplitude, this.phase, this.rate);
  final double amplitude;
  final double phase;
  final double rate;
}

/// Meeus table 27.C, transcribed verbatim. Do not tidy these numbers.
const _periodicTerms = <_PeriodicTerm>[
  _PeriodicTerm(485, 324.96, 1934.136),
  _PeriodicTerm(203, 337.23, 32964.467),
  _PeriodicTerm(199, 342.08, 20.186),
  _PeriodicTerm(182, 27.85, 445267.112),
  _PeriodicTerm(156, 73.14, 45036.886),
  _PeriodicTerm(136, 171.52, 22518.443),
  _PeriodicTerm(77, 222.54, 65928.934),
  _PeriodicTerm(74, 296.72, 3034.906),
  _PeriodicTerm(70, 243.58, 9037.513),
  _PeriodicTerm(58, 119.81, 33718.147),
  _PeriodicTerm(52, 297.17, 150.678),
  _PeriodicTerm(50, 21.02, 2281.226),
  _PeriodicTerm(45, 247.54, 29929.562),
  _PeriodicTerm(44, 325.15, 31555.956),
  _PeriodicTerm(29, 60.93, 4443.417),
  _PeriodicTerm(18, 155.12, 67555.328),
  _PeriodicTerm(17, 288.79, 4562.452),
  _PeriodicTerm(16, 198.04, 62894.029),
  _PeriodicTerm(14, 199.76, 31436.921),
  _PeriodicTerm(12, 95.39, 14577.848),
  _PeriodicTerm(12, 287.11, 31931.756),
  _PeriodicTerm(12, 320.81, 34777.259),
  _PeriodicTerm(9, 227.73, 1222.114),
  _PeriodicTerm(8, 15.45, 16859.074),
];
