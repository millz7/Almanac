import 'package:flutter/foundation.dart';

import '../environment/day_night.dart';
import '../environment/geo_location.dart';
import '../environment/moon_phase.dart';
import '../environment/season.dart';
import '../time/calendar_date.dart';

/// The current moment, as every part of the Almanac sees it.
///
/// **One almanac, several views.** The Cookbook's season, the Garden's
/// date and the Moon page's phase are not three answers that happen to
/// agree — they are the same answers, resolved once. This is that shared
/// surface, and it holds only facts the app has already worked out
/// somewhere else.
///
/// **What it deliberately does not hold.** No coordinates. No history, no
/// snapshots, no previous values — it is derived on demand and thrown
/// away, so there is nothing here to leak, persist or send anywhere. And
/// no feature data: a consumer that needs a cycle phase or a garden asks
/// the feature that owns it, through that feature's own application
/// seam, rather than finding a copy here.
///
/// **Reading it is not the only way to use it.** Prefer the individual
/// providers — `currentSeasonProvider`, `todayProvider`,
/// `currentMoonProvider` — when a screen only needs one fact. A widget
/// that watches the whole moment rebuilds when any part of it moves.
@immutable
class AlmanacMoment {
  const AlmanacMoment({
    required this.today,
    required this.season,
    required this.hemisphere,
    required this.moon,
    this.daylight,
  });

  /// The local calendar day. The same `todayProvider` Cycle, Garden and
  /// the Nature Log read.
  final CalendarDate today;

  /// The astronomical season the user is in.
  final Season season;

  /// The hemisphere the app resolved — from a position where there is
  /// one, otherwise from the user's own choice.
  final Hemisphere hemisphere;

  /// The moon's phase and illumination right now.
  final MoonPhaseState moon;

  /// Where the day has got to, when sunrise and sunset have resolved.
  /// Null before that, and honest about it rather than guessing.
  final DayNightState? daylight;

  bool get hasDaylight => daylight != null;

  @override
  bool operator ==(Object other) =>
      other is AlmanacMoment &&
      other.today == today &&
      other.season == season &&
      other.hemisphere == hemisphere &&
      other.moon.phase == moon.phase &&
      other.moon.illuminatedPercent == moon.illuminatedPercent &&
      other.daylight?.phase == daylight?.phase;

  @override
  int get hashCode => Object.hash(
    today,
    season,
    hemisphere,
    moon.phase,
    moon.illuminatedPercent,
    daylight?.phase,
  );

  /// Says what the moment is, and nothing about the user.
  @override
  String toString() =>
      'AlmanacMoment(${today.iso}, ${season.label}, ${moon.phase.label})';
}
