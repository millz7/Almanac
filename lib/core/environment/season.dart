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

  @override
  String toString() => 'SeasonState(${season.label}, $startedAt → $endsAt)';
}
