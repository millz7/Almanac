import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

void main() {
  setUpAll(useTimeZoneDatabase);

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    Set<FeatureId> features = const {},
    Size surface = const Size(400, 900),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = surface * 2;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

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
    return container;
  }

  AlmanacNavigationBar barOf(WidgetTester tester) =>
      tester.widget<AlmanacNavigationBar>(find.byType(AlmanacNavigationBar));

  List<String> destinationsOf(WidgetTester tester) =>
      barOf(tester).destinations.map((feature) => feature.name).toList();

  group('the bar is built from what the user chose', () {
    testWidgets('nothing chosen leaves just the Environment', (tester) async {
      await pumpApp(tester);

      expect(destinationsOf(tester), ['Environment']);
    });

    testWidgets('one chosen feature becomes one more tab', (tester) async {
      await pumpApp(tester, features: {FeatureId.yoga});

      expect(destinationsOf(tester), ['Environment', 'Yoga']);
    });

    testWidgets('several become several, in registry order', (tester) async {
      await pumpApp(
        tester,
        features: {FeatureId.natureLog, FeatureId.meditation, FeatureId.cycle},
      );

      expect(destinationsOf(tester), [
        'Environment',
        'Meditation',
        'Cycle',
        'Nature Log',
      ]);
    });

    testWidgets('everything chosen gives all eight destinations', (
      tester,
    ) async {
      await pumpApp(
        tester,
        features: FeatureRegistry.optional.map((feature) => feature.id).toSet(),
      );

      expect(destinationsOf(tester), [
        'Environment',
        'Meditation',
        'Yoga',
        'Chakras',
        'Cycle',
        'Cookbook',
        'Garden',
        'Nature Log',
      ]);
    });

    testWidgets('what was not chosen is not in the bar', (tester) async {
      await pumpApp(tester, features: {FeatureId.yoga});

      expect(destinationsOf(tester), isNot(contains('Meditation')));
      expect(destinationsOf(tester), isNot(contains('Cookbook')));
    });

    testWidgets('the Environment is always first and always present', (
      tester,
    ) async {
      for (final features in [
        <FeatureId>{},
        {FeatureId.garden},
        FeatureRegistry.optional.map((feature) => feature.id).toSet(),
      ]) {
        await pumpApp(tester, features: features);
        expect(destinationsOf(tester).first, 'Environment');
      }
    });
  });

  group('there is no hub of any kind', () {
    testWidgets('no More, Explore, Navigation or Other destination', (
      tester,
    ) async {
      await pumpApp(
        tester,
        features: FeatureRegistry.optional.map((feature) => feature.id).toSet(),
      );

      final names = destinationsOf(tester);
      for (final forbidden in [
        'More',
        'Explore',
        'Navigation',
        'Other',
        'Settings',
        'Features',
      ]) {
        expect(
          names,
          isNot(contains(forbidden)),
          reason: 'a "$forbidden" destination must never exist',
        );
        expect(find.byIcon(Icons.more_horiz), findsNothing);
      }
    });

    testWidgets('every chosen feature is in the bar, none folded away', (
      tester,
    ) async {
      final everything = FeatureRegistry.optional
          .map((feature) => feature.id)
          .toSet();
      await pumpApp(tester, features: everything);

      expect(barOf(tester).destinations.length, everything.length + 1);
    });
  });

  group('each destination navigates independently', () {
    testWidgets('tapping a feature opens that feature', (tester) async {
      await pumpApp(
        tester,
        features: {FeatureId.meditation, FeatureId.cookbook},
      );

      await tester.tap(find.bySemanticsLabel('Cookbook'));
      await tester.pumpAndSettle();

      expect(find.text('Coming soon'), findsOneWidget);
      expect(barOf(tester).selectedIndex, 2);

      await tester.tap(find.bySemanticsLabel('Meditation'));
      await tester.pumpAndSettle();

      expect(barOf(tester).selectedIndex, 1);
    });

    testWidgets('each one shows its own name and message', (tester) async {
      await pumpApp(tester, features: {FeatureId.garden, FeatureId.chakras});

      for (final feature in [
        FeatureRegistry.byId(FeatureId.garden),
        FeatureRegistry.byId(FeatureId.chakras),
      ]) {
        await tester.tap(find.bySemanticsLabel(feature.name));
        await tester.pumpAndSettle();

        // Its own heading, and its own sentence — obvious which feature
        // this is, without pretending to be the feature.
        expect(find.text(feature.name), findsWidgets);
        expect(find.text(feature.placeholderMessage), findsOneWidget);
      }
    });

    testWidgets('returning to the Environment brings back the real screen', (
      tester,
    ) async {
      await pumpApp(tester, features: {FeatureId.yoga});

      await tester.tap(find.bySemanticsLabel('Yoga'));
      await tester.pumpAndSettle();
      expect(find.text('Coming soon'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Environment'));
      await tester.pumpAndSettle();

      expect(find.text('Tuesday 15 July'), findsOneWidget);
      expect(find.text('Coming soon'), findsNothing);
    });
  });

  group('changing the Almanac while using it', () {
    testWidgets('removing the feature you are standing in returns you home', (
      tester,
    ) async {
      final container = await pumpApp(tester, features: {FeatureId.yoga});

      await tester.tap(find.bySemanticsLabel('Yoga'));
      await tester.pumpAndSettle();
      expect(find.text('Coming soon'), findsOneWidget);

      await container
          .read(userSettingsProvider.notifier)
          .setFeatureChosen(FeatureId.yoga, false);
      await tester.pumpAndSettle();

      // Not stranded on a screen the navigation can no longer reach.
      expect(destinationsOf(tester), ['Environment']);
      expect(find.text('Tuesday 15 July'), findsOneWidget);
      expect(barOf(tester).selectedIndex, 0);
    });

    testWidgets('removing a feature you are not in leaves you where you are', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        features: {FeatureId.yoga, FeatureId.garden},
      );

      await tester.tap(find.bySemanticsLabel('Garden'));
      await tester.pumpAndSettle();

      await container
          .read(userSettingsProvider.notifier)
          .setFeatureChosen(FeatureId.yoga, false);
      await tester.pumpAndSettle();

      expect(destinationsOf(tester), ['Environment', 'Garden']);
      expect(barOf(tester).selectedIndex, 1);
    });

    testWidgets('adding a feature makes it reachable straight away', (
      tester,
    ) async {
      final container = await pumpApp(tester);

      expect(destinationsOf(tester), ['Environment']);

      await container
          .read(userSettingsProvider.notifier)
          .setFeatureChosen(FeatureId.chakras, true);
      await tester.pumpAndSettle();

      expect(destinationsOf(tester), ['Environment', 'Chakras']);

      // No restart needed: the route was always registered.
      await tester.tap(find.bySemanticsLabel('Chakras'));
      await tester.pumpAndSettle();
      expect(find.text('Coming soon'), findsOneWidget);
    });

    testWidgets('a feature switched off and on again still works', (
      tester,
    ) async {
      final container = await pumpApp(tester, features: {FeatureId.cycle});
      final settings = container.read(userSettingsProvider.notifier);

      await tester.tap(find.bySemanticsLabel('Cycle'));
      await tester.pumpAndSettle();

      await settings.setFeatureChosen(FeatureId.cycle, false);
      await tester.pumpAndSettle();
      expect(destinationsOf(tester), ['Environment']);

      await settings.setFeatureChosen(FeatureId.cycle, true);
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Cycle'));
      await tester.pumpAndSettle();
      expect(find.text('Coming soon'), findsOneWidget);
    });
  });

  group('labels and accessibility', () {
    testWidgets('a short Almanac shows the full names', (tester) async {
      await pumpApp(
        tester,
        features: {FeatureId.yoga},
        surface: const Size(400, 900),
      );

      expect(find.text('Environment'), findsWidgets);
      expect(find.text('Yoga'), findsWidgets);
    });

    testWidgets('a full Almanac shows the agreed short names', (tester) async {
      // Wide enough that all eight fit at once; the narrow case is the
      // scrolling one below.
      await pumpApp(
        tester,
        surface: const Size(760, 900),
        features: FeatureRegistry.optional.map((feature) => feature.id).toSet(),
      );

      // The deliberate words, not truncations.
      for (final short in ['Env', 'Med', 'Chak', 'Cook', 'Nature']) {
        expect(
          find.text(short),
          findsWidgets,
          reason: '"$short" should be in the bar',
        );
      }
      // And nothing anywhere ends in an ellipsis.
      expect(find.textContaining('…'), findsNothing);
      expect(find.textContaining('...'), findsNothing);
    });

    testWidgets('the accessibility label is the full name even when short', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpApp(
        tester,
        surface: const Size(760, 900),
        features: FeatureRegistry.optional.map((feature) => feature.id).toSet(),
      );

      // "Chak" on screen; "Chakras" to a screen reader.
      expect(find.text('Chak'), findsOneWidget);
      expect(find.text('Chakras'), findsNothing);
      for (final feature in FeatureRegistry.all) {
        expect(
          find.bySemanticsLabel(feature.name),
          findsOneWidget,
          reason: '${feature.name} must be announced by its full name',
        );
      }

      handle.dispose();
    });

    testWidgets('every destination stays comfortably tappable', (tester) async {
      await pumpApp(
        tester,
        surface: const Size(760, 900),
        features: FeatureRegistry.optional.map((feature) => feature.id).toSet(),
      );

      for (final feature in FeatureRegistry.all) {
        final size = tester.getSize(find.bySemanticsLabel(feature.name));
        expect(
          size.width,
          greaterThanOrEqualTo(48),
          reason: '${feature.name} is too narrow to tap',
        );
        expect(
          size.height,
          greaterThanOrEqualTo(48),
          reason: '${feature.name} is too short to tap',
        );
      }
    });

    testWidgets('a bar too narrow for eight scrolls rather than shrinking', (
      tester,
    ) async {
      await pumpApp(
        tester,
        surface: const Size(320, 800),
        features: FeatureRegistry.optional.map((feature) => feature.id).toSet(),
      );

      // The bar has become a strip that scrolls...
      final strip = find.descendant(
        of: find.byType(AlmanacNavigationBar),
        matching: find.byType(Scrollable),
      );
      expect(strip, findsOneWidget);

      // ...and still holds every destination, at full size, with nothing
      // folded into an overflow menu.
      expect(barOf(tester).destinations.length, 8);
      for (final feature in FeatureRegistry.all) {
        await tester.scrollUntilVisible(
          find.bySemanticsLabel(feature.name),
          80,
          scrollable: strip,
        );
        final size = tester.getSize(find.bySemanticsLabel(feature.name));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('doubling the text size does not break the bar', (
      tester,
    ) async {
      await pumpApp(
        tester,
        textScale: 2,
        features: FeatureRegistry.optional.map((feature) => feature.id).toSet(),
      );

      // An overflow would be reported as an exception during layout.
      expect(tester.takeException(), isNull);
      expect(find.textContaining('…'), findsNothing);
      // Everything is still reachable.
      expect(barOf(tester).destinations.length, 8);
    });
  });
}
