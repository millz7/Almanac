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
final todayProvider = Provider<CalendarDate>(
  (ref) => CalendarDate.from(ref.watch(clockProvider)().toLocal()),
);
