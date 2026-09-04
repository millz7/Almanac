import 'dart:math' as math;

/// What the sun does on a given day at a given place.
enum SolarDayKind {
  /// An ordinary day: the sun rises and sets.
  risesAndSets,

  /// Polar night — the sun stays below the horizon all day.
  sunNeverRises,

  /// Midnight sun — the sun stays above the horizon all day.
  sunNeverSets,
}

/// The result of a sunrise/sunset calculation for one local day.
///
/// [sunrise] and [sunset] are null unless [kind] is
/// [SolarDayKind.risesAndSets]. That is deliberate: inside the polar
/// circles there are days with no sunrise at all, and the app says so
/// rather than inventing a time.
class SolarTimes {
  const SolarTimes.risesAndSets({
    required DateTime this.sunrise,
    required DateTime this.sunset,
  }) : kind = SolarDayKind.risesAndSets;

  const SolarTimes.sunNeverRises()
    : kind = SolarDayKind.sunNeverRises,
      sunrise = null,
      sunset = null;

  const SolarTimes.sunNeverSets()
    : kind = SolarDayKind.sunNeverSets,
      sunrise = null,
      sunset = null;

  final SolarDayKind kind;

  /// UTC instant of sunrise, or null on a polar day.
  final DateTime? sunrise;

  /// UTC instant of sunset, or null on a polar day.
  final DateTime? sunset;

  @override
  String toString() => switch (kind) {
    SolarDayKind.risesAndSets => 'SolarTimes($sunrise → $sunset)',
    SolarDayKind.sunNeverRises => 'SolarTimes(sun never rises)',
    SolarDayKind.sunNeverSets => 'SolarTimes(sun never sets)',
  };
}

/// Calculates sunrise and sunset for a date and position.
///
/// Implements the algorithm published by NOAA's Global Monitoring
/// Laboratory (their Solar Calculator), which is the standard low-precision
/// solar-position method from Jean Meeus, *Astronomical Algorithms*,
/// chapters 25 and 15.
///
/// **Accuracy.** Within about a minute for latitudes below roughly 72°,
/// degrading closer to the poles where the sun crosses the horizon at a
/// very shallow angle and small errors in refraction translate into large
/// errors in time. That is comfortably good enough for an app that
/// changes its colours around sunset; it is not observatory-grade.
///
/// **Assumptions.**
/// * Sunrise and sunset are taken at a solar zenith of 90.833°, the
///   conventional value that allows for average atmospheric refraction
///   (about 34 arcminutes) and the sun's apparent radius (about 16
///   arcminutes). So these are the moments the sun's *upper edge* meets a
///   flat horizon.
/// * Sea level, and a flat horizon. Altitude and terrain are ignored;
///   a mountain range to the west will hide the sun before this says so.
/// * Longitude is positive east, matching `GeoLocation`.
/// * The equation of time and the sun's declination are evaluated once at
///   local solar noon and then refined once at the approximate event, as
///   NOAA's own calculator does.
///
/// **Edge cases.** Inside the polar circles the sun may not rise or set at
/// all; that is reported through [SolarDayKind] instead of a fabricated
/// time. Callers must handle it — see `resolveDayNight`.
abstract final class SolarCalculator {
  /// The solar zenith angle at which sunrise and sunset are defined.
  static const _sunriseZenithDegrees = 90.833;

  /// Sunrise and sunset for the calendar day [year]-[month]-[day] **as
  /// reckoned locally**, at the given position.
  ///
  /// The caller supplies the local date because "today" is a local idea;
  /// the results come back as absolute UTC instants.
  static SolarTimes forDate({
    required int year,
    required int month,
    required int day,
    required double latitude,
    required double longitude,
  }) {
    // Julian day at 00:00 UT on the requested date. The event times are
    // then found as offsets in minutes from that midnight.
    final julianDay = _julianDayOfMidnightUtc(year, month, day);

    final noonEstimate = _solarNoonMinutesUtc(julianDay, longitude);
    final declinationAtNoon = _sunDeclination(
      _julianCentury(julianDay + noonEstimate / _minutesPerDay),
    );

    final hourAngle = _sunriseHourAngle(latitude, declinationAtNoon);
    if (hourAngle == null) {
      // The sun never reaches the sunrise zenith today. Which side of the
      // horizon it stays on depends on whether the pole is tilted toward
      // or away from the sun.
      final sunIsUp = _sunIsAlwaysUp(latitude, declinationAtNoon);
      return sunIsUp
          ? const SolarTimes.sunNeverSets()
          : const SolarTimes.sunNeverRises();
    }

    final sunriseMinutes = _refineEvent(
      julianDay: julianDay,
      longitude: longitude,
      latitude: latitude,
      approximateMinutes: noonEstimate - 4 * hourAngle,
      isSunrise: true,
    );
    final sunsetMinutes = _refineEvent(
      julianDay: julianDay,
      longitude: longitude,
      latitude: latitude,
      approximateMinutes: noonEstimate + 4 * hourAngle,
      isSunrise: false,
    );

    if (sunriseMinutes == null || sunsetMinutes == null) {
      // The refinement pass disagreed with the first: the day is right on
      // the edge of a polar day or night. Fall back to the unrefined
      // answer rather than reporting nothing.
      final sunIsUp = _sunIsAlwaysUp(latitude, declinationAtNoon);
      return sunIsUp
          ? const SolarTimes.sunNeverSets()
          : const SolarTimes.sunNeverRises();
    }

    return SolarTimes.risesAndSets(
      sunrise: _instantAt(year, month, day, sunriseMinutes),
      sunset: _instantAt(year, month, day, sunsetMinutes),
    );
  }

  /// Recomputes an event's time using the sun's position at the event
  /// rather than at noon, which is what brings the result inside a minute.
  static double? _refineEvent({
    required double julianDay,
    required double longitude,
    required double latitude,
    required double approximateMinutes,
    required bool isSunrise,
  }) {
    final century = _julianCentury(
      julianDay + approximateMinutes / _minutesPerDay,
    );
    final declination = _sunDeclination(century);
    final hourAngle = _sunriseHourAngle(latitude, declination);
    if (hourAngle == null) return null;

    final noon = 720 - 4 * longitude - _equationOfTimeMinutes(century);
    return isSunrise ? noon - 4 * hourAngle : noon + 4 * hourAngle;
  }

  /// Minutes after 00:00 UTC at which the sun crosses the local meridian.
  ///
  /// At longitude 0 with no equation-of-time correction this is 720
  /// minutes — 12:00 UTC — as it should be.
  static double _solarNoonMinutesUtc(double julianDay, double longitude) {
    final century = _julianCentury(julianDay);
    return 720 - 4 * longitude - _equationOfTimeMinutes(century);
  }

  /// The hour angle, in degrees, between solar noon and sunrise.
  ///
  /// Null when the sun never reaches the sunrise zenith on this day,
  /// which is the polar-day/polar-night case.
  static double? _sunriseHourAngle(double latitude, double declination) {
    final latitudeRadians = _radians(latitude);
    final declinationRadians = _radians(declination);

    final cosHourAngle =
        math.cos(_radians(_sunriseZenithDegrees)) /
            (math.cos(latitudeRadians) * math.cos(declinationRadians)) -
        math.tan(latitudeRadians) * math.tan(declinationRadians);

    if (cosHourAngle > 1 || cosHourAngle < -1) return null;
    return _degrees(math.acos(cosHourAngle));
  }

  /// On a day with no sunrise or sunset, decides which it is: the sun is
  /// permanently up when the hemisphere's pole is tilted sunward, i.e.
  /// when latitude and declination share a sign.
  static bool _sunIsAlwaysUp(double latitude, double declination) =>
      (latitude >= 0) == (declination >= 0);

  // --- Solar position, following NOAA / Meeus ---------------------------

  /// Julian centuries since J2000.0.
  static double _julianCentury(double julianDay) =>
      (julianDay - 2451545.0) / 36525.0;

  /// Geometric mean longitude of the sun, in degrees.
  static double _geometricMeanLongitude(double t) =>
      _wrap360(280.46646 + t * (36000.76983 + t * 0.0003032));

  /// Geometric mean anomaly of the sun, in degrees.
  static double _geometricMeanAnomaly(double t) =>
      357.52911 + t * (35999.05029 - t * 0.0001537);

  /// Eccentricity of the Earth's orbit.
  static double _orbitEccentricity(double t) =>
      0.016708634 - t * (0.000042037 + t * 0.0000001267);

  /// The sun's equation of the centre, in degrees.
  static double _equationOfCentre(double t) {
    final m = _radians(_geometricMeanAnomaly(t));
    return math.sin(m) * (1.914602 - t * (0.004817 + t * 0.000014)) +
        math.sin(2 * m) * (0.019993 - t * 0.000101) +
        math.sin(3 * m) * 0.000289;
  }

  /// The sun's apparent longitude, in degrees, including the correction
  /// for nutation and aberration.
  static double _apparentLongitude(double t) {
    final trueLongitude = _geometricMeanLongitude(t) + _equationOfCentre(t);
    return trueLongitude -
        0.00569 -
        0.00478 * math.sin(_radians(125.04 - 1934.136 * t));
  }

  /// Obliquity of the ecliptic, corrected for nutation, in degrees.
  static double _obliquity(double t) {
    final seconds = 21.448 - t * (46.815 + t * (0.00059 - t * 0.001813));
    final mean = 23 + (26 + seconds / 60) / 60;
    return mean + 0.00256 * math.cos(_radians(125.04 - 1934.136 * t));
  }

  /// The sun's declination, in degrees.
  static double _sunDeclination(double t) {
    final sinDeclination =
        math.sin(_radians(_obliquity(t))) *
        math.sin(_radians(_apparentLongitude(t)));
    return _degrees(math.asin(sinDeclination));
  }

  /// The equation of time — apparent solar time minus mean solar time —
  /// in minutes.
  static double _equationOfTimeMinutes(double t) {
    final epsilon = _radians(_obliquity(t));
    final l0 = _radians(_geometricMeanLongitude(t));
    final e = _orbitEccentricity(t);
    final m = _radians(_geometricMeanAnomaly(t));

    final y = math.tan(epsilon / 2) * math.tan(epsilon / 2);

    final equation =
        y * math.sin(2 * l0) -
        2 * e * math.sin(m) +
        4 * e * y * math.sin(m) * math.cos(2 * l0) -
        0.5 * y * y * math.sin(4 * l0) -
        1.25 * e * e * math.sin(2 * m);

    return _degrees(equation) * 4;
  }

  // --- Calendar and angle helpers ---------------------------------------

  static const _minutesPerDay = 1440.0;

  /// Julian Day number at 00:00 UTC on the given calendar date.
  static double _julianDayOfMidnightUtc(int year, int month, int day) {
    final utcMidnight = DateTime.utc(year, month, day);
    return utcMidnight.millisecondsSinceEpoch / Duration.millisecondsPerDay +
        _unixEpochJulianDay;
  }

  /// Julian Day of the Unix epoch (1970-01-01 00:00 UTC).
  static const _unixEpochJulianDay = 2440587.5;

  /// The instant [minutesAfterUtcMidnight] after 00:00 UTC on the given
  /// date. Values outside 0–1440 are fine and roll into the neighbouring
  /// day, which happens routinely at high longitudes.
  static DateTime _instantAt(
    int year,
    int month,
    int day,
    double minutesAfterUtcMidnight,
  ) => DateTime.utc(
    year,
    month,
    day,
  ).add(Duration(milliseconds: (minutesAfterUtcMidnight * 60000).round()));

  static double _radians(double degrees) => degrees * math.pi / 180.0;

  static double _degrees(double radians) => radians * 180.0 / math.pi;

  static double _wrap360(double degrees) {
    final wrapped = degrees % 360;
    return wrapped < 0 ? wrapped + 360 : wrapped;
  }
}
