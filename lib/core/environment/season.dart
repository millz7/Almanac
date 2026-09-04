import 'package:flutter/foundation.dart';

/// The four seasons the app dresses itself in.
///
/// This is the season the *user* is experiencing, not a northern-hemisphere
/// default: it is always derived together with a [Hemisphere]. See
/// `season_service.dart`.
enum Season {
  spring('Spring'),
  summer('Summer'),
  autumn('Autumn'),
  winter('Winter');

  const Season(this.label);

  /// Human-readable name, for the developer preview and future UI.
  final String label;

  /// The season that follows this one.
  ///
  /// The cycle is the same in both hemispheres — spring always gives way
  /// to summer — because a [Season] here is already the season the user
  /// is experiencing, not a month of the year.
  Season get next => switch (this) {
    Season.spring => Season.summer,
    Season.summer => Season.autumn,
    Season.autumn => Season.winter,
    Season.winter => Season.spring,
  };
}

/// The current season plus the instants it runs between.
///
/// [endsAt] is what lets the app roll over to the next season on its own,
/// without polling: it can simply wake up at that moment.
@immutable
class SeasonState {
  const SeasonState({
    required this.season,
    required this.startedAt,
    required this.endsAt,
  });

  final Season season;

  /// UTC instant of the equinox/solstice that began this season.
  final DateTime startedAt;

  /// UTC instant of the equinox/solstice that ends it.
  final DateTime endsAt;

  /// How far through the season [instant] falls, 0.0 at its opening
  /// equinox or solstice and 1.0 at the next one.
  ///
  /// This is what lets the app say "early summer" rather than only
  /// "summer" — a sense of where in the season you are, taken from the
  /// real astronomical boundaries rather than from the calendar month.
  double fractionElapsedAt(DateTime instant) {
    final span = endsAt.difference(startedAt).inMicroseconds;
    if (span <= 0) return 0;
    final elapsed = instant.toUtc().difference(startedAt).inMicroseconds;
    return (elapsed / span).clamp(0.0, 1.0);
  }

  @override
  String toString() => 'SeasonState(${season.label}, $startedAt → $endsAt)';
}
