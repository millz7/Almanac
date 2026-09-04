import 'package:flutter/foundation.dart';

import 'day_night.dart';
import 'geo_location.dart';
import 'season.dart';

/// Everything the app knows about the natural world around the user right
/// now: where they are, what season it is there, and where the day is.
///
/// This is the single source of truth that the theme system — and later,
/// feature screens — read from. Nothing recomputes seasons or day/night on
/// its own.
@immutable
class NaturalEnvironment {
  const NaturalEnvironment({
    required this.location,
    required this.season,
    required this.dayNight,
  });

  final GeoLocation location;
  final SeasonState season;
  final DayNightState dayNight;

  @override
  String toString() => 'NaturalEnvironment($location, $season, $dayNight)';
}
