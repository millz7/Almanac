import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

/// The user's local time zone, as a real IANA zone.
///
/// Deliberately separate from `GeoLocation`: the device always knows its
/// time zone, with no permission and no position, so the app can always
/// work out the user's local calendar day even when it has no idea where
/// they are.
///
/// This is a named zone (`Pacific/Auckland`, `Europe/London`) rather than
/// a fixed offset, because an offset cannot describe a place. Somewhere
/// that observes daylight saving is UTC+12 for part of the year and
/// UTC+13 for the rest, and "midnight local" moves with it — which
/// matters for the app, since the local calendar day is what decides
/// which sunrise and sunset apply.
@immutable
class LocalTimeZone {
  const LocalTimeZone(this.location);

  /// Looks up a zone by IANA identifier, e.g. `Pacific/Auckland`.
  ///
  /// Requires [initializeTimeZoneDatabase] to have run. Throws
  /// [tz.LocationNotFoundException] for an unknown identifier — callers
  /// dealing with platform-supplied names should use
  /// [LocalTimeZone.tryByName].
  factory LocalTimeZone.byName(String identifier) =>
      LocalTimeZone(tz.getLocation(identifier));

  /// Like [LocalTimeZone.byName] but returns null instead of throwing, for
  /// identifiers that came from outside the app.
  static LocalTimeZone? tryByName(String identifier) {
    try {
      return LocalTimeZone.byName(identifier);
    } on Object {
      return null;
    }
  }

  /// UTC, used as the last-resort fallback when the platform will not say
  /// where it is. Correct rather than invented: the app is explicit that
  /// it does not know, instead of guessing a zone.
  static LocalTimeZone get utc => LocalTimeZone(tz.UTC);

  final tz.Location location;

  /// The IANA identifier, for display and diagnostics.
  String get id => location.name;

  /// The offset in effect at [instant] — which is a function of the
  /// instant, not a property of the zone, because of daylight saving.
  Duration offsetAt(DateTime instant) =>
      location.timeZone(instant.toUtc().millisecondsSinceEpoch).offset;

  /// Whether daylight saving is in effect at [instant].
  bool isDaylightSavingAt(DateTime instant) =>
      location.timeZone(instant.toUtc().millisecondsSinceEpoch).isDst;

  /// The user's wall-clock time for [instant], as a real zone-aware
  /// [DateTime] whose fields read as the local clock would.
  tz.TZDateTime wallTimeAt(DateTime instant) =>
      tz.TZDateTime.from(instant, location);

  /// The absolute instant at which the local clock reads the given
  /// year/month/day/hour/minute.
  ///
  /// Ambiguous and skipped local times — the hour that repeats or never
  /// happens at a daylight-saving change — are resolved by the time-zone
  /// database rather than by this app.
  tz.TZDateTime instantAtLocal(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
  ]) => tz.TZDateTime(location, year, month, day, hour, minute);

  /// Midnight at the start of the local day containing [instant].
  ///
  /// Uses the zone database rather than subtracting an offset, so this
  /// stays correct on the days a clock shift makes the local day 23 or
  /// 25 hours long.
  tz.TZDateTime midnightOf(DateTime instant) {
    final local = wallTimeAt(instant);
    return instantAtLocal(local.year, local.month, local.day);
  }

  /// The local calendar date containing [instant], as year/month/day.
  ({int year, int month, int day}) localDateOf(DateTime instant) {
    final local = wallTimeAt(instant);
    return (year: local.year, month: local.month, day: local.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalTimeZone && other.location.name == location.name;

  @override
  int get hashCode => location.name.hashCode;

  @override
  String toString() => 'LocalTimeZone($id)';
}
