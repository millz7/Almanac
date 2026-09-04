import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
// The "all" dataset, not the smaller "latest" one, because it includes
// the database's link names as well as its canonical zones. Android
// happily reports links — Europe/Oslo, Asia/Calcutta, US/Pacific — and
// with the smaller dataset every one of those would fail to resolve and
// silently drop the user to UTC.
import 'package:timezone/data/latest_all.dart' as tz_data;

import 'local_time_zone.dart';

/// Loads the IANA time-zone database into memory.
///
/// Must run once before any [LocalTimeZone] is created — from `main()` in
/// the app, and from test setup. Calling it more than once is harmless.
void initializeTimeZoneDatabase() => tz_data.initializeTimeZones();

/// Finds out which time zone the device is actually in.
///
/// Behind an interface because it is a platform call: tests substitute a
/// fixed zone rather than inheriting whatever the machine running them
/// happens to be set to.
abstract interface class TimeZoneService {
  Future<LocalTimeZone> currentTimeZone();
}

/// Reads the device's IANA zone identifier from the platform.
///
/// Android reports this from `TimeZone.getDefault().getID()`, so it
/// follows the user's system setting — including automatic changes when
/// they travel — and needs no permission.
///
/// Dart cannot do this by itself: `DateTime.timeZoneName` yields an
/// abbreviation such as `NZST` or `PDT`, which is ambiguous between zones
/// and useless for looking up daylight-saving rules.
class PlatformTimeZoneService implements TimeZoneService {
  const PlatformTimeZoneService();

  @override
  Future<LocalTimeZone> currentTimeZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final zone = LocalTimeZone.tryByName(info.identifier);
      if (zone != null) return zone;
      debugPrint(
        'Unknown time zone identifier "${info.identifier}"; using UTC.',
      );
    } on Object catch (error) {
      debugPrint('Could not read the device time zone: $error');
    }
    // Better to be openly wrong-but-defined than to invent a zone.
    return LocalTimeZone.utc;
  }
}

/// A time-zone service that always reports the same zone. Used by tests
/// and as a stand-in where no platform is available.
class FixedTimeZoneService implements TimeZoneService {
  const FixedTimeZoneService(this.zone);

  final LocalTimeZone zone;

  @override
  Future<LocalTimeZone> currentTimeZone() async => zone;
}
