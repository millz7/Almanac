import 'package:flutter/foundation.dart';

import 'geo_location.dart';

/// One modelled sea-level reading, at an instant.
///
/// The raw material the app derives everything else from — a whole tide
/// curve is a list of these, never shown to the user as numbers.
@immutable
class TideSample {
  const TideSample({required this.time, required this.heightMetres});

  /// UTC instant.
  final DateTime time;

  /// Metres above the modelled mean sea level — the provider's datum,
  /// not a harbour chart datum. Kept only to derive extrema and
  /// direction; never displayed as a number.
  final double heightMetres;

  @override
  String toString() => 'TideSample($time, ${heightMetres.toStringAsFixed(2)}m)';
}

/// A high or a low.
enum TideExtremeType { high, low }

/// One turning point in the tide curve.
@immutable
class TideExtreme {
  const TideExtreme({
    required this.type,
    required this.time,
    required this.heightMetres,
  });

  final TideExtremeType type;

  /// UTC instant.
  final DateTime time;

  final double heightMetres;

  @override
  String toString() =>
      'TideExtreme(${type.name}, $time, ${heightMetres.toStringAsFixed(2)}m)';
}

/// Where the tide is going, right now.
enum TideDirection {
  rising,
  falling,

  /// Close enough to a high that "rising" or "falling" would overstate
  /// how much is actually changing — see `tideDirectionAt`.
  nearHigh,

  /// The low equivalent of [nearHigh].
  nearLow,

  /// Too little curve around this instant to say — an edge of the
  /// fetched window, or fewer than two samples.
  unknown,
}

/// Everything the Almanac keeps from one tide fetch.
///
/// **Mapped once, kept small.** [samples] is only the fetched window
/// (see `OpenMeteoMarineTideService` for its length) — never a growing
/// history — and [extrema] is derived from it once, not recomputed on
/// every read. Direction and the next high/low are deliberately *not*
/// stored here: they depend on "now", which can move on while a cached
/// snapshot is still being shown, so they are read with `tideDirectionAt`
/// and `nextTideExtreme` at display time instead of going stale inside
/// the snapshot.
@immutable
class TideSnapshot {
  const TideSnapshot({
    required this.location,
    required this.obtainedAt,
    required this.samples,
    required this.extrema,
  });

  /// The (rounded, low-precision) coordinates this curve was fetched
  /// for — see `OpenMeteoMarineTideService` for the exact rounding.
  final GeoLocation location;

  /// When the fetch completed. Used only to decide staleness — never
  /// shown to the user, and never persisted between launches.
  final DateTime obtainedAt;

  /// The fetched window, in order. See the service for exactly how much
  /// of the curve this covers.
  final List<TideSample> samples;

  /// Every high and low found in [samples], in order — see
  /// `extractTideExtrema` for how these are derived.
  final List<TideExtreme> extrema;

  /// Whether this snapshot is older than [maxAge].
  bool isStaleAt(DateTime now, Duration maxAge) =>
      now.toUtc().difference(obtainedAt.toUtc()) > maxAge;

  @override
  String toString() =>
      'TideSnapshot(${samples.length} samples, ${extrema.length} extrema, '
      'obtained $obtainedAt)';
}

/// Everything the app can know about the tide at the shared location,
/// right now.
///
/// The same shape as `LocationState`: a sealed hierarchy rather than a
/// scatter of booleans, so exactly one of these is true at a time and a
/// `switch` over them is checked by the compiler. This is deliberately
/// **not** collapsed into a single nullable snapshot the way weather is
/// — a tide reading has more than one honest reason to be missing, and
/// the four read differently: no position to ask about, a position the
/// marine model has nothing for, a provider that could not be reached,
/// and a real answer.
@immutable
sealed class TideState {
  const TideState();
}

/// No location is shared, so no request has been made at all.
final class TideLocationRequired extends TideState {
  const TideLocationRequired();
}

/// A position is known, but the marine model has no usable data for
/// it — see [TideFetchNoData] in `tide_service.dart`. Well inland is the
/// ordinary reason; the app never guesses a coast to work around it.
final class TideUnavailableForLocation extends TideState {
  const TideUnavailableForLocation();
}

/// The provider could not be reached, or its response could not be
/// used, and there was no still-fresh cached reading for roughly the
/// same place to fall back on.
final class TideProviderUnavailable extends TideState {
  const TideProviderUnavailable();
}

/// A real tide curve is available.
final class TideAvailable extends TideState {
  const TideAvailable(this.snapshot);

  final TideSnapshot snapshot;
}

/// Thrown by a [TideService] on a network failure, a non-200 response, or
/// a response that cannot be parsed. Always caught at the seam that calls
/// the service — see `TideController` — so the app is never left without
/// a usable state to show.
class TideServiceFailure implements Exception {
  const TideServiceFailure(this.message);

  final String message;

  @override
  String toString() => 'TideServiceFailure: $message';
}
