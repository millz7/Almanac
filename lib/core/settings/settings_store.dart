import 'user_settings.dart';

/// Persists [UserSettings].
///
/// [read] is synchronous: the store is opened once during startup, before
/// the app is built, so the first frame already knows whether onboarding
/// is needed. [write] is asynchronous and is allowed to fail — callers
/// must not treat a save as successful until its future completes.
abstract interface class SettingsStore {
  UserSettings read();

  /// Throws if the settings could not be persisted.
  Future<void> write(UserSettings settings);
}

/// A store that keeps settings only for the lifetime of the process.
///
/// Used by tests, and as the fallback when the real store cannot be
/// opened — the app still runs and still honours the user's choice for
/// this session, it just cannot remember it next time.
class InMemorySettingsStore implements SettingsStore {
  InMemorySettingsStore([this._settings = const UserSettings()]);

  UserSettings _settings;

  @override
  UserSettings read() => _settings;

  @override
  Future<void> write(UserSettings settings) async => _settings = settings;
}
