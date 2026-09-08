import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/environment/environment_providers.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock_providers.dart';
import '../data/nature_log_store.dart';
import '../data/shared_preferences_nature_log_store.dart';
import '../domain/around_now.dart';
import '../domain/observation.dart';

export '../../../core/time/calendar_date.dart' show CalendarDate;
export '../../../core/time/clock_providers.dart' show todayProvider;
export '../data/nature_log_store.dart';
export '../domain/around_now.dart';
export '../domain/observation.dart';

/// Which nature guide applies where the user is.
///
/// Reads the location state the rest of the app already resolved — and
/// nothing else. The hemisphere is deliberately not consulted: it
/// settles the astronomical season, which the screens read from
/// `currentSeasonProvider`, but it cannot settle which species guide
/// applies. See [NatureGuide.resolve].
///
/// It never asks for permission: opening the Nature Log must not make
/// the phone put up a dialog, and there is a test for that.
final natureGuideProvider = Provider<NatureGuide>(
  (ref) => NatureGuide.resolve(location: ref.watch(locationStateProvider)),
);

/// Where the Nature Log is kept. Tests override it; the app uses the
/// preferences-backed store, opened lazily on first use.
final natureLogStoreProvider = Provider<NatureLogStore>(
  (ref) => SharedPreferencesNatureLogStore(),
);

/// What the user has noticed, and the only way to change it.
final natureLogProvider = AsyncNotifierProvider<NatureLogController, NatureLog>(
  NatureLogController.new,
);

class NatureLogController extends AsyncNotifier<NatureLog> {
  @override
  Future<NatureLog> build() => ref.read(natureLogStoreProvider).read();

  NatureLog get _log => state.value ?? NatureLog.empty;

  /// Records something from the Nature Book.
  ///
  /// The entry's name is written down as it stands today — see
  /// [NatureObservation.label] — so the observation survives a book that
  /// changes later.
  Future<void> recordFromBook({
    required NatureItem item,
    CalendarDate? on,
    String? note,
    String? placeLabel,
  }) => _record(
    category: item.category,
    label: item.primaryName,
    itemId: item.id,
    on: on,
    note: note,
    placeLabel: placeLabel,
  );

  /// Records something the user described themselves.
  ///
  /// Kept exactly as they wrote it. The app does not try to match it to
  /// anything in the book, and does not try to identify it.
  Future<void> recordCustom({
    required String name,
    required NatureCategory category,
    CalendarDate? on,
    String? note,
    String? placeLabel,
  }) => _record(
    category: category,
    label: name,
    on: on,
    note: note,
    placeLabel: placeLabel,
  );

  Future<void> _record({
    required NatureCategory category,
    required String label,
    CalendarDate? on,
    String? itemId,
    String? note,
    String? placeLabel,
  }) {
    final today = ref.read(todayProvider);
    final date = on ?? today;
    final order = _log.nextOrder;

    return _persist(
      _log.adding(
        NatureObservation(
          // The order makes it unique even for two of the same thing on
          // one day, without a random number or a clock reading.
          instanceId: 'obs-$order-${date.iso}',
          date: date,
          category: category,
          label: label.trim(),
          order: order,
          itemId: itemId,
          note: _clean(note),
          placeLabel: _clean(placeLabel),
        ),
      ),
    );
  }

  /// Edits an observation. Blank text clears the field rather than
  /// storing whitespace.
  Future<void> edit(
    String instanceId, {
    CalendarDate? date,
    NatureCategory? category,
    String? label,
    String? note,
    String? placeLabel,
  }) {
    final existing = _log.find(instanceId);
    if (existing == null) return Future.value();

    final trimmedLabel = label?.trim();
    return _persist(
      _log.updating(
        existing.copyWith(
          date: date,
          category: category,
          label: trimmedLabel == null || trimmedLabel.isEmpty
              ? null
              : trimmedLabel,
          note: _clean(note),
          placeLabel: _clean(placeLabel),
          clearNote: _clean(note) == null,
          clearPlace: _clean(placeLabel) == null,
        ),
      ),
    );
  }

  Future<void> remove(String instanceId) => _persist(_log.removing(instanceId));

  /// Removes everything, from memory and from storage.
  Future<void> clear() async {
    await ref.read(natureLogStoreProvider).deleteAll();
    state = AsyncData(NatureLog.empty);
  }

  static String? _clean(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// Writes first, then updates what the screen shows, so the app never
  /// displays a change that was not stored.
  Future<void> _persist(NatureLog next) async {
    await ref.read(natureLogStoreProvider).write(next);
    state = AsyncData(next);
  }
}

/// What the guide suggests looking for, here and now.
///
/// Depends on where and when, and deliberately not on what the user has
/// recorded: a suggestion is never mistaken for an observation.
final aroundNowProvider = Provider<AroundNow>(
  (ref) => aroundNow(
    guide: ref.watch(natureGuideProvider),
    today: ref.watch(todayProvider),
  ),
);
