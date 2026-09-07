import 'dart:convert';

import '../../../core/time/calendar_date.dart';
import '../domain/observation.dart';

/// Keeps the Nature Log on this device.
///
/// Its own store, its own key, its own delete-everything — the same
/// shape as the Cycle's and the Garden's. What somebody has noticed is
/// theirs; it has nothing to do with app preferences, and "clear my log"
/// has to mean exactly that.
///
/// Local only. No network, no account, and **no coordinates**: an
/// observation carries a place only when the user typed one, in their
/// own words.
abstract interface class NatureLogStore {
  /// Reads what is stored. Returns an empty log rather than throwing.
  Future<NatureLog> read();

  /// Persists [log]. Throws if it could not be written.
  Future<void> write(NatureLog log);

  /// Removes every trace of the log from storage.
  Future<void> deleteAll();
}

/// A store that keeps the log only for the lifetime of the process.
class InMemoryNatureLogStore implements NatureLogStore {
  InMemoryNatureLogStore([NatureLog? log]) : _log = log ?? NatureLog.empty;

  NatureLog _log;

  @override
  Future<NatureLog> read() async => _log;

  @override
  Future<void> write(NatureLog log) async => _log = log;

  @override
  Future<void> deleteAll() async => _log = NatureLog.empty;
}

/// One observation, as a single stored line of JSON.
///
/// JSON rather than the Garden's pipe-separated line, because these
/// records hold free text: a note reading "on the fence | by the shed"
/// must survive being written down. Still one line per observation, so a
/// line that will not parse can be dropped on its own.
String encodeObservation(NatureObservation observation) => jsonEncode(
  <String, Object?>{
    'id': observation.instanceId,
    'date': observation.date.iso,
    'category': observation.category.name,
    'label': observation.label,
    'order': observation.order,
    'item': observation.itemId,
    'note': observation.note,
    'place': observation.placeLabel,
  }..removeWhere((_, value) => value == null),
);

/// Reads one stored line, or null if it cannot be trusted.
///
/// Everything optional may be missing; everything required has to parse.
/// A line that does not is dropped — a damaged file should cost the
/// entry it damaged and nothing more.
NatureObservation? decodeObservation(String line) {
  final Object? parsed;
  try {
    parsed = jsonDecode(line);
  } on FormatException {
    return null;
  }
  if (parsed is! Map<String, dynamic>) return null;

  final id = parsed['id'];
  final label = parsed['label'];
  final order = parsed['order'];
  if (id is! String || id.isEmpty) return null;
  if (label is! String || label.trim().isEmpty) return null;
  if (order is! int) return null;

  final date = parsed['date'];
  if (date is! String) return null;
  final parsedDate = CalendarDate.tryParse(date);
  if (parsedDate == null) return null;

  final category = parsed['category'];
  if (category is! String) return null;
  final parsedCategory = NatureCategory.tryParse(category);
  if (parsedCategory == null) return null;

  String? text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  return NatureObservation(
    instanceId: id,
    date: parsedDate,
    category: parsedCategory,
    label: label,
    order: order,
    // Kept as written even when this version has never heard of it: the
    // label above is what makes that survivable.
    itemId: text(parsed['item']),
    note: text(parsed['note']),
    placeLabel: text(parsed['place']),
  );
}

/// Reads a whole stored log, dropping any line that will not parse.
///
/// **An unknown item id is kept, not dropped.** A log written by a later
/// version may name an entry this one does not have; because every
/// observation carries the name it was saved with, it still reads
/// correctly and can still be edited or deleted. Downgrading loses
/// nothing.
NatureLog decodeLog(List<String> lines) =>
    NatureLog([for (final line in lines) ?decodeObservation(line)]);

List<String> encodeLog(NatureLog log) => [
  for (final observation in log.observations) encodeObservation(observation),
];
