import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/core/settings/settings_store.dart';
import 'package:almanac/core/settings/user_settings.dart';
import 'package:almanac/features/onboarding/domain/onboarding_stage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer containerWith(SettingsStore store) {
    final container = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  UserSettingsController controllerFor(SettingsStore store) =>
      containerWith(store).read(userSettingsProvider.notifier);

  group('UserSettings', () {
    test('a fresh install has answered nothing', () {
      const settings = UserSettings();

      expect(settings.name, isNull);
      expect(settings.nameAsked, isFalse);
      expect(settings.hemisphere, isNull);
      expect(settings.features, isEmpty);
      expect(settings.onboardingCompleted, isFalse);
    });

    test('copyWith leaves the name alone unless it is passed', () {
      const settings = UserSettings(name: 'Millie');

      expect(settings.copyWith(nameAsked: true).name, 'Millie');
      // Passing null explicitly is how a name is removed — the whole
      // reason copyWith needs a sentinel here.
      expect(settings.copyWith(name: null).name, isNull);
      expect(settings.copyWith(name: 'Sam').name, 'Sam');
    });

    test('equality covers the feature set by contents, not by identity', () {
      const a = UserSettings(features: {FeatureId.yoga, FeatureId.garden});
      const b = UserSettings(features: {FeatureId.garden, FeatureId.yoga});
      const c = UserSettings(features: {FeatureId.yoga});

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('the Environment is always included, whatever is stored', () {
      const settings = UserSettings();

      expect(settings.includes(FeatureId.environment), isTrue);
      expect(settings.includes(FeatureId.yoga), isFalse);
    });

    test('chosen features come back in registry order, not pick order', () {
      const settings = UserSettings(
        features: {FeatureId.natureLog, FeatureId.meditation, FeatureId.cycle},
      );

      expect(settings.chosenFeatures.map((feature) => feature.name).toList(), [
        'Meditation',
        'Cycle',
        'Nature Log',
      ]);
    });
  });

  group('the name', () {
    test('is stored, and counts as asked', () async {
      final store = InMemorySettingsStore();
      await controllerFor(store).setName('Millie');

      expect(store.read().name, 'Millie');
      expect(store.read().nameAsked, isTrue);
      expect(almanacTitleFor(store.read().name), "Millie's Almanac");
    });

    test('is trimmed', () async {
      final store = InMemorySettingsStore();
      await controllerFor(store).setName('   Millie   ');

      expect(store.read().name, 'Millie');
    });

    test('skipping stores nothing but still counts as asked', () async {
      final store = InMemorySettingsStore();
      await controllerFor(store).skipName();

      expect(store.read().name, isNull);
      expect(store.read().nameAsked, isTrue);
      expect(almanacTitleFor(store.read().name), 'Your Almanac');
    });

    test('whitespace only is the same as no name', () async {
      final store = InMemorySettingsStore();
      await controllerFor(store).setName('    ');

      // Otherwise the panel would be titled "'s Almanac".
      expect(store.read().name, isNull);
      expect(almanacTitleFor(store.read().name), 'Your Almanac');
    });

    test('can be removed later', () async {
      final store = InMemorySettingsStore(
        const UserSettings(name: 'Millie', nameAsked: true),
      );
      await controllerFor(store).setName('');

      expect(store.read().name, isNull);
    });

    test('is capped rather than rejected', () async {
      final store = InMemorySettingsStore();
      await controllerFor(store).setName('M' * 200);

      expect(store.read().name!.length, UserSettingsController.maxNameLength);
    });
  });

  group('choosing features', () {
    test('none is a valid answer', () async {
      final store = InMemorySettingsStore();
      await controllerFor(store).setFeatures({});

      expect(store.read().features, isEmpty);
      // And the Environment is still there.
      expect(store.read().includes(FeatureId.environment), isTrue);
    });

    test('one is stored', () async {
      final store = InMemorySettingsStore();
      await controllerFor(store).setFeatures({FeatureId.yoga});

      expect(store.read().features, {FeatureId.yoga});
    });

    test('several are stored', () async {
      final store = InMemorySettingsStore();
      await controllerFor(store).setFeatures({
        FeatureId.meditation,
        FeatureId.cookbook,
        FeatureId.natureLog,
      });

      expect(store.read().features, {
        FeatureId.meditation,
        FeatureId.cookbook,
        FeatureId.natureLog,
      });
    });

    test('all seven are stored', () async {
      final store = InMemorySettingsStore();
      final everything = FeatureRegistry.optional
          .map((feature) => feature.id)
          .toSet();
      await controllerFor(store).setFeatures(everything);

      expect(store.read().features, everything);
      expect(store.read().chosenFeatures.length, 7);
    });

    test('one can be added and removed again', () async {
      final store = InMemorySettingsStore();
      final controller = controllerFor(store);

      await controller.setFeatureChosen(FeatureId.garden, true);
      expect(store.read().features, {FeatureId.garden});

      await controller.setFeatureChosen(FeatureId.garden, false);
      expect(store.read().features, isEmpty);
    });

    test('the Environment cannot be added to the stored set', () async {
      final store = InMemorySettingsStore();
      await controllerFor(store)
          .setFeatures({FeatureId.environment, FeatureId.yoga});

      // It is part of the app, not a choice; storing it as one would
      // invite code that could switch it off.
      expect(store.read().features, {FeatureId.yoga});
    });

    test('the Environment cannot be switched off', () async {
      final store = InMemorySettingsStore(
        const UserSettings(features: {FeatureId.yoga}),
      );
      await controllerFor(store).setFeatureChosen(FeatureId.environment, false);

      expect(store.read().includes(FeatureId.environment), isTrue);
      expect(store.read().features, {FeatureId.yoga});
    });
  });

  group('across a restart', () {
    test('everything answered in setup is still there', () async {
      // One store, two containers: the second stands in for a relaunch.
      final store = InMemorySettingsStore();

      final firstRun = containerWith(store);
      final controller = firstRun.read(userSettingsProvider.notifier);
      await controller.setName('Millie');
      await controller.selectHemisphere(Hemisphere.southern);
      await controller.markLocationIntroSeen();
      await controller.setFeatures({FeatureId.yoga, FeatureId.garden});
      await controller.completeOnboarding();

      final secondRun = containerWith(store);
      final settings = secondRun.read(userSettingsProvider);

      expect(settings.name, 'Millie');
      expect(settings.hemisphere, Hemisphere.southern);
      expect(settings.features, {FeatureId.yoga, FeatureId.garden});
      expect(settings.onboardingCompleted, isTrue);
      expect(secondRun.read(onboardingStageProvider), OnboardingStage.complete);
      expect(secondRun.read(almanacTitleProvider), "Millie's Almanac");
    });

    test('a skipped name survives as a skipped name', () async {
      final store = InMemorySettingsStore();

      final firstRun = containerWith(store);
      final controller = firstRun.read(userSettingsProvider.notifier);
      await controller.skipName();
      await controller.selectHemisphere(Hemisphere.northern);
      await controller.markLocationIntroSeen();
      await controller.completeOnboarding();

      final secondRun = containerWith(store);

      expect(secondRun.read(userSettingsProvider).name, isNull);
      expect(secondRun.read(almanacTitleProvider), 'Your Almanac');
      // And they are not asked again.
      expect(secondRun.read(onboardingStageProvider), OnboardingStage.complete);
    });
  });

  group('the stage machine', () {
    test('walks the four questions in order', () async {
      final store = InMemorySettingsStore();
      final container = containerWith(store);
      final controller = container.read(userSettingsProvider.notifier);

      expect(container.read(onboardingStageProvider), OnboardingStage.name);

      await controller.skipName();
      expect(
        container.read(onboardingStageProvider),
        OnboardingStage.hemisphere,
      );

      await controller.selectHemisphere(Hemisphere.northern);
      expect(container.read(onboardingStageProvider), OnboardingStage.location);

      await controller.markLocationIntroSeen();
      expect(container.read(onboardingStageProvider), OnboardingStage.features);

      await controller.completeOnboarding();
      expect(container.read(onboardingStageProvider), OnboardingStage.complete);
    });

    test('completion wins, so a settled user is never sent back', () {
      // Somebody who set the app up before the name question existed.
      final container = containerWith(
        InMemorySettingsStore(
          const UserSettings(
            hemisphere: Hemisphere.northern,
            locationIntroSeen: true,
            onboardingCompleted: true,
          ),
        ),
      );

      expect(container.read(userSettingsProvider).nameAsked, isFalse);
      expect(container.read(onboardingStageProvider), OnboardingStage.complete);
    });
  });
}
