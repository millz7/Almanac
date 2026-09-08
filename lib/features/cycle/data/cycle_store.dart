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

/// One recorded day, as a single stored line.
///
/// `YYYY-MM-DD|level|start`, e.g. `2026-09-04|heavy|1`. Pipe-separated
/// rather than JSON because every field is a short token with no free
/// text in it — there is nothing here a user typed.
String encodeRecord(CycleDayRecord record) => [
  record.date.iso,
  record.level.name,
  record.isPeriodStart ? '1' : '0',
].join('|');

/// Reads one stored line, or null if it cannot be trusted.
CycleDayRecord? decodeRecord(String line) {
  final parts = line.split('|');
  if (parts.length != 3) return null;

  final date = CalendarDate.tryParse(parts[0]);
  if (date == null) return null;
  final level = BleedingLevel.tryParse(parts[1]);
  if (level == null) return null;

  return CycleDayRecord(
    date: date,
    level: level,
    // A period start on a spotting day is dropped by `CycleData` rather
    // than trusted from a line — including a line an older or newer
    // version wrote.
    isPeriodStart: parts[2] == '1',
  );
}

/// `YYYY-MM-DD|level|start`, one per recorded day, earliest first.
List<String> encodeRecords(CycleData data) => [
  for (final record in data.records) encodeRecord(record),
];

/// Reads a whole stored log, dropping any line that will not parse.
List<CycleDayRecord> decodeRecords(List<String> lines) => [
  for (final line in lines) ?decodeRecord(line),
];

/// Turns Step 11's period-start-only data into day records.
///
/// **Conservative on purpose.** The old model recorded one thing: the
/// dates the user said a period began. So each of those becomes exactly
/// one day of recorded bleeding, marked as that period's day 1 — and
/// **nothing else**. The following four days are not invented, because
/// the old data never claimed them, and inventing them would put
/// bleeding in somebody's history that they never entered.
///
/// Deterministic, and a pure function so the migration can be tested
/// without a store at all.
List<CycleDayRecord> migrateLegacyStarts(Iterable<CalendarDate> starts) => [
  for (final date in starts)
    CycleDayRecord(
      date: date,
      level: BleedingLevel.bleeding,
      isPeriodStart: true,
    ),
];
