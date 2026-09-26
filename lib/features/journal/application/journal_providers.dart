import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/context/festival_context.dart';
import '../../../core/context/almanac_context.dart';
import '../../../core/environment/environment_providers.dart';
import '../../../core/time/calendar_date.dart';
import '../data/journal_store.dart';
import '../data/shared_preferences_journal_store.dart';
import '../domain/journal_entry.dart';

export '../../../core/time/calendar_date.dart' show CalendarDate;
export '../../../core/time/clock_providers.dart' show todayProvider;
export '../data/journal_store.dart';
export '../domain/journal_entry.dart';

/// Where the Journal is kept. Tests override it; the app uses the
/// preferences-backed store, opened lazily on first use.
final journalStoreProvider = Provider<JournalStore>(
  (ref) => SharedPreferencesJournalStore(),
);

/// What surrounds today, in the words a page would record.
///
/// Read from the providers every other feature reads — the one Moon, the
/// one season, the Wheel's festival bridge, the Maramataka preference —
/// and never calculated here. Each optional part is gated where it
/// comes from: no festival while the Wheel is switched off, no
/// Maramataka while the preference is off.
final journalContextProvider = Provider<JournalContext>((ref) {
  final moon = ref.watch(currentMoonProvider);
  final season = ref.watch(currentSeasonProvider);
  // Only a festival falling *on* today — an approaching one is not part
  // of what the day was.
  final festival = ref.watch(almanacFestivalProvider(null));
  final onToday =
      festival != null && festival.state == FestivalTimingState.today
      ? festival.id
      : null;
  final night = ref.watch(currentMaramatakaProvider);

  return JournalContext(
    moonPhase: moon.phase.label,
    illuminatedFraction: moon.illuminatedFraction,
    season: season.label,
    festivalId: onToday?.name,
    festivalName: onToday?.label,
    maramatakaId: night?.id,
    maramatakaName: night?.name,
    maramatakaReference: night == null ? null : Maramataka.referenceId,
  );
});

/// Permission to write one page: today's, as it was when the page was
/// opened.
///
/// **The only way to write.** Its constructor is private to this library
/// and the one thing that makes one is [JournalController.openToday],
/// which reads the date from [todayProvider]. There is no way to ask for
/// a past or a future page, so none can be written.
///
/// **The midnight rule.** A draft keeps the date it was opened with. If
/// the clock passes midnight while somebody is writing, saving still
/// stamps the day they started on — the words were that day's. Once they
/// leave the page, the next draft opened is the new day's.
class JournalDraft {
  const JournalDraft._(this.date, this.context);

  /// The page this draft writes to.
  final CalendarDate date;

  /// What surrounded the day when the page was opened — used for a new
  /// page if the save lands after midnight, when the live context would
  /// already describe the next day.
  final JournalContext context;

  @override
  String toString() => 'JournalDraft(${date.iso})';
}

/// Every saved page, and the only way to change them.
final journalProvider = AsyncNotifierProvider<JournalController, JournalBook>(
  JournalController.new,
);

class JournalController extends AsyncNotifier<JournalBook> {
  @override
  Future<JournalBook> build() => ref.read(journalStoreProvider).read();

  JournalBook get _book => state.value ?? JournalBook.empty;

  /// Opens today's page for writing. Writes nothing: a page exists only
  /// once something is saved on it.
  JournalDraft openToday() =>
      JournalDraft._(ref.read(todayProvider), ref.read(journalContextProvider));

  /// Saves [text] on the draft's page.
  ///
  /// A new page takes its snapshot now — from the live context while it
  /// is still the draft's day, or from the one captured when the page
  /// was opened if midnight has passed since. An existing page keeps the
  /// snapshot it was first saved with; only its words and [updatedAt]
  /// change.
  ///
  /// Blank text is refused rather than stored: there is no blank page.
  Future<void> save(JournalDraft draft, String text) {
    if (text.trim().isEmpty) {
      return Future.error(
        ArgumentError('A journal page needs something written on it'),
      );
    }
    final now = ref.read(clockProvider)();
    final existing = _book.find(draft.date);
    if (existing != null) {
      if (existing.text == text) return Future.value();
      return _persist(_book.putting(existing.withText(text, updatedAt: now)));
    }

    final context = ref.read(todayProvider) == draft.date
        ? ref.read(journalContextProvider)
        : draft.context;
    return _persist(
      _book.putting(
        JournalEntry(
          date: draft.date,
          text: text,
          createdAt: now,
          updatedAt: now,
          context: context,
        ),
      ),
    );
  }

  /// Removes one page. The screen asks first.
  Future<void> remove(CalendarDate date) {
    if (_book.find(date) == null) return Future.value();
    return _persist(_book.removing(date));
  }

  /// Removes everything, from memory and from storage.
  Future<void> clear() async {
    await ref.read(journalStoreProvider).deleteAll();
    state = AsyncData(JournalBook.empty);
  }

  /// Writes first, then updates what the screen shows, so the app never
  /// displays a page that was not stored.
  Future<void> _persist(JournalBook next) async {
    await ref.read(journalStoreProvider).write(next);
    state = AsyncData(next);
  }
}
