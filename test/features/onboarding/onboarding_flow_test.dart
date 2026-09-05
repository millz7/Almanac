import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/natural_environment.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/core/settings/settings_store.dart';
import 'package:almanac/core/settings/user_settings.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 keeps the Override type out of its main export.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// A store whose writes always fail, for the error path.
///
/// Reads as somebody who has passed the name question, so the failure
/// under test is the hemisphere's rather than the name's.
class _FailingSettingsStore implements SettingsStore {
  const _FailingSettingsStore();

  @override
  UserSettings read() => const UserSettings(nameAsked: true);

  @override
  Future<void> write(UserSettings settings) async =>
      throw StateError('disk is full');
}

void main() {
  /// The palette the app is currently wearing.
  SeasonalPalette paletteAt(WidgetTester tester, Finder finder) =>
      tester.element(finder).palette;

  Future<ProviderContainer> pumpApp(
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
    return container;
  }

  /// Scrolls a control into view before tapping it. The onboarding
  /// screens scroll on short displays, and the default test viewport is
  /// shorter than a phone.
  Future<void> tapControl(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  final nameQuestion = find.text('What should we call you?');
  final hemisphereQuestion = find.text('Where are you in the world?');
  final locationIntro = find.text(
    'Let your Almanac follow the world around you',
  );
  final featureQuestion = find.text('What would you like in your Almanac?');
  final northernChoice = find.widgetWithText(ChoiceCard, 'Northern Hemisphere');
  final southernChoice = find.widgetWithText(ChoiceCard, 'Southern Hemisphere');

  /// A device that has answered the name question and nothing else, so
  /// the hemisphere is the step in hand. Most of the tests below are
  /// about a later stage than the name, and this keeps them from having
  /// to walk past it.
  InMemorySettingsStore atHemisphereQuestion() =>
      InMemorySettingsStore(const UserSettings(nameAsked: true));

  /// Settings for somebody who has finished setup.
  UserSettings settled({
    Hemisphere hemisphere = Hemisphere.southern,
    String? name,
    Set<FeatureId> features = const {},
  }) => UserSettings(
    name: name,
    nameAsked: true,
    hemisphere: hemisphere,
    locationIntroSeen: true,
    features: features,
    onboardingCompleted: true,
  );

  /// Answers the last question — what to put in the Almanac — which is
  /// what actually lands the user in the app.
  Future<void> finishSetup(WidgetTester tester) async {
    expect(featureQuestion, findsOneWidget);
    await tapControl(
      tester,
      find.widgetWithText(ElevatedButton, 'Just the Environment'),
    );
  }

  group('first launch', () {
    testWidgets('opens on the name question, which can be skipped', (
      tester,
    ) async {
      final store = InMemorySettingsStore();
      final service = FakeLocationService();
      final container = await pumpApp(
        tester,
        overrides: environmentOverrides(
          settingsStore: store,
          locationService: service,
        ),
      );

      expect(nameQuestion, findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      // Nothing about accounts, and no permission dialog on the very
      // first screen either.
      expect(find.textContaining('sign in', findRichText: true), findsNothing);
      expect(service.requestCount, 0);
      expect(
        container.read(locationStateProvider),
        isA<LocationPermissionNotRequested>(),
      );

      await tapControl(tester, find.text('Skip'));

      // Skipped means no name stored, and on to the next question.
      expect(store.read().name, isNull);
      expect(store.read().nameAsked, isTrue);
      expect(hemisphereQuestion, findsOneWidget);
    });

    testWidgets('a supplied name is kept and titles their Almanac', (
      tester,
    ) async {
      final store = InMemorySettingsStore();
      final container = await pumpApp(
        tester,
        overrides: environmentOverrides(settingsStore: store),
      );

      await tester.enterText(find.byType(TextField), '  Millie  ');
      await tapControl(tester, find.widgetWithText(ElevatedButton, 'Continue'));

      // Trimmed, stored, and used for the one thing it is for.
      expect(store.read().name, 'Millie');
      expect(container.read(almanacTitleProvider), "Millie's Almanac");
      expect(hemisphereQuestion, findsOneWidget);
    });

    testWidgets('asks which hemisphere, with no location prompt', (
      tester,
    ) async {
      final service = FakeLocationService();
      final container = await pumpApp(
        tester,
        overrides: environmentOverrides(
          settingsStore: atHemisphereQuestion(),
          locationService: service,
        ),
      );

      expect(hemisphereQuestion, findsOneWidget);
      expect(
        find.text(
          'We use your hemisphere to follow the seasons where '
          'you live.',
        ),
        findsOneWidget,
      );
      expect(northernChoice, findsOneWidget);
      expect(southernChoice, findsOneWidget);

      // The very first screen must not be a permission dialog.
      expect(service.requestCount, 0);
      expect(
        container.read(locationStateProvider),
        isA<LocationPermissionNotRequested>(),
      );

      // And it is not the main app either.
      expect(find.byType(AlmanacNavigationBar), findsNothing);
    });

    testWidgets('onboarding wears the active seasonal theme', (tester) async {
      // Mid-July, nothing chosen yet: the screen still looks like the app.
      await pumpApp(
        tester,
        overrides: environmentOverrides(settingsStore: atHemisphereQuestion()),
      );

      final palette = paletteAt(tester, hemisphereQuestion);
      expect(palette, same(SummerPalettes.day));
    });

    testWidgets('at night onboarding wears the night palette', (tester) async {
      await pumpApp(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 15, 23),
          settingsStore: atHemisphereQuestion(),
        ),
      );

      expect(paletteAt(tester, hemisphereQuestion), same(SummerPalettes.night));
    });
  });

  group('existing preference', () {
    testWidgets('a configured user goes straight into the app', (tester) async {
      await pumpApp(
        tester,
        overrides: environmentOverrides(
          settingsStore: InMemorySettingsStore(settled()),
        ),
      );

      expect(nameQuestion, findsNothing);
      expect(hemisphereQuestion, findsNothing);
      expect(locationIntro, findsNothing);
      expect(featureQuestion, findsNothing);
      expect(find.byType(AlmanacNavigationBar), findsOneWidget);
      // The Environment, with a real date on it.
      expect(find.text('Tuesday 15 July'), findsOneWidget);
    });
  });

  group('choosing a hemisphere', () {
    testWidgets('saves the choice and moves to the location explanation', (
      tester,
    ) async {
      final store = atHemisphereQuestion();
      final container = await pumpApp(
        tester,
        overrides: environmentOverrides(settingsStore: store),
      );

      await tapControl(tester, southernChoice);

      expect(store.read().hemisphere, Hemisphere.southern);
      expect(
        container.read(userSettingsProvider).hemisphere,
        Hemisphere.southern,
      );
      expect(locationIntro, findsOneWidget);
      expect(hemisphereQuestion, findsNothing);
    });

    testWidgets('4 September: southern gives winter, northern gives summer', (
      tester,
    ) async {
      // The date from the brief. The hemispheres do diverge — which is
      // the point — but the app uses *astronomical* seasons, and the
      // September equinox is not until the 22nd, so early September is
      // still summer in the north and winter in the south. A
      // meteorological calendar would say autumn/spring here.
      final september = DateTime.utc(2025, 9, 4, 12);

      await pumpApp(
        tester,
        overrides: environmentOverrides(
          now: september,
          settingsStore: atHemisphereQuestion(),
        ),
      );
      await tapControl(tester, southernChoice);

      expect(paletteAt(tester, locationIntro).name, 'Winter Day');

      // A fresh launch, same date, the other answer.
      await pumpApp(
        tester,
        overrides: environmentOverrides(
          now: september,
          settingsStore: atHemisphereQuestion(),
        ),
      );
      await tapControl(tester, northernChoice);

      expect(paletteAt(tester, locationIntro).name, 'Summer Day');
    });

    testWidgets('mid-October: southern gives spring, northern gives autumn', (
      tester,
    ) async {
      // Past the September equinox, so this is where spring and autumn
      // actually diverge under astronomical seasons.
      final october = DateTime.utc(2025, 10, 15, 12);

      await pumpApp(
        tester,
        overrides: environmentOverrides(
          now: october,
          settingsStore: atHemisphereQuestion(),
        ),
      );
      await tapControl(tester, southernChoice);

      expect(paletteAt(tester, locationIntro).name, 'Spring Day');

      await pumpApp(
        tester,
        overrides: environmentOverrides(
          now: october,
          settingsStore: atHemisphereQuestion(),
        ),
      );
      await tapControl(tester, northernChoice);

      expect(paletteAt(tester, locationIntro).name, 'Autumn Day');
    });

    testWidgets('December: southern gives summer, northern gives winter', (
      tester,
    ) async {
      final december = DateTime.utc(2025, 12, 25, 12);

      await pumpApp(
        tester,
        overrides: environmentOverrides(
          now: december,
          settingsStore: atHemisphereQuestion(),
        ),
      );
      await tapControl(tester, southernChoice);
      expect(paletteAt(tester, locationIntro).name, 'Summer Day');

      await pumpApp(
        tester,
        overrides: environmentOverrides(
          now: december,
          settingsStore: atHemisphereQuestion(),
        ),
      );
      await tapControl(tester, northernChoice);
      expect(paletteAt(tester, locationIntro).name, 'Winter Day');
    });

    testWidgets('a save failure keeps the user on the question', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: environmentOverrides(
          settingsStore: const _FailingSettingsStore(),
        ),
      );

      await tapControl(tester, southernChoice);

      // Not silently carried on as though it saved.
      expect(hemisphereQuestion, findsOneWidget);
      expect(locationIntro, findsNothing);
      expect(find.text("That didn't save"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('location explanation', () {
    List<Override> afterHemisphere({
      Hemisphere hemisphere = Hemisphere.southern,
      DateTime? now,
      FakeLocationService? service,
      SettingsStore? store,
    }) => environmentOverrides(
      now: now,
      settingsStore:
          store ??
          InMemorySettingsStore(
            UserSettings(nameAsked: true, hemisphere: hemisphere),
          ),
      locationService: service ?? FakeLocationService(),
    );

    testWidgets('explains the benefits and offers an easy way out', (
      tester,
    ) async {
      await pumpApp(tester, overrides: afterHemisphere());

      expect(locationIntro, findsOneWidget);
      expect(find.text('Allow Location'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);
      expect(find.text('Sunrise and sunset where you are'), findsOneWidget);
      // No pressure, no dead end.
      expect(find.textContaining('must'), findsNothing);
    });

    testWidgets('"Not Now" keeps the chosen hemisphere and enters the app', (
      tester,
    ) async {
      final store = InMemorySettingsStore(
        const UserSettings(nameAsked: true, hemisphere: Hemisphere.southern),
      );
      final service = FakeLocationService();
      final container = await pumpApp(
        tester,
        overrides: afterHemisphere(store: store, service: service),
      );

      await tapControl(tester, find.text('Not Now'));
      await finishSetup(tester);

      // Never prompted, and the app is usable.
      expect(service.requestCount, 0);
      expect(find.byType(AlmanacNavigationBar), findsOneWidget);

      // The hemisphere still drives the season: July in the south.
      expect(store.read().hemisphere, Hemisphere.southern);
      expect(
        container.read(resolvedHemisphereProvider).hemisphere,
        Hemisphere.southern,
      );
      expect(
        paletteAt(tester, find.byType(AlmanacNavigationBar)).name,
        'Winter Day',
      );
    });

    testWidgets('"Allow Location" prompts once and continues either way', (
      tester,
    ) async {
      final service = FakeLocationService(
        requestResult: const LocationPermissionDenied(),
      );
      final container = await pumpApp(
        tester,
        overrides: afterHemisphere(service: service),
      );

      await tapControl(tester, find.text('Allow Location'));
      await finishSetup(tester);

      expect(service.requestCount, 1);
      // A refusal is not an error: the app opens anyway.
      expect(find.byType(AlmanacNavigationBar), findsOneWidget);
      expect(
        container.read(resolvedHemisphereProvider).hemisphere,
        Hemisphere.southern,
      );
    });

    testWidgets('granting location derives the hemisphere from latitude', (
      tester,
    ) async {
      final service = FakeLocationService(
        requestResult: const LocationAvailable(TestLocations.wellington),
      );
      final container = await pumpApp(
        tester,
        // Stored choice deliberately disagrees with the position.
        overrides: afterHemisphere(
          hemisphere: Hemisphere.northern,
          service: service,
        ),
      );

      await tapControl(tester, find.text('Allow Location'));
      await finishSetup(tester);

      final resolved = container.read(resolvedHemisphereProvider);
      expect(resolved.hemisphere, Hemisphere.southern);
      // The stored preference is untouched.
      expect(
        container.read(userSettingsProvider).hemisphere,
        Hemisphere.northern,
      );
      expect(
        paletteAt(tester, find.byType(AlmanacNavigationBar)).name,
        'Winter Day',
      );
    });

    testWidgets('a permanently denied permission does not trap the user', (
      tester,
    ) async {
      final service = FakeLocationService(
        requestResult: const LocationPermissionPermanentlyDenied(),
      );
      await pumpApp(tester, overrides: afterHemisphere(service: service));

      await tapControl(tester, find.text('Allow Location'));
      await finishSetup(tester);

      expect(find.byType(AlmanacNavigationBar), findsOneWidget);
    });

    testWidgets('a broken platform layer does not trap the user', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: environmentOverrides(
          settingsStore: InMemorySettingsStore(
            const UserSettings(
              nameAsked: true,
              hemisphere: Hemisphere.southern,
            ),
          ),
          locationService: const ThrowingLocationService(),
        ),
      );

      await tapControl(tester, find.text('Allow Location'));
      await finishSetup(tester);

      expect(find.byType(AlmanacNavigationBar), findsOneWidget);
    });
  });

  group('the New Zealand scenario, across the year', () {
    // Latitude ~-41, longitude ~174: a southern user who has declined
    // location, so only their chosen hemisphere is available.
    /// Noon on a New Zealand calendar day, as an absolute instant. Using
    /// local noon rather than UTC noon matters at +13: UTC midday is the
    /// small hours of the next NZ day.
    DateTime localNoon(int month, int day) =>
        TestTimeZones.wellington.instantAtLocal(2025, month, day, 12);

    // Astronomical seasons, so the turning points are the equinoxes and
    // solstices rather than the 1st of a month.
    final cases = <({String label, DateTime date, String palette})>[
      (label: '15 January', date: localNoon(1, 15), palette: 'Summer Day'),
      (label: '15 April', date: localNoon(4, 15), palette: 'Autumn Day'),
      (label: '15 July', date: localNoon(7, 15), palette: 'Winter Day'),
      // Before the September equinox: still winter in the south.
      (label: '4 September', date: localNoon(9, 4), palette: 'Winter Day'),
      // After it: spring.
      (label: '15 October', date: localNoon(10, 15), palette: 'Spring Day'),
      (label: '25 December', date: localNoon(12, 25), palette: 'Summer Day'),
    ];

    for (final testCase in cases) {
      testWidgets('${testCase.label} in NZ is ${testCase.palette}', (
        tester,
      ) async {
        await pumpApp(
          tester,
          overrides: environmentOverrides(
            now: testCase.date,
            timeZone: TestTimeZones.wellington,
            settingsStore: InMemorySettingsStore(settled()),
            // Daylight is derived from the local day by the helper.
          ),
        );

        expect(
          paletteAt(tester, find.byType(AlmanacNavigationBar)).name,
          testCase.palette,
        );
      });
    }

    testWidgets('and the same dates with a real NZ latitude agree', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 10, 15, 12),
          timeZone: TestTimeZones.wellington,
          settingsStore: InMemorySettingsStore(settled()),
          locationState: const LocationAvailable(TestLocations.wellington),
        ),
      );

      final environment = await container.read(
        naturalEnvironmentProvider.future,
      );
      expect(environment.season.season, Season.spring);
      expect(environment.hemisphere, Hemisphere.southern);
      expect(
        environment.hemisphereSource,
        HemisphereSource.derivedFromLocation,
      );
      expect(environment.location, TestLocations.wellington);
    });
  });

  group('onboarding is not part of normal navigation', () {
    testWidgets('a configured app has no route back into onboarding', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: environmentOverrides(
          settingsStore: InMemorySettingsStore(
            settled(
              hemisphere: Hemisphere.northern,
              features: FeatureId.values.toSet()..remove(FeatureId.environment),
            ),
          ),
        ),
      );

      // Every destination is reachable; none of them is onboarding.
      for (final feature in FeatureRegistry.all) {
        await tester.tap(find.bySemanticsLabel(feature.name));
        await tester.pumpAndSettle();
        expect(nameQuestion, findsNothing);
        expect(hemisphereQuestion, findsNothing);
        expect(locationIntro, findsNothing);
        expect(featureQuestion, findsNothing);
      }
    });
  });

  group('accessibility', () {
    testWidgets('both hemisphere options are labelled buttons', (tester) async {
      await pumpApp(
        tester,
        overrides: environmentOverrides(settingsStore: atHemisphereQuestion()),
      );

      final handle = tester.ensureSemantics();
      for (final label in ['Northern Hemisphere', 'Southern Hemisphere']) {
        expect(
          find.bySemanticsLabel(RegExp(label)),
          findsOneWidget,
          reason: '$label must be readable by a screen reader',
        );
      }
      handle.dispose();
    });

    testWidgets('the choices clear the minimum touch target', (tester) async {
      await pumpApp(
        tester,
        overrides: environmentOverrides(settingsStore: atHemisphereQuestion()),
      );

      for (final choice in [northernChoice, southernChoice]) {
        final size = tester.getSize(choice);
        expect(
          size.height,
          greaterThanOrEqualTo(AppDimens.minTouchTarget),
          reason: 'a primary choice must be comfortably tappable',
        );
      }
    });
  });
}
