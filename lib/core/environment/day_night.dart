import 'package:flutter/foundation.dart';

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

/// How long the palette spends easing between night and day around each
/// solar crossing. Centred on sunrise/sunset, so the halfway point of the
/// blend is the moment the sun reaches the horizon.
const kTwilightWindow = Duration(minutes: 45);

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
    this.nextChangeAt,
  });

  final DayPhase phase;

  /// 0.0 at full night, 1.0 in full daylight, in between during twilight.
  final double daylight;

  /// When the phase next changes, if that is known from today's events.
  /// Null after sunset, when the next change belongs to tomorrow.
  final DateTime? nextChangeAt;

  /// True from the midpoint of dawn to the midpoint of dusk.
  bool get isDaytime => daylight >= 0.5;

  /// True while easing between night and day in either direction.
  bool get isTransitioning => phase == DayPhase.dawn || phase == DayPhase.dusk;

  @override
  String toString() =>
      'DayNightState(${phase.label}, daylight: '
      '${daylight.toStringAsFixed(2)})';
}

/// Works out the day/night state at [instant] from real solar events.
///
/// Deliberately a pure function of its inputs — no clock reads, no
/// hard-coded hours — so it is trivially testable and works the same
/// whether the events came from a placeholder or from real astronomical
/// data later on.
DayNightState resolveDayNight({
  required DateTime instant,
  required SolarEvents events,
  Duration twilight = kTwilightWindow,
}) {
  final now = instant.toUtc();
  final half = twilight ~/ 2;

  final dawnStart = events.sunrise.subtract(half);
  final dawnEnd = events.sunrise.add(half);
  final duskStart = events.sunset.subtract(half);
  final duskEnd = events.sunset.add(half);

  if (now.isBefore(dawnStart)) {
    return DayNightState(
      phase: DayPhase.night,
      daylight: 0,
      nextChangeAt: dawnStart,
    );
  }
  if (now.isBefore(dawnEnd)) {
    return DayNightState(
      phase: DayPhase.dawn,
      daylight: _progress(now, dawnStart, dawnEnd),
      nextChangeAt: dawnEnd,
    );
  }
  if (now.isBefore(duskStart)) {
    return DayNightState(
      phase: DayPhase.day,
      daylight: 1,
      nextChangeAt: duskStart,
    );
  }
  if (now.isBefore(duskEnd)) {
    return DayNightState(
      phase: DayPhase.dusk,
      daylight: 1 - _progress(now, duskStart, duskEnd),
      nextChangeAt: duskEnd,
    );
  }
  // After dusk. The next change is tomorrow's dawn, which needs tomorrow's
  // solar events, so it is left for the caller to schedule.
  return const DayNightState(phase: DayPhase.night, daylight: 0);
}

/// How far [now] has travelled through the window [start]–[end], as 0–1.
double _progress(DateTime now, DateTime start, DateTime end) {
  final span = end.difference(start).inMicroseconds;
  if (span <= 0) return 1;
  final elapsed = now.difference(start).inMicroseconds;
  return (elapsed / span).clamp(0.0, 1.0);
}
