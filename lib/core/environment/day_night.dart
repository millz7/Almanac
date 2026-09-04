import 'package:flutter/foundation.dart';

import 'local_time_zone.dart';
import 'solar_service.dart';

/// Where the day currently is, relative to the sun.
enum DayPhase {
  night('Night'),
  dawn('Dawn'),
  day('Day'),
  dusk('Dusk');

  const DayPhase(this.label);

  final String label;
}

/// How much the app really knows about the state it is reporting.
enum DayNightAccuracy {
  /// Derived from real sunrise/sunset for the user's coordinates.
  fromSolarEvents,

  /// Estimated from the local clock because no position has been shared.
  /// Good enough to theme by; never good enough to present as sunrise.
  estimatedWithoutLocation,
}

/// How long the palette spends easing between night and day around each
/// solar crossing. Centred on sunrise/sunset, so the halfway point of the
/// blend is the moment the sun reaches the horizon.
const kTwilightWindow = Duration(minutes: 45);

/// The nominal daylight window used only when the app has no coordinates.
///
/// A rough global average, not a claim about anywhere in particular. It
/// exists so that someone who declines location still sees a night theme
/// at night; the resulting state is flagged
/// [DayNightAccuracy.estimatedWithoutLocation] and no sunrise time is
/// ever shown from it.
const kNominalSunriseLocalTime = Duration(hours: 7);
const kNominalSunsetLocalTime = Duration(hours: 19);

/// The current day/night state.
///
/// [daylight] is the important part for theming: rather than a hard
/// day/night switch it is a continuous 0–1 value, which lets the theme
/// interpolate smoothly through dawn and dusk.
@immutable
class DayNightState {
  const DayNightState({
    required this.phase,
    required this.daylight,
    this.accuracy = DayNightAccuracy.fromSolarEvents,
    this.nextChangeAt,
  });

  final DayPhase phase;

  /// 0.0 at full night, 1.0 in full daylight, in between during twilight.
  final double daylight;

  /// Whether this came from real solar events or from an estimate.
  final DayNightAccuracy accuracy;

  /// When the phase next changes, if that is known from today's events.
  /// Null after sunset, and on days when the sun neither rises nor sets.
  final DateTime? nextChangeAt;

  /// True from the midpoint of dawn to the midpoint of dusk.
  bool get isDaytime => daylight >= 0.5;

  /// True while easing between night and day in either direction.
  bool get isTransitioning => phase == DayPhase.dawn || phase == DayPhase.dusk;

  @override
  String toString() =>
      'DayNightState(${phase.label}, daylight: '
      '${daylight.toStringAsFixed(2)}, ${accuracy.name})';
}

/// Works out the day/night state at [instant].
///
/// The single day/night calculation in the app. It covers three cases,
/// all of which end up producing the same continuous [DayNightState.daylight]
/// value so the theme has one thing to follow:
///
/// 1. An ordinary day — eased around the real sunrise and sunset.
/// 2. A polar day or night — pinned to full daylight or full night.
/// 3. No coordinates — estimated from the local clock and flagged as such.
///
/// Deliberately a pure function of its inputs, with no clock reads, so it
/// is trivially testable.
DayNightState resolveDayNight({
  required DateTime instant,
  required SolarEvents events,
  LocalTimeZone? timeZone,
  Duration twilight = kTwilightWindow,
}) {
  // Inside the polar circles the sun may not cross the horizon at all.
  switch (events.kind) {
    case SolarDayKind.sunNeverSets:
      return const DayNightState(phase: DayPhase.day, daylight: 1);
    case SolarDayKind.sunNeverRises:
      return const DayNightState(phase: DayPhase.night, daylight: 0);
    case SolarDayKind.risesAndSets:
      break;
  }

  final sunrise = events.sunrise;
  final sunset = events.sunset;

  if (sunrise == null || sunset == null) {
    return _estimateFromClock(
      instant: instant,
      timeZone: timeZone,
      twilight: twilight,
    );
  }

  return _resolveAround(
    instant: instant,
    sunrise: sunrise,
    sunset: sunset,
    twilight: twilight,
    accuracy: DayNightAccuracy.fromSolarEvents,
  );
}

/// How far through the daylight hours [instant] has got: 0.0 at sunrise,
/// 1.0 at sunset.
///
/// This is **not** [DayNightState.daylight], and the two must not be
/// confused. `daylight` is the twilight blend that drives the palette —
/// it reaches 1.0 shortly after sunrise and stays there until dusk, which
/// is exactly what a colour scheme wants and exactly what a drawing of
/// the sun's position does not. This is the position through the day, so
/// something drawing the sun on its arc has a value that actually moves
/// between breakfast and teatime.
///
/// Null whenever there is no arc to trace: before sunrise, after sunset,
/// inside the polar circles on a day the sun does not cross the horizon,
/// and when no position has been shared so the times are unknown. Callers
/// must handle null rather than substituting a value — a sun drawn at a
/// made-up height is a made-up fact.
double? solarDayProgress({
  required DateTime instant,
  required SolarEvents events,
}) {
  final sunrise = events.sunrise;
  final sunset = events.sunset;
  if (sunrise == null || sunset == null) return null;

  final now = instant.toUtc();
  if (now.isBefore(sunrise) || now.isAfter(sunset)) return null;

  final span = sunset.difference(sunrise).inMicroseconds;
  if (span <= 0) return null;
  return (now.difference(sunrise).inMicroseconds / span).clamp(0.0, 1.0);
}

/// The shared easing logic, used for both real and estimated events.
DayNightState _resolveAround({
  required DateTime instant,
  required DateTime sunrise,
  required DateTime sunset,
  required Duration twilight,
  required DayNightAccuracy accuracy,
}) {
  final now = instant.toUtc();
  final half = twilight ~/ 2;

  final dawnStart = sunrise.subtract(half);
  final dawnEnd = sunrise.add(half);
  final duskStart = sunset.subtract(half);
  final duskEnd = sunset.add(half);

  if (now.isBefore(dawnStart)) {
    return DayNightState(
      phase: DayPhase.night,
      daylight: 0,
      accuracy: accuracy,
      nextChangeAt: dawnStart,
    );
  }
  if (now.isBefore(dawnEnd)) {
    return DayNightState(
      phase: DayPhase.dawn,
      daylight: _progress(now, dawnStart, dawnEnd),
      accuracy: accuracy,
      nextChangeAt: dawnEnd,
    );
  }
  if (now.isBefore(duskStart)) {
    return DayNightState(
      phase: DayPhase.day,
      daylight: 1,
      accuracy: accuracy,
      nextChangeAt: duskStart,
    );
  }
  if (now.isBefore(duskEnd)) {
    return DayNightState(
      phase: DayPhase.dusk,
      daylight: 1 - _progress(now, duskStart, duskEnd),
      accuracy: accuracy,
      nextChangeAt: duskEnd,
    );
  }
  // After dusk. The next change is tomorrow's dawn, which needs
  // tomorrow's solar events, so it is left for the caller to schedule.
  return DayNightState(phase: DayPhase.night, daylight: 0, accuracy: accuracy);
}

/// Estimates day/night from the local clock, for when the app has no
/// coordinates to calculate real solar events from.
DayNightState _estimateFromClock({
  required DateTime instant,
  required LocalTimeZone? timeZone,
  required Duration twilight,
}) {
  // With neither coordinates nor a time zone there is nothing to go on;
  // daylight is the friendlier of the two guesses for a first frame.
  if (timeZone == null) {
    return const DayNightState(
      phase: DayPhase.day,
      daylight: 1,
      accuracy: DayNightAccuracy.estimatedWithoutLocation,
    );
  }

  final midnight = timeZone.midnightOf(instant);
  return _resolveAround(
    instant: instant,
    sunrise: midnight.add(kNominalSunriseLocalTime),
    sunset: midnight.add(kNominalSunsetLocalTime),
    twilight: twilight,
    accuracy: DayNightAccuracy.estimatedWithoutLocation,
  );
}

/// How far [now] has travelled through the window [start]–[end], as 0–1.
double _progress(DateTime now, DateTime start, DateTime end) {
  final span = end.difference(start).inMicroseconds;
  if (span <= 0) return 1;
  final elapsed = now.difference(start).inMicroseconds;
  return (elapsed / span).clamp(0.0, 1.0);
}
