import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/environment/environment_providers.dart';
import '../../../core/time/calendar_date.dart';
import '../data/cycle_store.dart';
import '../data/shared_preferences_cycle_store.dart';
import '../domain/cycle_calculator.dart';

export '../data/cycle_store.dart';
export '../domain/cycle_calculator.dart';

/// Where cycle data is kept. Tests override it; the app uses the
/// preferences-backed store, opened lazily on first use.
final cycleStoreProvider = Provider<CycleStore>(
  (ref) => SharedPreferencesCycleStore(),
);

/// Today, as a calendar date.
///
/// The single place the clock becomes a date. Everything below this line
/// is arithmetic on dates, so nothing deeper in the feature ever reads
/// `DateTime.now()` — which is what lets a test walk a cycle a day at a
/// time.
final todayProvider = Provider<CalendarDate>(
  (ref) => CalendarDate.from(ref.watch(clockProvider)().toLocal()),
);

/// The user's recorded cycle dates and their chosen estimate length.
///
/// Read from the store on first use and written back on every change.
/// Nothing here leaves the device.
final cycleDataProvider = AsyncNotifierProvider<CycleController, CycleData>(
  CycleController.new,
);

class CycleController extends AsyncNotifier<CycleData> {
  @override
  Future<CycleData> build() => ref.read(cycleStoreProvider).read();

  CycleData get _data => state.value ?? CycleData.empty;

  /// Records a first day of a period.
  ///
  /// Refuses a date in the future. The date picker cannot offer one, but
  /// the rule belongs here too: a cycle cannot have begun on a day that
  /// has not happened.
  Future<void> recordStart(CalendarDate date) async {
    if (date.isAfter(ref.read(todayProvider))) return;
    await _persist(_data.withStart(date));
  }

  /// Moves a recorded date. Also refuses the future.
  Future<void> editStart(CalendarDate from, CalendarDate to) async {
    if (to.isAfter(ref.read(todayProvider))) return;
    await _persist(_data.replacingStart(from, to));
  }

  Future<void> deleteStart(CalendarDate date) =>
      _persist(_data.withoutStart(date));

  /// Changes what the estimates are drawn with — and only that. The
  /// recorded dates are passed through untouched.
  Future<void> setAssumedLength(int length) =>
      _persist(_data.withAssumedLength(length));

  /// Removes everything, from memory and from storage.
  Future<void> deleteEverything() async {
    await ref.read(cycleStoreProvider).deleteAll();
    state = AsyncData(CycleData.empty);
  }

  /// Writes first, then updates what the screen shows, so the app never
  /// displays a change that was not stored. A failure propagates to the
  /// caller, which tells the user rather than pretending.
  Future<void> _persist(CycleData next) async {
    await ref.read(cycleStoreProvider).write(next);
    state = AsyncData(next);
  }
}

/// Where the cycle has got to today.
final cycleMomentProvider = Provider<CycleMoment>((ref) {
  final data = ref.watch(cycleDataProvider).value ?? CycleData.empty;
  return cycleMomentAt(today: ref.watch(todayProvider), data: data);
});
