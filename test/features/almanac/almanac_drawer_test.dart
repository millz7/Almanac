import 'package:almanac/app/almanac_button.dart';
import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/app/theme/theme_providers.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/core/settings/settings_store.dart';
import 'package:almanac/core/settings/user_settings.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// A store whose writes always fail, for the error path.
class _FailingSettingsStore implements SettingsStore {
  const _FailingSettingsStore();

  @override
  UserSettings read() => const UserSettings(
    nameAsked: true,
    hemisphere: Hemisphere.northern,
    locationIntroSeen: true,
    onboardingCompleted: true,
  );

  @override
  Future<void> write(UserSettings settings) async =>
      throw StateError('disk is full');
}

void main() {
  setUpAll(useTimeZoneDatabase);

  final northernChoice = find.widgetWithText(ChoiceCard, 'Northern Hemisphere');
  final southernChoice = find.widgetWithText(ChoiceCard, 'Southern Hemisphere');

  /// Launches the app and opens the Almanac the way a user would.
  Future<ProviderContainer> openAlmanac(
    WidgetTester tester, {
    List<Override>? overrides,
    Set<FeatureId> features = const {},
    String? name,
  }) async {
    // Tall enough that the whole panel is laid out at once: it is a
    // ListView, so a section below the fold would not be built at all.
    tester.view.physicalSize = const Size(900, 6000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides:
          overrides ?? environmentOverrides(features: features, name: name),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AlmanacButton));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tapControl(WidgetTester tester, Finder finder) async {
    // Settle first: a control whose label depends on what was just typed
    // may not have been rebuilt yet.
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('opening it', () {
    testWidgets('the top-right control opens the panel', (tester) async {
      await openAlmanac(tester);

      expect(find.text('Your Almanac'), findsWidgets);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Location & Region'), findsOneWidget);
      expect(find.text('Your Almanac'), findsWidgets);
    });

    testWidgets('it is titled with the name they gave', (tester) async {
      await openAlmanac(tester, name: 'Millie');

      expect(find.text("Millie's Almanac"), findsOneWidget);
      expect(find.text('Your Almanac'), findsOneWidget); // the section
    });

    testWidgets('a skipped name still gives a proper title', (tester) async {
      await openAlmanac(tester);

      // Not a blank, and not an apology for a missing value.
      expect(find.textContaining("'s Almanac"), findsNothing);
      expect(find.text('Your Almanac'), findsWidgets);
    });

    testWidgets('it is reachable from a feature screen too', (tester) async {
      await openAlmanac(tester, features: {FeatureId.yoga});

      // Close it, go to a feature, and open it again from there.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Yoga'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AlmanacButton));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('it is not a tab', (tester) async {
      await openAlmanac(tester, features: {FeatureId.yoga});

      final bar = tester.widget<AlmanacNavigationBar>(
        find.byType(AlmanacNavigationBar),
      );
      final names = bar.destinations.map((feature) => feature.name);
      expect(names, isNot(contains('Settings')));
      expect(names, isNot(contains('Almanac')));
    });

    testWidgets('opening it never asks for location', (tester) async {
      final service = FakeLocationService();
      await openAlmanac(
        tester,
        overrides: environmentOverrides(locationService: service),
      );

      // Looking at your own preferences is not consent to be located.
      expect(service.requestCount, 0);
    });
  });

  group('the name', () {
    testWidgets('can be set from the panel and retitles it', (tester) async {
      final store = InMemorySettingsStore(
        const UserSettings(
          nameAsked: true,
          hemisphere: Hemisphere.northern,
          locationIntroSeen: true,
          onboardingCompleted: true,
        ),
      );
      await openAlmanac(
        tester,
        overrides: environmentOverrides(settingsStore: store),
      );

      await tester.enterText(find.byType(TextField), 'Millie');
      await tapControl(tester, find.text('Save name'));

      expect(store.read().name, 'Millie');
      expect(find.text("Millie's Almanac"), findsOneWidget);
    });

    testWidgets('can be changed', (tester) async {
      final container = await openAlmanac(tester, name: 'Millie');

      await tester.enterText(find.byType(TextField), 'Sam');
      await tapControl(tester, find.text('Save name'));

      expect(container.read(userSettingsProvider).name, 'Sam');
      expect(find.text("Sam's Almanac"), findsOneWidget);
    });

    testWidgets('can be removed, going back to Your Almanac', (tester) async {
      final container = await openAlmanac(tester, name: 'Millie');

      await tester.enterText(find.byType(TextField), '');
      await tapControl(tester, find.text('Remove name'));

      expect(container.read(userSettingsProvider).name, isNull);
      expect(find.text("Millie's Almanac"), findsNothing);
    });

    testWidgets('a failed save says so rather than pretending', (tester) async {
      await openAlmanac(
        tester,
        overrides: environmentOverrides(
          settingsStore: const _FailingSettingsStore(),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Millie');
      await tapControl(tester, find.text('Save name'));

      expect(
        find.text('That could not be saved on this device. Please try again.'),
        findsWidgets,
      );
      expect(find.text("Millie's Almanac"), findsNothing);
    });
  });

  group('the hemisphere', () {
    testWidgets('can be changed, and the app changes season with it', (
      tester,
    ) async {
      final container = await openAlmanac(tester);

      expect(
        container.read(userSettingsProvider).hemisphere,
        Hemisphere.northern,
      );

      await tapControl(tester, southernChoice);

      expect(
        container.read(userSettingsProvider).hemisphere,
        Hemisphere.southern,
      );
      // Mid-July: the whole app is now in winter.
      expect(container.read(activePaletteProvider).name, 'Winter Day');
    });

    testWidgets('the current choice is shown as chosen', (tester) async {
      await openAlmanac(tester);

      expect(tester.widget<ChoiceCard>(northernChoice).selected, isTrue);
      expect(tester.widget<ChoiceCard>(southernChoice).selected, isFalse);
    });

    testWidgets('a location-derived hemisphere does not overwrite it', (
      tester,
    ) async {
      final container = await openAlmanac(
        tester,
        overrides: environmentOverrides(
          hemisphere: Hemisphere.northern,
          locationState: const LocationAvailable(TestLocations.wellington),
        ),
      );

      // The position wins for calculations...
      expect(
        container.read(resolvedHemisphereProvider).hemisphere,
        Hemisphere.southern,
      );
      // ...and the stored preference is left exactly as they set it.
      expect(
        container.read(userSettingsProvider).hemisphere,
        Hemisphere.northern,
      );
      expect(tester.widget<ChoiceCard>(northernChoice).selected, isTrue);
      // And the difference is explained rather than left to look like a bug.
      expect(find.textContaining('Your choice above is kept'), findsOneWidget);
    });
  });

  group('what is in the Almanac', () {
    testWidgets('lists every feature, with the Environment fixed', (
      tester,
    ) async {
      await openAlmanac(tester);

      for (final feature in FeatureRegistry.all) {
        expect(
          find.text(feature.name),
          findsWidgets,
          reason: '${feature.name} should be listed',
        );
      }

      // Seven switches, not eight: the Environment has no decision to make.
      expect(find.byType(SwitchListTile), findsNWidgets(7));
      expect(find.text('Always here'), findsOneWidget);
    });

    testWidgets('the Environment has no switch to turn it off', (tester) async {
      await openAlmanac(tester);

      final environmentRow = find.ancestor(
        of: find.text('Always here'),
        matching: find.byType(SwitchListTile),
      );
      expect(environmentRow, findsNothing);
    });

    testWidgets('a feature can be added, and appears in the navigation', (
      tester,
    ) async {
      final container = await openAlmanac(tester);

      await tapControl(tester, find.widgetWithText(SwitchListTile, 'Cookbook'));

      expect(container.read(userSettingsProvider).features, {
        FeatureId.cookbook,
      });
      final bar = tester.widget<AlmanacNavigationBar>(
        find.byType(AlmanacNavigationBar),
      );
      expect(bar.destinations.map((feature) => feature.name), [
        'Environment',
        'Cookbook',
      ]);
    });

    testWidgets('a feature can be removed', (tester) async {
      final container = await openAlmanac(
        tester,
        features: {FeatureId.cookbook, FeatureId.garden},
      );

      await tapControl(tester, find.widgetWithText(SwitchListTile, 'Garden'));

      expect(container.read(userSettingsProvider).features, {
        FeatureId.cookbook,
      });
      final bar = tester.widget<AlmanacNavigationBar>(
        find.byType(AlmanacNavigationBar),
      );
      expect(bar.destinations.map((feature) => feature.name), [
        'Environment',
        'Cookbook',
      ]);
    });

    testWidgets('several can be added in one visit', (tester) async {
      final container = await openAlmanac(tester);

      for (final name in ['Yoga', 'Garden', 'Nature Log']) {
        await tapControl(tester, find.widgetWithText(SwitchListTile, name));
      }

      expect(container.read(userSettingsProvider).features, {
        FeatureId.yoga,
        FeatureId.garden,
        FeatureId.natureLog,
      });
    });

    testWidgets('the changes are written, not just shown', (tester) async {
      final store = InMemorySettingsStore(
        const UserSettings(
          nameAsked: true,
          hemisphere: Hemisphere.northern,
          locationIntroSeen: true,
          onboardingCompleted: true,
        ),
      );
      await openAlmanac(
        tester,
        overrides: environmentOverrides(settingsStore: store),
      );

      await tapControl(tester, find.widgetWithText(SwitchListTile, 'Chakras'));

      expect(store.read().features, {FeatureId.chakras});
    });
  });

  group('location', () {
    testWidgets('the existing controls are reused, not reimplemented', (
      tester,
    ) async {
      await openAlmanac(tester);

      expect(find.text('Location access'), findsOneWidget);
      expect(find.text('Not enabled'), findsOneWidget);
      expect(find.text('Enable Location'), findsOneWidget);
      expect(find.textContaining('never sent anywhere'), findsOneWidget);
    });

    testWidgets('it only prompts from a deliberate tap', (tester) async {
      final service = FakeLocationService();
      await openAlmanac(
        tester,
        overrides: environmentOverrides(locationService: service),
      );

      expect(service.requestCount, 0);

      await tapControl(tester, find.text('Enable Location'));

      expect(service.requestCount, 1);
    });

    testWidgets('a permanent denial offers settings, not another prompt', (
      tester,
    ) async {
      await openAlmanac(
        tester,
        overrides: environmentOverrides(
          locationState: const LocationPermissionPermanentlyDenied(),
        ),
      );

      expect(find.text('Open app settings'), findsOneWidget);
      expect(find.text('Enable Location'), findsNothing);
    });

    testWidgets('no coordinates are ever shown', (tester) async {
      await openAlmanac(
        tester,
        overrides: environmentOverrides(
          locationState: const LocationAvailable(
            TestLocations.wellington,
            accuracyMetres: 850,
          ),
        ),
      );

      expect(find.textContaining('-41.2'), findsNothing);
      expect(find.textContaining('174.7'), findsNothing);
      expect(find.text('Allowed'), findsOneWidget);
    });
  });
}
