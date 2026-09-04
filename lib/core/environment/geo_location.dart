import 'package:flutter/foundation.dart';

/// Which half of the world the user is in. Determines whether the June
/// solstice means summer or winter.
enum Hemisphere { northern, southern }

/// Where the app believes the user is.
///
/// The time zone is modelled as a plain [utcOffset] rather than an IANA
/// zone name. That is enough for everything the theme system needs — the
/// season boundaries are absolute instants (see `astronomical_seasons.dart`)
/// and sunrise/sunset are instants too, so the offset is only used to work
/// out the user's local calendar day. A full IANA time zone can replace
/// this later without changing any caller.
@immutable
class GeoLocation {
  const GeoLocation({
    required this.latitude,
    required this.longitude,
    required this.utcOffset,
    this.isFallback = false,
  });

  /// Degrees north (positive) or south (negative) of the equator.
  final double latitude;

  /// Degrees east (positive) or west (negative) of Greenwich.
  final double longitude;

  /// The offset from UTC currently in effect at this location.
  final Duration utcOffset;

  /// True when this is a stand-in rather than the user's real position, so
  /// the UI can eventually say "using a default location" instead of
  /// silently showing the wrong hemisphere's season.
  final bool isFallback;

  /// Locations exactly on the equator are treated as northern; the
  /// four-season model does not really describe the tropics anyway.
  Hemisphere get hemisphere =>
      latitude < 0 ? Hemisphere.southern : Hemisphere.northern;

  /// The user's wall-clock time for [instant].
  ///
  /// The result carries local field values (year/month/day/hour) but is
  /// flagged as UTC, because Dart has no "naive local time" type. Use it
  /// for calendar arithmetic only, and convert back with [toInstant].
  DateTime toLocalWallTime(DateTime instant) => instant.toUtc().add(utcOffset);

  /// The inverse of [toLocalWallTime]: turns a local wall-clock time back
  /// into the absolute instant it refers to.
  DateTime toInstant(DateTime localWallTime) =>
      localWallTime.subtract(utcOffset).toUtc();

  /// Midnight at the start of the user's local day containing [instant].
  DateTime localMidnight(DateTime instant) {
    final local = toLocalWallTime(instant);
    return DateTime.utc(local.year, local.month, local.day);
  }

  @override
  String toString() =>
      'GeoLocation(lat: $latitude, lon: $longitude, '
      'utcOffset: $utcOffset, isFallback: $isFallback)';
}
