import 'package:flutter/foundation.dart';

/// The user's local time zone, as a plain offset from UTC.
///
/// Deliberately separate from [GeoLocation]: the device always knows its
/// UTC offset, with no permission and no position, so the app can always
/// work out the user's local calendar day even when it has no idea where
/// they are.
///
/// An offset is not a full IANA zone — it cannot say when daylight saving
/// changes — but nothing here needs that yet: season boundaries and
/// sunrise/sunset are absolute instants, and the offset is only used to
/// find local midnight. A real zone can replace this without changing any
/// caller.
@immutable
class LocalTimeZone {
  const LocalTimeZone(this.utcOffset);

  /// The device's current offset. Available without any permission.
  factory LocalTimeZone.ofDevice() =>
      LocalTimeZone(DateTime.now().timeZoneOffset);

  final Duration utcOffset;

  /// The user's wall-clock time for [instant].
  ///
  /// The result carries local field values (year/month/day/hour) but is
  /// flagged as UTC, because Dart has no "naive local time" type. Use it
  /// for calendar arithmetic only, and convert back with [instantOf].
  DateTime wallTimeAt(DateTime instant) => instant.toUtc().add(utcOffset);

  /// The inverse of [wallTimeAt]: turns a local wall-clock time back into
  /// the absolute instant it refers to.
  DateTime instantOf(DateTime wallTime) => wallTime.subtract(utcOffset).toUtc();

  /// Midnight at the start of the local day containing [instant], as an
  /// absolute instant.
  DateTime midnightOf(DateTime instant) {
    final local = wallTimeAt(instant);
    return instantOf(DateTime.utc(local.year, local.month, local.day));
  }

  @override
  bool operator ==(Object other) =>
      other is LocalTimeZone && other.utcOffset == utcOffset;

  @override
  int get hashCode => utcOffset.hashCode;

  @override
  String toString() => 'LocalTimeZone(${utcOffset.inHours}h)';
}
