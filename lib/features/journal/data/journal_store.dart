import 'dart:convert';

import '../../../core/time/calendar_date.dart';
import '../domain/journal_entry.dart';

/// Keeps the Journal on this device.
///
/// Its own store, its own key, its own delete-everything — the same
/// shape as the Cycle's, the Garden's and the Nature Log's. Nothing here
/// ever leaves the phone: no network, no account, no sharing, and the
/// words on a page are never written to a log.
abstract interface class JournalStore {
  /// Reads what is stored. Returns an empty book rather than throwing.
  Future<JournalBook> read();

  /// Persists [book]. Throws if it could not be written.
  Future<void> write(JournalBook book);

  /// Removes every trace of the Journal from storage.
  Future<void> deleteAll();
}

/// A store that keeps the Journal only for the lifetime of the process.
class InMemoryJournalStore implements JournalStore {
  InMemoryJournalStore([JournalBook? book]) : _book = book ?? JournalBook.empty;

  JournalBook _book;

  /// How many times something was written — for tests that check that
  /// opening, reading or leaving a page writes nothing.
  int writes = 0;

  @override
  Future<JournalBook> read() async => _book;

  @override
  Future<void> write(JournalBook book) async {
    writes++;
    _book = book;
  }

  @override
  Future<void> deleteAll() async => _book = JournalBook.empty;
}

/// One page, as a single stored line of JSON — free text survives any
/// punctuation, and a damaged line costs only its own page.
String encodeJournalEntry(JournalEntry entry) => jsonEncode(
  <String, Object?>{
    'id': entry.id,
    'date': entry.date.iso,
    'text': entry.text,
    'created': entry.createdAt.toUtc().toIso8601String(),
    'updated': entry.updatedAt.toUtc().toIso8601String(),
    'moon': entry.context.moonPhase,
    'lit': entry.context.illuminatedFraction,
    'season': entry.context.season,
    'festivalId': entry.context.festivalId,
    'festival': entry.context.festivalName,
    'maramatakaId': entry.context.maramatakaId,
    'maramataka': entry.context.maramatakaName,
    'maramatakaRef': entry.context.maramatakaReference,
  }..removeWhere((_, value) => value == null),
);

/// Reads one stored line, or null if it cannot be trusted.
///
/// A page with no words is dropped too: there is no such thing as a
/// blank entry.
JournalEntry? decodeJournalEntry(String line) {
  final Object? parsed;
  try {
    parsed = jsonDecode(line);
  } on FormatException {
    return null;
  }
  if (parsed is! Map<String, dynamic>) return null;

  final date = parsed['date'];
  final parsedDate = date is String ? CalendarDate.tryParse(date) : null;
  if (parsedDate == null) return null;

  final text = parsed['text'];
  if (text is! String || text.trim().isEmpty) return null;

  DateTime? instant(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
  final created = instant(parsed['created']);
  final updated = instant(parsed['updated']);
  if (created == null || updated == null) return null;

  final moon = parsed['moon'];
  final lit = parsed['lit'];
  final season = parsed['season'];
  if (moon is! String || season is! String) return null;
  if (lit is! num || !lit.isFinite || lit < 0 || lit > 1) return null;

  String? optional(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  return JournalEntry(
    date: parsedDate,
    text: text,
    createdAt: created,
    updatedAt: updated,
    context: JournalContext(
      moonPhase: moon,
      illuminatedFraction: lit.toDouble(),
      season: season,
      festivalId: optional(parsed['festivalId']),
      festivalName: optional(parsed['festival']),
      maramatakaId: optional(parsed['maramatakaId']),
      maramatakaName: optional(parsed['maramataka']),
      maramatakaReference: optional(parsed['maramatakaRef']),
    ),
  );
}

/// Reads a whole stored Journal, dropping any line that will not parse.
///
/// Should two lines ever claim one date — only possible if the file was
/// damaged — the first is kept, so there is still one page per date.
JournalBook decodeJournal(List<String> lines) {
  final seen = <CalendarDate>{};
  return JournalBook([
    for (final line in lines)
      if (decodeJournalEntry(line) case final entry?)
        if (seen.add(entry.date)) entry,
  ]);
}

List<String> encodeJournal(JournalBook book) => [
  for (final entry in book.entries) encodeJournalEntry(entry),
];
