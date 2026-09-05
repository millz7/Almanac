import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/core/settings/settings_store.dart';
import 'package:almanac/core/settings/user_settings.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

void main() {
  setUpAll(useTimeZoneDatabase);

  /// Everything answered except the last question.
  UserSettings atFeatureQuestion() => const UserSettings(
    nameAsked: true,
    hemisphere: Hemisphere.northern,
    locationIntroSeen: true,
  );

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    SettingsStore? store,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(840, 5200);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final container = ProviderContainer(
      overrides: environmentOverrides(
        settingsStore: store ?? InMemorySettingsStore(atFeatureQuestion()),
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> choose(WidgetTester tester, String name) async {
    final card = find.widgetWithText(ChoiceCard, name);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
  }

  Future<void> continueOn(WidgetTester tester) async {
    final button = find.byType(ElevatedButton);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  final question = find.text('What would you like in your Almanac?');

  group('the question', () {
    testWidgets('is the last step of setup', (tester) async {
      await pumpApp(tester);

      expect(question, findsOneWidget);
      expect(
        find.textContaining('you can add or remove them whenever you like'),
        findsOneWidget,
      );
    });

    testWidgets('offers the seven choosable features and not the eighth', (
      tester,
    ) async {
      await pumpApp(tester);

      for (final feature in FeatureRegistry.optional) {
        expect(
          find.widgetWithText(ChoiceCard, feature.name),
          findsOneWidget,
          reason: '${feature.name} should be offered',
        );
      }
      // The Environment is not a choice.
      expect(find.widgetWithText(ChoiceCard, 'Environment'), findsNothing);
      expect(
        find.textContaining('The Environment — the season, sky, sun and moon'),
        findsOneWidget,
      );
    });

    testWidgets('wears the season like the rest of onboarding', (tester) async {
      await pumpApp(tester);

      // Mid-July in the north.
      expect(tester.element(question).palette.name, 'Summer Day');
    });
  });

  group('choosing', () {
    testWidgets('nothing is allowed, and lands in the app', (tester) async {
      final store = InMemorySettingsStore(atFeatureQuestion());
      final container = await pumpApp(tester, store: store);

      // The button says what it will do rather than pretending a choice
      // was made.
      expect(
        find.widgetWithText(ElevatedButton, 'Just the Environment'),
        findsOneWidget,
      );
      await continueOn(tester);

      expect(store.read().features, isEmpty);
      expect(store.read().onboardingCompleted, isTrue);
      expect(container.read(userSettingsProvider).onboardingCompleted, isTrue);
      expect(find.byType(AlmanacNavigationBar), findsOneWidget);
    });

    testWidgets('one is stored and becomes a tab', (tester) async {
      final store = InMemorySettingsStore(atFeatureQuestion());
      await pumpApp(tester, store: store);

      await choose(tester, 'Yoga');
      expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);
      await continueOn(tester);

      expect(store.read().features, {FeatureId.yoga});

      final bar = tester.widget<AlmanacNavigationBar>(
        find.byType(AlmanacNavigationBar),
      );
      expect(bar.destinations.map((feature) => feature.name), [
        'Environment',
        'Yoga',
      ]);
    });

    testWidgets('several are stored, in registry order', (tester) async {
      final store = InMemorySettingsStore(atFeatureQuestion());
      await pumpApp(tester, store: store);

      // Picked out of order on purpose.
      await choose(tester, 'Nature Log');
      await choose(tester, 'Meditation');
      await choose(tester, 'Cycle');
      await continueOn(tester);

      expect(store.read().features, {
        FeatureId.meditation,
        FeatureId.cycle,
        FeatureId.natureLog,
      });

      final bar = tester.widget<AlmanacNavigationBar>(
        find.byType(AlmanacNavigationBar),
      );
      expect(bar.destinations.map((feature) => feature.name).toList(), [
        'Environment',
        'Meditation',
        'Cycle',
        'Nature Log',
      ]);
    });

    testWidgets('all seven are stored', (tester) async {
      final store = InMemorySettingsStore(atFeatureQuestion());
      await pumpApp(tester, store: store);

      for (final feature in FeatureRegistry.optional) {
        await choose(tester, feature.name);
      }
      await continueOn(tester);

      expect(
        store.read().features,
        FeatureRegistry.optional.map((feature) => feature.id).toSet(),
      );

      final bar = tester.widget<AlmanacNavigationBar>(
        find.byType(AlmanacNavigationBar),
      );
      expect(bar.destinations.length, 8);
    });

    testWidgets('a choice can be un-chosen before continuing', (tester) async {
      final store = InMemorySettingsStore(atFeatureQuestion());
      await pumpApp(tester, store: store);

      await choose(tester, 'Yoga');
      expect(
        tester
            .widget<ChoiceCard>(find.widgetWithText(ChoiceCard, 'Yoga'))
            .selected,
        isTrue,
      );

      await choose(tester, 'Yoga');
      expect(
        tester
            .widget<ChoiceCard>(find.widgetWithText(ChoiceCard, 'Yoga'))
            .selected,
        isFalse,
      );

      await continueOn(tester);
      expect(store.read().features, isEmpty);
    });

    testWidgets('nothing is written until Continue', (tester) async {
      final store = InMemorySettingsStore(atFeatureQuestion());
      await pumpApp(tester, store: store);

      await choose(tester, 'Yoga');
      await choose(tester, 'Garden');

      // Six ticks should not be six writes.
      expect(store.read().features, isEmpty);
      expect(store.read().onboardingCompleted, isFalse);
    });
  });

  group('accessibility', () {
    testWidgets('every option is a labelled, selectable button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester);

      for (final feature in FeatureRegistry.optional) {
        expect(
          find.bySemanticsLabel(RegExp(feature.name)),
          findsOneWidget,
          reason: '${feature.name} must be readable by a screen reader',
        );
      }
      handle.dispose();
    });

    testWidgets('every option clears the minimum touch target', (tester) async {
      await pumpApp(tester);

      for (final feature in FeatureRegistry.optional) {
        expect(
          tester.getSize(find.widgetWithText(ChoiceCard, feature.name)).height,
          greaterThanOrEqualTo(AppDimens.minTouchTarget),
        );
      }
    });

    testWidgets('doubling the text size does not break the question', (
      tester,
    ) async {
      await pumpApp(tester, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(question, findsOneWidget);
      expect(find.widgetWithText(ChoiceCard, 'Nature Log'), findsOneWidget);
    });
  });
}
