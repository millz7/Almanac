import 'package:almanac/app/almanac_button.dart';
import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/features/chakras/application/chakra_reflections.dart';
import 'package:almanac/features/chakras/domain/chakras.dart';
import 'package:almanac/features/chakras/presentation/widgets/chakra_journey.dart';
import 'package:almanac/features/chakras/presentation/widgets/chakra_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

void main() {
  setUpAll(useTimeZoneDatabase);

  final reflect = find.widgetWithText(ElevatedButton, 'Reflect');
  final save = find.widgetWithText(ElevatedButton, 'Save reflection');
  final notNow = find.widgetWithText(TextButton, 'Not now');
  final backToTheSeven = find.widgetWithText(TextButton, 'Back to the seven');
  final field = find.byType(TextField);

  /// A tab in the navigation bar, by its accessibility label. Scoped to
  /// the bar because the Environment also links onward to the features.
  Finder navTab(String name) => find.descendant(
    of: find.byType(AlmanacNavigationBar),
    matching: find.bySemanticsLabel(name),
  );

  /// One chakra's row on the overview.
  Finder stop(Chakra chakra) => find.bySemanticsLabel(chakra.semanticLabel);

  /// Opens Chakras through the real navigation.
  Future<ProviderContainer> openChakras(
    WidgetTester tester, {
    double textScale = 1,
    bool reducedMotion = false,
    Size surface = const Size(420, 1800),
    Set<FeatureId> features = const {FeatureId.chakras},
  }) async {
    tester.view.physicalSize = surface * 2;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    if (reducedMotion) {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
    }

    final container = ProviderContainer(
      overrides: environmentOverrides(features: features),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(navTab('Chakras'));
    await tester.pumpAndSettle();
    return container;
  }

  /// Opens one chakra from the overview.
  Future<void> open(WidgetTester tester, Chakra chakra) async {
    await tester.ensureVisible(stop(chakra));
    await tester.pumpAndSettle();
    await tester.tap(stop(chakra));
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, Finder control) async {
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  group('the seven, down the body', () {
    testWidgets('all of them are there, with what they carry', (tester) async {
      await openChakras(tester);

      for (final chakra in ChakraCatalogue.all) {
        expect(find.text(chakra.name), findsOneWidget, reason: chakra.name);
        expect(find.text(chakra.associationPhrase), findsOneWidget);
      }
      expect(find.byType(ChakraJourney), findsOneWidget);
    });

    testWidgets('it says whose tradition this is before anything else', (
      tester,
    ) async {
      await openChakras(tester);

      expect(find.text(ChakraCatalogue.introduction), findsOneWidget);
      expect(find.textContaining('In some traditions'), findsOneWidget);
    });

    testWidgets('they run from the crown at the top to the root at the base', (
      tester,
    ) async {
      await openChakras(tester);

      // It is a body, so the head is at the top of it.
      final tops = [
        for (final chakra in ChakraCatalogue.all.reversed)
          tester.getTopLeft(find.text(chakra.name)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(
        tester.getTopLeft(find.text('Crown')).dy,
        lessThan(tester.getTopLeft(find.text('Root')).dy),
      );
    });

    testWidgets('nothing is animating once the seven have arrived', (
      tester,
    ) async {
      await openChakras(tester);

      // A one-shot arrival, not a permanent pulse: after it lands there
      // is no ticker left in the feature at all.
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('the Almanac is still reachable from here', (tester) async {
      await openChakras(tester);

      expect(find.byType(AlmanacButton), findsOneWidget);
    });
  });

  group('opening one', () {
    testWidgets('each row opens its own chakra', (tester) async {
      await openChakras(tester);

      for (final chakra in ChakraCatalogue.all) {
        await open(tester, chakra);

        expect(find.text(chakra.sanskrit), findsOneWidget);
        expect(find.text(chakra.traditionSentence), findsOneWidget);
        expect(find.text(chakra.prompt), findsOneWidget);
        // Nobody else's.
        for (final other in ChakraCatalogue.all) {
          if (other == chakra) continue;
          expect(find.text(other.sanskrit), findsNothing);
          expect(find.text(other.prompt), findsNothing);
        }

        await press(tester, backToTheSeven);
      }
    });

    testWidgets('it names the colour and the place in words', (tester) async {
      await openChakras(tester);
      await open(tester, ChakraCatalogue.heart);

      // The hue is decoration; the words are the information.
      expect(
        find.text(
          'Traditionally placed at the centre of the chest, and shown '
          'as green.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('it offers the prompt and a way to answer it', (tester) async {
      await openChakras(tester);
      await open(tester, ChakraCatalogue.throat);

      expect(find.text('A reflective prompt'), findsOneWidget);
      expect(find.text('What wants to be expressed?'), findsOneWidget);
      expect(reflect, findsOneWidget);
    });

    testWidgets('the symbol is drawn, and it is only ever a decoration', (
      tester,
    ) async {
      await openChakras(tester);
      await open(tester, ChakraCatalogue.root);

      expect(find.byType(ChakraSymbol), findsOneWidget);
      final symbol = tester.widget<ChakraSymbol>(find.byType(ChakraSymbol));
      expect(symbol.chakra, ChakraCatalogue.root);
      // Everything it carries is written beside it in real text.
      expect(
        find.descendant(
          of: find.byType(ChakraSymbol),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });

    testWidgets('going back returns to all seven', (tester) async {
      await openChakras(tester);
      await open(tester, ChakraCatalogue.sacral);
      await press(tester, backToTheSeven);

      expect(find.byType(ChakraJourney), findsOneWidget);
      expect(find.text('Svadhisthana'), findsNothing);
    });
  });

  group('reflecting', () {
    testWidgets('the prompt comes with the chakra it belongs to', (
      tester,
    ) async {
      await openChakras(tester);
      await open(tester, ChakraCatalogue.solarPlexus);
      await press(tester, reflect);

      expect(find.text('Solar Plexus'), findsWidgets);
      expect(
        find.text('Where could you trust yourself a little more?'),
        findsOneWidget,
      );
      expect(field, findsOneWidget);
      expect(save, findsOneWidget);
      expect(notNow, findsOneWidget);
    });

    testWidgets('the field says what it is and what to do with it', (
      tester,
    ) async {
      await openChakras(tester);
      await open(tester, ChakraCatalogue.root);
      await press(tester, reflect);

      expect(find.text('Your reflection'), findsOneWidget);
      expect(find.text('Write anything that comes to mind.'), findsOneWidget);
      // And it is honest about where the words go.
      expect(find.text(ChakraCatalogue.reflectionNote), findsOneWidget);
      expect(find.textContaining('stays on this device'), findsOneWidget);
    });

    testWidgets('writing something keeps it against that chakra', (
      tester,
    ) async {
      final container = await openChakras(tester);
      await open(tester, ChakraCatalogue.heart);
      await press(tester, reflect);

      await tester.enterText(field, 'The garden, and whoever planted it.');
      await press(tester, save);

      expect(find.text('What you wrote'), findsOneWidget);
      expect(find.text('The garden, and whoever planted it.'), findsOneWidget);
      expect(
        container.read(chakraReflectionsProvider)[ChakraId.heart],
        'The garden, and whoever planted it.',
      );
    });

    testWidgets('saving an empty field is allowed, and keeps nothing', (
      tester,
    ) async {
      final container = await openChakras(tester);
      await open(tester, ChakraCatalogue.crown);
      await press(tester, reflect);

      // Writing is optional: pressing save without typing is a normal
      // thing to do, not an error.
      await press(tester, save);

      expect(find.text('What you wrote'), findsNothing);
      expect(container.read(chakraReflectionsProvider), isEmpty);
      expect(find.text('Sahasrara'), findsOneWidget);
    });

    testWidgets('whitespace alone is nothing at all', (tester) async {
      final container = await openChakras(tester);
      await open(tester, ChakraCatalogue.crown);
      await press(tester, reflect);

      await tester.enterText(field, '   \n  ');
      await press(tester, save);

      expect(container.read(chakraReflectionsProvider), isEmpty);
    });

    testWidgets('"Not now" writes nothing down', (tester) async {
      final container = await openChakras(tester);
      await open(tester, ChakraCatalogue.throat);
      await press(tester, reflect);

      await tester.enterText(field, 'Something half-formed.');
      await press(tester, notNow);

      expect(container.read(chakraReflectionsProvider), isEmpty);
      expect(find.text('What you wrote'), findsNothing);
      expect(find.text('Vishuddha'), findsOneWidget);
    });

    testWidgets('a reflection can be returned to and rewritten', (
      tester,
    ) async {
      final container = await openChakras(tester);
      await open(tester, ChakraCatalogue.root);
      await press(tester, reflect);
      await tester.enterText(field, 'Cold water.');
      await press(tester, save);

      await press(tester, reflect);
      expect(tester.widget<TextField>(field).controller?.text, 'Cold water.');

      await tester.enterText(field, 'Cold water, and bread.');
      await press(tester, save);

      expect(
        container.read(chakraReflectionsProvider)[ChakraId.root],
        'Cold water, and bread.',
      );
    });

    testWidgets('each chakra keeps its own', (tester) async {
      final container = await openChakras(tester);

      await open(tester, ChakraCatalogue.root);
      await press(tester, reflect);
      await tester.enterText(field, 'The ground.');
      await press(tester, save);
      await press(tester, backToTheSeven);

      await open(tester, ChakraCatalogue.crown);
      expect(find.text('What you wrote'), findsNothing);
      await press(tester, reflect);
      await tester.enterText(field, 'The weather.');
      await press(tester, save);

      expect(container.read(chakraReflectionsProvider), {
        ChakraId.root: 'The ground.',
        ChakraId.crown: 'The weather.',
      });
    });

    testWidgets('it survives stepping away to another part of the Almanac', (
      tester,
    ) async {
      await openChakras(
        tester,
        features: {FeatureId.chakras, FeatureId.garden},
      );

      await open(tester, ChakraCatalogue.heart);
      await press(tester, reflect);
      await tester.enterText(field, 'A half-written thought.');
      await press(tester, save);

      await tester.tap(navTab('Garden'));
      await tester.pumpAndSettle();
      await tester.tap(navTab('Chakras'));
      await tester.pumpAndSettle();

      // Still on the same chakra — the shell keeps each tab where it was
      // — and still holding what was written there.
      expect(find.text('Anahata'), findsOneWidget);
      expect(find.text('What you wrote'), findsOneWidget);
      expect(find.text('A half-written thought.'), findsOneWidget);
    });

    testWidgets('nothing is carried into a fresh start', (tester) async {
      // The whole of the storage: a provider, and no further. A new
      // container is a new launch, and it begins with nothing.
      final container = ProviderContainer(overrides: environmentOverrides());
      addTearDown(container.dispose);

      expect(container.read(chakraReflectionsProvider), isEmpty);
    });
  });

  group('leaving', () {
    testWidgets('nothing is left running', (tester) async {
      await openChakras(
        tester,
        features: {FeatureId.chakras, FeatureId.garden},
      );
      await open(tester, ChakraCatalogue.thirdEye);

      await tester.tap(navTab('Garden'));
      await tester.pumpAndSettle();

      expect(tester.binding.transientCallbackCount, 0);
      expect(find.byType(ChakraSymbol), findsNothing);
    });

    testWidgets('backgrounding the app leaves nothing behind either', (
      tester,
    ) async {
      await openChakras(tester);
      await open(tester, ChakraCatalogue.heart);

      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // There is no session here to interrupt — which is the point: the
      // screen simply stays where it was, with nothing ticking.
      expect(find.text('Anahata'), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('reduced motion', () {
    testWidgets('the seven are simply already there', (tester) async {
      await openChakras(tester, reducedMotion: true);

      for (final chakra in ChakraCatalogue.all) {
        expect(find.text(chakra.name), findsOneWidget);
      }
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('a chakra opens fully in focus, and everything works', (
      tester,
    ) async {
      final container = await openChakras(tester, reducedMotion: true);
      await open(tester, ChakraCatalogue.sacral);

      // Selected, and at rest: no animation ever ran.
      final symbol = tester.widget<ChakraSymbol>(find.byType(ChakraSymbol));
      expect(symbol.focus, 1);
      expect(tester.binding.transientCallbackCount, 0);

      await press(tester, reflect);
      await tester.enterText(field, 'Still works.');
      await press(tester, save);

      expect(
        container.read(chakraReflectionsProvider)[ChakraId.sacral],
        'Still works.',
      );
    });
  });

  group('accessibility', () {
    testWidgets('each chakra says what it is, without mentioning colour', (
      tester,
    ) async {
      await openChakras(tester);

      for (final chakra in ChakraCatalogue.all) {
        expect(stop(chakra), findsOneWidget, reason: chakra.name);
      }
      expect(
        find.bySemanticsLabel(
          'Root chakra. Traditionally associated with grounding, stability '
          'and belonging.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the drawn body line says nothing', (tester) async {
      await openChakras(tester);

      // The rows carry the words; the artwork behind them is excluded so
      // a screen reader is not asked to interpret a painting.
      final journey = find.byType(ChakraJourney);
      expect(
        find.descendant(of: journey, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
    });

    testWidgets('every control is a comfortable target', (tester) async {
      await openChakras(tester);

      for (final chakra in ChakraCatalogue.all) {
        expect(
          tester.getSize(stop(chakra)).height,
          greaterThanOrEqualTo(48),
          reason: chakra.name,
        );
      }

      await open(tester, ChakraCatalogue.root);
      for (final control in [reflect, backToTheSeven]) {
        expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
      }

      await press(tester, reflect);
      for (final control in [save, notNow]) {
        expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('doubling the text size breaks nothing', (tester) async {
      await openChakras(tester, textScale: 2);

      expect(find.text('Root'), findsOneWidget);
      await open(tester, ChakraCatalogue.root);
      expect(find.text('Muladhara'), findsOneWidget);

      await press(tester, reflect);
      expect(find.text('Your reflection'), findsOneWidget);
      expect(save, findsOneWidget);
    });
  });
}
