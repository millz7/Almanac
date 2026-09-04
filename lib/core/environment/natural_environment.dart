import 'package:flutter/foundation.dart';

import 'day_night.dart';
import 'geo_location.dart';
import 'local_time_zone.dart';
import 'season.dart';

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
/// Note what is optional and what is not. [hemisphere] and [timeZone] are
/// always known, so seasons always work. [location] is null unless the
/// user has actually shared their position, and features that genuinely
/// need coordinates must check for it rather than assume one.
@immutable
class NaturalEnvironment {
  const NaturalEnvironment({
    required this.hemisphere,
    required this.hemisphereSource,
    required this.timeZone,
    required this.season,
    required this.dayNight,
    this.location,
  });

  final Hemisphere hemisphere;
  final HemisphereSource hemisphereSource;
  final LocalTimeZone timeZone;
  final SeasonState season;
  final DayNightState dayNight;

  /// The user's precise position, or null if they have not shared it.
  /// Never a stand-in value.
  final GeoLocation? location;

  /// Whether features that require coordinates can run.
  bool get hasPreciseLocation => location != null;

  @override
  String toString() =>
      'NaturalEnvironment(${hemisphere.name} via ${hemisphereSource.name}, '
      '$season, $dayNight, location: ${location ?? 'not shared'})';
}
