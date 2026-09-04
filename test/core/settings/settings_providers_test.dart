import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/core/settings/settings_store.dart';
import 'package:almanac/core/settings/user_settings.dart';
import 'package:almanac/features/onboarding/domain/onboarding_stage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A store whose writes fail, to prove a save failure is not swallowed.
class _FailingSettingsStore implements SettingsStore {
  const _FailingSettingsStore();

  @override
  UserSettings read() => const UserSettings();

  @override
  Future<void> write(UserSettings settings) async =>
      throw StateError('disk is full');
}

void main() {
  ProviderContainer containerWith(SettingsStore store) {
    final container = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('first launch', () {
    test('nothing stored means onboarding starts at the hemisphere', () {
      final container = containerWith(InMemorySettingsStore());

      expect(container.read(userSettingsProvider).hemisphere, isNull);
      expect(
        container.read(onboardingStageProvider),
        OnboardingStage.hemisphere,
      );
    });
  });

  group('selecting a hemisphere', () {
    test('northern is saved and moves setup on', () async {
      final store = InMemorySettingsStore();
      final container = containerWith(store);

      await container
          .read(userSettingsProvider.notifier)
          .selectHemisphere(Hemisphere.northern);

      expect(store.read().hemisphere, Hemisphere.northern);
      expect(
        container.read(userSettingsProvider).hemisphere,
        Hemisphere.northern,
      );
      expect(container.read(onboardingStageProvider), OnboardingStage.location);
    });

    test('southern is saved', () async {
      final store = InMemorySettingsStore();
      final container = containerWith(store);

      await container
          .read(userSettingsProvider.notifier)
          .selectHemisphere(Hemisphere.southern);

      expect(store.read().hemisphere, Hemisphere.southern);
      expect(
        container.read(userSettingsProvider).hemisphere,
        Hemisphere.southern,
      );
    });

    test('the choice can be changed later', () async {
      final store = InMemorySettingsStore(
        const UserSettings(
          hemisphere: Hemisphere.northern,
          locationIntroSeen: true,
        ),
      );
      final container = containerWith(store);

      await container
          .read(userSettingsProvider.notifier)
          .selectHemisphere(Hemisphere.southern);

      expect(store.read().hemisphere, Hemisphere.southern);
      // Changing it does not drag the user back through onboarding.
      expect(container.read(onboardingStageProvider), OnboardingStage.complete);
    });
  });

  group('existing preference', () {
    test('a stored southern hemisphere skips the hemisphere question', () {
      final container = containerWith(
        InMemorySettingsStore(
          const UserSettings(
            hemisphere: Hemisphere.southern,
            locationIntroSeen: true,
          ),
        ),
      );

      expect(
        container.read(userSettingsProvider).hemisphere,
        Hemisphere.southern,
      );
      expect(container.read(onboardingStageProvider), OnboardingStage.complete);
    });

    test('a hemisphere without the location intro resumes at location', () {
      final container = containerWith(
        InMemorySettingsStore(
          const UserSettings(hemisphere: Hemisphere.southern),
        ),
      );

      expect(container.read(onboardingStageProvider), OnboardingStage.location);
    });
  });

  group('restart', () {
    test('the saved hemisphere is still there in a fresh container', () async {
      // One store, two containers: the second stands in for a relaunch.
      final store = InMemorySettingsStore();

      final firstRun = containerWith(store);
      await firstRun
          .read(userSettingsProvider.notifier)
          .selectHemisphere(Hemisphere.southern);
      await firstRun
          .read(userSettingsProvider.notifier)
          .markLocationIntroSeen();

      final secondRun = containerWith(store);

      expect(
        secondRun.read(userSettingsProvider).hemisphere,
        Hemisphere.southern,
      );
      expect(secondRun.read(onboardingStageProvider), OnboardingStage.complete);
    });
  });

  group('save failure', () {
    test('a failed write throws and leaves the state unchanged', () async {
      final container = containerWith(const _FailingSettingsStore());

      await expectLater(
        container
            .read(userSettingsProvider.notifier)
            .selectHemisphere(Hemisphere.southern),
        throwsA(isA<StateError>()),
      );

      // The app must not act as though the choice was saved.
      expect(container.read(userSettingsProvider).hemisphere, isNull);
      expect(
        container.read(onboardingStageProvider),
        OnboardingStage.hemisphere,
      );
    });
  });

  group('location intro', () {
    test('is recorded so the user is only asked once', () async {
      final store = InMemorySettingsStore(
        const UserSettings(hemisphere: Hemisphere.northern),
      );
      final container = containerWith(store);

      expect(container.read(onboardingStageProvider), OnboardingStage.location);

      await container
          .read(userSettingsProvider.notifier)
          .markLocationIntroSeen();

      expect(store.read().locationIntroSeen, isTrue);
      expect(container.read(onboardingStageProvider), OnboardingStage.complete);
    });
  });
}
