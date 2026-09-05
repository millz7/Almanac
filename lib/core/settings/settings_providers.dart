import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../environment/geo_location.dart';
import '../features/feature_registry.dart';
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

  /// The longest name the app will keep.
  ///
  /// Not a validation rule so much as a limit on how much of somebody's
  /// input can end up in a heading. Anything longer is trimmed rather
  /// than rejected, because refusing a name would be a strange thing for
  /// this app to do.
  static const maxNameLength = 40;

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

  /// Sets what the user would like to be called.
  ///
  /// Whitespace-only input is the same as no name — it would otherwise
  /// produce the heading "'s Almanac" — so it is stored as null and the
  /// app falls back to "Your Almanac". Either way the question counts as
  /// answered.
  Future<void> setName(String? name) {
    final trimmed = name?.trim();
    final cleaned = (trimmed == null || trimmed.isEmpty)
        ? null
        : trimmed.substring(
            0,
            trimmed.length < maxNameLength ? trimmed.length : maxNameLength,
          );

    return _persist(state.copyWith(name: cleaned, nameAsked: true));
  }

  /// Records that the name question has been put and declined, without
  /// storing anything.
  Future<void> skipName() => setName(null);

  /// Replaces the whole set of chosen features.
  ///
  /// The Environment is stripped out if a caller passes it: it is part of
  /// the app, not a choice, and letting it into the stored set would
  /// invite code that could switch it off.
  Future<void> setFeatures(Set<FeatureId> features) => _persist(
    state.copyWith(features: {...features}..remove(FeatureId.environment)),
  );

  /// Adds or removes one feature.
  ///
  /// Ignores any attempt to change the Environment rather than throwing:
  /// the UI never offers it, and a silent no-op is the safer answer if
  /// some future screen tries.
  Future<void> setFeatureChosen(FeatureId id, bool chosen) {
    if (id == FeatureId.environment) return Future.value();

    final next = {...state.features};
    if (chosen) {
      next.add(id);
    } else {
      next.remove(id);
    }
    return setFeatures(next);
  }

  /// Marks first-launch setup as finished. The last step of onboarding.
  Future<void> completeOnboarding() =>
      _persist(state.copyWith(onboardingCompleted: true));

  Future<void> _persist(UserSettings settings) async {
    if (settings == state) return;
    await ref.read(settingsStoreProvider).write(settings);
    state = settings;
  }
}

/// The title of the user's Almanac, as shown on the drawer and its
/// opening control.
///
/// The one place the name is used. Someone who skipped the question gets
/// "Your Almanac", which is a proper title rather than an apology for a
/// missing value.
final almanacTitleProvider = Provider<String>(
  (ref) => almanacTitleFor(ref.watch(userSettingsProvider).name),
);

/// "Millie's Almanac", or "Your Almanac" when there is no name.
///
/// A name already ending in "s" gets "'s" all the same — "Chris's
/// Almanac" — which is the more common convention and avoids having to
/// guess whether a name is a plural.
String almanacTitleFor(String? name) =>
    (name == null || name.trim().isEmpty) ? 'Your Almanac' : "$name's Almanac";
