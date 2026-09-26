import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../environment/environment_providers.dart';
import 'calendar_date.dart';

/// Today, as a calendar date.
///
/// The single place in the app where the clock becomes a date. Features
/// that reason about days — the Cycle's arithmetic, the Garden's month
/// windows — read this rather than calling `DateTime.now()`, which is
/// what lets a test walk a year a day at a time.
///
/// It follows [clockProvider], so overriding the clock in a test moves
/// every date-aware feature together.
///
/// It prefers the resolved environment's instant, which is what makes
/// "today" *keep* being today: the environment re-resolves at each
/// day/night change, on its six-hourly cap, and when the app returns to
/// the foreground. A screen left open across midnight therefore moves to
/// the new date on its own — Cycle Home does not sit in September on the
/// first of October — without anything polling a clock.
///
/// **The date is read in the app's own time zone**, the IANA zone the
/// environment resolved — never the process's `DateTime.toLocal()`. The
/// two agree until the phone changes zone while the app is in the
/// background: the zone is re-read on resume, but the runtime's own
/// idea of "local" can lag until a restart, and "today" must follow the
/// zone every other date in the app is calculated in.
final todayProvider = Provider<CalendarDate>((ref) {
  final environment = ref.watch(naturalEnvironmentProvider).value;
  if (environment != null) {
    return CalendarDate.from(
      environment.timeZone.wallTimeAt(environment.resolvedAt),
    );
  }

  // Before the first resolution completes, the clock alone — still in
  // the app's zone.
  return CalendarDate.from(
    ref.watch(timeZoneProvider).wallTimeAt(ref.watch(clockProvider)()),
  );
});
