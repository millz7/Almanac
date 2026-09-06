import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/app/theme/theme_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/dev/theme_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_environment_services.dart';
import 'support/test_overrides.dart';

void main() {
  /// The palette the app is actually wearing, read from a widget deep in
  /// the tree so this asserts what the user sees.
  SeasonalPalette paletteOf(WidgetTester tester) =>
      tester.element(find.byType(AlmanacNavigationBar)).palette;

  testWidgets(
    'the app launches on the Environment and shows the Almanac the user '
    'chose',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: environmentOverrides(
            features: const {FeatureId.meditation, FeatureId.natureLog},
          ),
          child: const AlmanacApp(),
        ),
      );
      await tester.pumpAndSettle();

      // The Environment screen itself: a real date, not a placeholder.
      expect(find.text('Tuesday 15 July'), findsOneWidget);

      final bar = tester.widget<AlmanacNavigationBar>(
        find.byType(AlmanacNavigationBar),
      );
      expect(bar.destinations.map((feature) => feature.name).toList(), [
        'Environment',
        'Meditation',
        'Nature Log',
      ]);
      expect(bar.selectedIndex, 0);

      await tester.tap(find.bySemanticsLabel('Meditation'));
      await tester.pumpAndSettle();

      // Meditation is built, so this is the real screen rather than a
      // placeholder.
      expect(find.text('Take a slow breath'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Start'), findsOneWidget);
    },
  );

  testWidgets('an Almanac with nothing added is just the Environment', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: environmentOverrides(),
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();

    final bar = tester.widget<AlmanacNavigationBar>(
      find.byType(AlmanacNavigationBar),
    );
    expect(bar.destinations.single.name, 'Environment');
  });

  testWidgets('the app dresses itself in the season it detects', (
    tester,
  ) async {
    // Mid-July, northern hemisphere, midday: summer, in daylight.
    await tester.pumpWidget(
      ProviderScope(
        overrides: environmentOverrides(),
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(paletteOf(tester), same(SummerPalettes.day));
    expect(
      Theme.of(tester.element(find.byType(AlmanacNavigationBar)))
          .scaffoldBackgroundColor,
      SummerPalettes.day.background,
    );
  });

  testWidgets('the same app at night wears the night palette', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // 23:00, well after the 21:00 sunset.
        overrides: environmentOverrides(now: DateTime.utc(2025, 7, 15, 23)),
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(paletteOf(tester), same(SummerPalettes.night));
    expect(
      Theme.of(tester.element(find.byType(AlmanacNavigationBar))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('July in the southern hemisphere is winter', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: environmentOverrides(
          // Local noon in Wellington, which is the previous day in UTC.
          now: TestTimeZones.wellington.instantAtLocal(2025, 7, 15, 12),
          timeZone: TestTimeZones.wellington,
          hemisphere: Hemisphere.southern,
        ),
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(paletteOf(tester).name, 'Winter Day');
  });

  testWidgets('a shared location overrides the stored hemisphere', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 15, 12),
          // Stored choice says northern; the device says Wellington.
          hemisphere: Hemisphere.northern,
          locationState: const LocationAvailable(TestLocations.wellington),
        ),
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(paletteOf(tester).name, 'Winter Day');
  });

  group('developer preview', () {
    testWidgets('overrides the detected season and time of day', (
      tester,
    ) async {
      final container = ProviderContainer(overrides: environmentOverrides());
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AlmanacApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(paletteOf(tester), same(SummerPalettes.day));

      container
          .read(themePreviewProvider.notifier)
          .select(
            const ThemePreviewSelection(season: Season.winter, isNight: true),
          );
      await tester.pumpAndSettle();

      expect(paletteOf(tester), same(WinterPalettes.night));

      // Handing control back returns to the detected environment.
      container.read(themePreviewProvider.notifier).clear();
      await tester.pumpAndSettle();

      expect(paletteOf(tester), same(SummerPalettes.day));
    });

    testWidgets('can reach all eight season and phase combinations', (
      tester,
    ) async {
      final container = ProviderContainer(overrides: environmentOverrides());
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AlmanacApp(),
        ),
      );
      await tester.pumpAndSettle();

      final seen = <String>[];
      for (final season in Season.values) {
        for (final isNight in [false, true]) {
          container
              .read(themePreviewProvider.notifier)
              .select(ThemePreviewSelection(season: season, isNight: isNight));
          await tester.pumpAndSettle();

          seen.add(paletteOf(tester).name);
        }
      }

      expect(seen, [
        'Spring Day',
        'Spring Night',
        'Summer Day',
        'Summer Night',
        'Autumn Day',
        'Autumn Night',
        'Winter Day',
        'Winter Night',
      ]);
    });
  });

  group('theme providers', () {
    test('a preview selection takes precedence over the environment', () {
      final container = ProviderContainer(overrides: environmentOverrides());
      addTearDown(container.dispose);

      container
          .read(themePreviewProvider.notifier)
          .select(
            const ThemePreviewSelection(season: Season.autumn, isNight: false),
          );

      expect(container.read(activePaletteProvider), same(AutumnPalettes.day));
    });

    test('before the environment resolves, the season is still correct', () {
      final container = ProviderContainer(overrides: environmentOverrides());
      addTearDown(container.dispose);

      // Read the palette without awaiting the async environment.
      expect(container.read(activePaletteProvider), same(SummerPalettes.day));
    });

    test('the bootstrap palette respects the chosen hemisphere', () {
      final container = ProviderContainer(
        overrides: environmentOverrides(hemisphere: Hemisphere.southern),
      );
      addTearDown(container.dispose);

      // Even before anything async resolves, a southern user in July must
      // not be shown summer.
      expect(container.read(activePaletteProvider), same(WinterPalettes.day));
    });
  });
}
