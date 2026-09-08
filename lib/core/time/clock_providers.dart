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
final todayProvider = Provider<CalendarDate>((ref) {
  final environment = ref.watch(naturalEnvironmentProvider).value;
  if (environment != null) {
    return CalendarDate.from(environment.resolvedAt.toLocal());
  }

  // Before the first resolution completes, the clock alone.
  return CalendarDate.from(ref.watch(clockProvider)().toLocal());
});
