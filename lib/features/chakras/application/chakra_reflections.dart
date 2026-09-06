import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chakras.dart';

/// Anything the user has written, this visit.
///
/// **Deliberately not persisted.** The app's only store is
/// [SettingsStore], which holds one small `UserSettings` object written
/// whole — the right shape for preferences and the wrong shape for
/// somebody's private writing, which needs its own lifecycle, its own
/// deletion and its own thinking about what it means to keep it. Rather
/// than bend the settings store into a journal, or pull in a database for
/// seven short strings, a reflection lives in memory for as long as the
/// Almanac is open and is then gone. The screen says so in those words.
///
/// What is true either way, and is the part that matters: nothing written
/// here leaves the device. No account, no sync, no network, no analytics.
///
/// Held in a provider rather than in the screen's own state so that
/// stepping away to another tab and coming back does not lose a
/// half-considered thought.
final chakraReflectionsProvider =
    NotifierProvider<ChakraReflections, Map<ChakraId, String>>(
      ChakraReflections.new,
    );

class ChakraReflections extends Notifier<Map<ChakraId, String>> {
  @override
  Map<ChakraId, String> build() => const {};

  /// What was written for [id], or null if nothing was.
  String? forChakra(ChakraId id) => state[id];

  /// Keeps [text] against [id].
  ///
  /// Blank input is the same as none: saving an empty field clears
  /// whatever was there rather than storing a piece of whitespace. That
  /// makes "Save reflection" on an untouched field a safe thing to press,
  /// which it has to be — writing is optional.
  void save(ChakraId id, String text) {
    final trimmed = text.trim();
    final next = Map<ChakraId, String>.from(state);
    if (trimmed.isEmpty) {
      next.remove(id);
    } else {
      next[id] = trimmed;
    }
    state = next;
  }
}
