import 'package:flutter/foundation.dart';

import 'day_night.dart';
import 'geo_location.dart';
import 'local_time_zone.dart';
import 'moon_phase.dart';
import 'season.dart';
import 'solar_service.dart';

/// Where the hemisphere the app is using actually came from.
///
/// Kept alongside the hemisphere itself so the app can tell the
/// difference between "the user told us" and "we worked it out", without
/// either one quietly overwriting the other.
enum HemisphereSource {
  /// Derived from a real latitude. Preferred when available.
  derivedFromLocation,

  /// Chosen by the user during onboarding, or later in settings. Used
  /// whenever there is no precise location — which is the normal case for
  /// anyone who declines location.
  userSelected,

  /// Neither is known: the app has to assume something to render its
  /// first frame. Only reachable before onboarding has been completed.
  technicalFallback,
}

/// The hemisphere the app is using, and why.
@immutable
class ResolvedHemisphere {
  const ResolvedHemisphere({
    required this.hemisphere,
    required this.source,
    this.userSelected,
  });

  /// The hemisphere used for environmental calculations.
  final Hemisphere hemisphere;

  final HemisphereSource source;

  /// What the user chose, if they have chosen. Carried alongside so the
  /// two are never confused and neither overwrites the other.
  final Hemisphere? userSelected;

  /// True when a real latitude disagrees with what the user chose.
  ///
  /// Nothing acts on this yet by design — the location-derived value wins
  /// for calculations and the preference is left alone — but it is
  /// surfaced so a future screen can explain the difference instead of
  /// the app silently contradicting the user.
  bool get disagreesWithPreference =>
      source == HemisphereSource.derivedFromLocation &&
      userSelected != null &&
      userSelected != hemisphere;

  @override
  bool operator ==(Object other) =>
      other is ResolvedHemisphere &&
      other.hemisphere == hemisphere &&
      other.source == source &&
      other.userSelected == userSelected;

  @override
  int get hashCode => Object.hash(hemisphere, source, userSelected);

  @override
  String toString() => 'ResolvedHemisphere(${hemisphere.name}, ${source.name})';
}

/// Everything the app knows about the natural world around the user right
/// now: which hemisphere they are in, what season it is there, and where
/// the day has got to.
///
/// This is the single source of truth the theme system — and later,
/// feature screens — read from. Nothing recomputes seasons or day/night
/// on its own.
///
/// Note what is optional and what is not. [hemisphere], [timeZone],
/// [season] and [moon] are always known, so those always work: the season
/// needs only a date and a hemisphere, and the moon's phase is the same
/// for everybody on Earth at a given moment. [location] is null unless
/// the user has actually shared their position, and [solarEvents] carries
/// no times without one — features that genuinely need coordinates must
/// check rather than assume.
@immutable
class NaturalEnvironment {
  const NaturalEnvironment({
    required this.resolvedAt,
    required this.hemisphere,
    required this.hemisphereSource,
    required this.timeZone,
    required this.season,
    required this.dayNight,
    required this.solarEvents,
    required this.moon,
    this.location,
  });

  /// The instant all of this was resolved for.
  ///
  /// Carried so screens read the same "now" the season and day/night were
  /// worked out from, instead of each one calling the clock again and
  /// disagreeing with the others by a few milliseconds — or, worse,
  /// ignoring the clock the tests injected.
  final DateTime resolvedAt;

  final Hemisphere hemisphere;
  final HemisphereSource hemisphereSource;
  final LocalTimeZone timeZone;
  final SeasonState season;
  final DayNightState dayNight;

  /// Today's sunrise and sunset, as absolute instants. Reports no times
  /// when there is no position to calculate from, and inside the polar
  /// circles on days the sun does not cross the horizon.
  final SolarEvents solarEvents;

  /// Where the moon is in its cycle.
  final MoonPhaseState moon;

  /// The user's precise position, or null if they have not shared it.
  /// Never a stand-in value.
  final GeoLocation? location;

  /// Whether features that require coordinates can run.
  bool get hasPreciseLocation => location != null;

  /// How far through the daylight hours it is, 0–1, or null when there is
  /// no arc to trace. See [solarDayProgress] for why this is a different
  /// quantity from [DayNightState.daylight].
  double? get dayProgress =>
      solarDayProgress(instant: resolvedAt, events: solarEvents);

  @override
  String toString() =>
      'NaturalEnvironment(${hemisphere.name} via ${hemisphereSource.name}, '
      '$season, $dayNight, $solarEvents, $moon, '
      'location: ${location ?? 'not shared'})';
}
