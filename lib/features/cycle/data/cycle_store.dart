import '../../../core/time/calendar_date.dart';
import '../domain/cycle_data.dart';

/// Keeps the Cycle feature's data on this device.
///
/// Deliberately its own store rather than a corner of the app's settings.
/// Cycle dates are sensitive in a way a hemisphere preference is not:
/// they need their own keys, their own serialisation, and — the part that
/// matters most — their own [deleteAll], so "delete my cycle history"
/// means exactly that and cannot take anything else with it or leave
/// anything behind.
///
/// Local only. There is no remote implementation of this interface and
/// nothing here touches the network.
abstract interface class CycleStore {
  /// Reads what is stored. Returns empty data rather than throwing: a
  /// device that cannot read its own preferences should still show the
  /// feature, and a corrupted value should be dropped, not fatal.
  Future<CycleData> read();

  /// Persists [data]. Throws if it could not be written, so a caller
  /// never reports a save that did not happen.
  Future<void> write(CycleData data);

  /// Removes every trace of the feature's data from storage.
  Future<void> deleteAll();
}

/// A store that keeps cycle data only for the lifetime of the process.
/// Used by tests, and as the fallback when the real one cannot be opened.
class InMemoryCycleStore implements CycleStore {
  InMemoryCycleStore([CycleData? data]) : _data = data ?? CycleData.empty;

  CycleData _data;

  @override
  Future<CycleData> read() async => _data;

  @override
  Future<void> write(CycleData data) async => _data = data;

  @override
  Future<void> deleteAll() async => _data = CycleData.empty;
}

/// Turns stored strings into dates, dropping anything unreadable.
///
/// Nothing that fails to parse is logged: an unreadable entry is still a
/// cycle date, and a debug line is exactly how sensitive data escapes
/// into a log. The count is safe to know; the values are not.
List<CalendarDate> parseStoredStarts(List<String> stored) => [
  for (final entry in stored) ?CalendarDate.tryParse(entry),
];

/// `YYYY-MM-DD`, one per recorded start, earliest first.
List<String> encodeStarts(CycleData data) => [
  for (final date in data.periodStarts) date.iso,
];
