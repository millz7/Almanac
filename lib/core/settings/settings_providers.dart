import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../environment/geo_location.dart';
import 'settings_store.dart';
import 'user_settings.dart';

/// The open settings store.
///
/// Overridden in `main()` with the real store once it has been opened,
/// and in tests with an in-memory one. It has no default because reading
/// settings before the store is ready would be a bug, and a loud failure
/// is better than a silent wrong answer.
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => throw StateError(
    'settingsStoreProvider must be overridden with an open SettingsStore. '
    'main() does this after awaiting openSettingsStore().',
  ),
);

/// The user's saved settings, and the only way to change them.
final userSettingsProvider =
    NotifierProvider<UserSettingsController, UserSettings>(
      UserSettingsController.new,
    );

class UserSettingsController extends Notifier<UserSettings> {
  @override
  UserSettings build() => ref.watch(settingsStoreProvider).read();

  /// Records the user's hemisphere choice.
  ///
  /// The in-memory state is updated only after the write succeeds, so a
  /// storage failure surfaces as a thrown error rather than an app that
  /// looks like it saved but did not. Callers are expected to catch it
  /// and offer a retry.
  Future<void> selectHemisphere(Hemisphere hemisphere) =>
      _persist(state.copyWith(hemisphere: hemisphere));

  /// Records that the user has seen the explanation of what location is
  /// for, whichever way they answered.
  Future<void> markLocationIntroSeen() =>
      _persist(state.copyWith(locationIntroSeen: true));

  Future<void> _persist(UserSettings settings) async {
    if (settings == state) return;
    await ref.read(settingsStoreProvider).write(settings);
    state = settings;
  }
}
