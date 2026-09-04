import 'package:almanac/app/app.dart';
import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/app/theme/theme_providers.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/natural_environment.dart';
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
    hemisphere: Hemisphere.northern,
    locationIntroSeen: true,
  );

  @override
  Future<void> write(UserSettings settings) async =>
      throw StateError('disk is full');
}

void main() {
  setUpAll(useTimeZoneDatabase);

  final settingsButton = find.byIcon(Icons.settings_outlined);
  final northernChoice = find.widgetWithText(ChoiceCard, 'Northern Hemisphere');
  final southernChoice = find.widgetWithText(ChoiceCard, 'Southern Hemisphere');

  /// Launches the app and opens Settings the way a user would.
  Future<ProviderContainer> openSettings(
    WidgetTester tester, {
    required List<Override> overrides,
  }) async {
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(settingsButton);
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tapControl(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('reaching settings', () {
    testWidgets('there is a way in from the app, and a way back', (
      tester,
    ) async {
      await openSettings(tester, overrides: environmentOverrides());

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Location & Region'), findsOneWidget);

      // It is pushed over the app, so the user can come back.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('settings is not one of the navigation tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: environmentOverrides(),
          child: const AlmanacApp(),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, 5);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('it wears the active seasonal palette', (tester) async {
      // Mid-July, northern: summer, in daylight.
      await openSettings(tester, overrides: environmentOverrides());

      final palette = tester.element(find.text('Hemisphere')).palette;
      expect(palette, same(SummerPalettes.day));
    });
  });

  group('changing hemisphere', () {
    testWidgets('shows which hemisphere is currently chosen', (tester) async {
      await openSettings(
        tester,
        overrides: environmentOverrides(hemisphere: Hemisphere.southern),
      );

      final selected = tester.widget<ChoiceCard>(southernChoice);
      final other = tester.widget<ChoiceCard>(northernChoice);

      expect(selected.selected, isTrue);
      expect(other.selected, isFalse);
    });

    testWidgets('the change persists and needs no restart', (tester) async {
      final store = InMemorySettingsStore(
        const UserSettings(
          hemisphere: Hemisphere.northern,
          locationIntroSeen: true,
        ),
      );
      final container = await openSettings(
        tester,
        overrides: environmentOverrides(settingsStore: store),
      );

      await tapControl(tester, southernChoice);

      // Written through to storage...
      expect(store.read().hemisphere, Hemisphere.southern);
      // ...and live in the app, with no restart.
      expect(
        container.read(userSettingsProvider).hemisphere,
        Hemisphere.southern,
      );
      expect(tester.widget<ChoiceCard>(southernChoice).selected, isTrue);
    });

    testWidgets('the season and theme follow immediately', (tester) async {
      // Mid-July: summer in the north, winter in the south.
      final container = await openSettings(
        tester,
        overrides: environmentOverrides(hemisphere: Hemisphere.northern),
      );

      expect(container.read(activePaletteProvider), same(SummerPalettes.day));

      await tapControl(tester, southernChoice);

      expect(container.read(activePaletteProvider), same(WinterPalettes.day));
      // And the screen the user is looking at has repainted.
      expect(
        tester.element(find.text('Hemisphere')).palette,
        same(WinterPalettes.day),
      );
    });

    testWidgets('the environment recomputes its season', (tester) async {
      final container = await openSettings(
        tester,
        overrides: environmentOverrides(hemisphere: Hemisphere.northern),
      );

      await tapControl(tester, southernChoice);
      final environment = await container.read(
        naturalEnvironmentProvider.future,
      );

      expect(environment.hemisphere, Hemisphere.southern);
      expect(environment.hemisphereSource, HemisphereSource.userSelected);
    });

    testWidgets('a save failure is reported, not swallowed', (tester) async {
      await openSettings(
        tester,
        overrides: environmentOverrides(
          settingsStore: const _FailingSettingsStore(),
        ),
      );

      await tapControl(tester, southernChoice);

      expect(find.textContaining('could not be saved'), findsOneWidget);
    });
  });

  group('location', () {
    testWidgets('offers to enable it when it has never been asked', (
      tester,
    ) async {
      await openSettings(tester, overrides: environmentOverrides());

      expect(find.text('Location access'), findsOneWidget);
      expect(find.text('Not enabled'), findsOneWidget);
      expect(find.text('Enable Location'), findsOneWidget);
    });

    testWidgets('asks the platform when the user taps Enable', (tester) async {
      final service = FakeLocationService(
        requestResult: LocationAvailable(
          TestLocations.wellington,
          accuracyMetres: 1500,
          obtainedAt: DateTime.utc(2025, 7, 15, 12),
        ),
      );
      await openSettings(
        tester,
        overrides: environmentOverrides(locationService: service),
      );

      await tapControl(tester, find.text('Enable Location'));

      expect(service.requestCount, 1);
      expect(find.text('Allowed'), findsOneWidget);
    });

    testWidgets('shows that it is allowed, with the fix accuracy', (
      tester,
    ) async {
      await openSettings(
        tester,
        overrides: environmentOverrides(
          locationState: LocationAvailable(
            TestLocations.wellington,
            accuracyMetres: 1200,
            obtainedAt: DateTime.utc(2025, 7, 15, 12),
          ),
        ),
      );

      expect(find.text('Allowed'), findsOneWidget);
      expect(find.textContaining('1200 m'), findsOneWidget);
      expect(find.text('Update my location'), findsOneWidget);
      // Nothing to grant, so no prompt offered.
      expect(find.text('Enable Location'), findsNothing);
    });

    testWidgets('a refusal is explained without pressure, and can be retried', (
      tester,
    ) async {
      await openSettings(
        tester,
        overrides: environmentOverrides(
          locationState: const LocationPermissionDenied(),
        ),
      );

      expect(find.text('Not enabled'), findsOneWidget);
      expect(find.textContaining('works from your hemisphere'), findsOneWidget);
      expect(find.text('Enable Location'), findsOneWidget);
      // No guilt, no dead ends.
      expect(find.textContaining('must'), findsNothing);
    });

    testWidgets('a permanent denial sends the user to the system, not a '
        'pointless prompt', (tester) async {
      final service = FakeLocationService(
        checkResult: const LocationPermissionPermanentlyDenied(),
      );
      await openSettings(
        tester,
        overrides: environmentOverrides(
          locationService: service,
          locationState: const LocationPermissionPermanentlyDenied(),
        ),
      );

      expect(find.text('Blocked'), findsOneWidget);
      expect(find.text('Open app settings'), findsOneWidget);
      expect(
        find.text('Enable Location'),
        findsNothing,
        reason: 'Android will not prompt again, so offering to is a lie',
      );

      await tapControl(tester, find.text('Open app settings'));

      expect(service.openSettingsCount, 1);
      expect(service.requestCount, 0);
    });

    testWidgets('an unavailable position is explained and retryable', (
      tester,
    ) async {
      await openSettings(
        tester,
        overrides: environmentOverrides(
          locationState: const LocationUnavailable('services off'),
        ),
      );

      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('Enable Location'), findsOneWidget);
    });

    testWidgets('the privacy position is stated plainly', (tester) async {
      await openSettings(tester, overrides: environmentOverrides());

      expect(
        find.textContaining('only ever read on this device'),
        findsOneWidget,
      );
    });
  });

  group('hemisphere disagreement', () {
    testWidgets('is explained rather than silently overriding the user', (
      tester,
    ) async {
      await openSettings(
        tester,
        overrides: environmentOverrides(
          // Chose northern; the device says Wellington.
          hemisphere: Hemisphere.northern,
          locationState: const LocationAvailable(TestLocations.wellington),
        ),
      );

      expect(
        find.textContaining('Your location puts you in the'),
        findsOneWidget,
      );
      // The stored choice is still shown as theirs.
      expect(tester.widget<ChoiceCard>(northernChoice).selected, isTrue);
    });

    testWidgets('no note appears when the two agree', (tester) async {
      await openSettings(
        tester,
        overrides: environmentOverrides(
          hemisphere: Hemisphere.southern,
          locationState: const LocationAvailable(TestLocations.wellington),
        ),
      );

      expect(
        find.textContaining('Your location puts you in the'),
        findsNothing,
      );
    });
  });
}
