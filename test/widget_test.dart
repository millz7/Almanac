import 'package:almanac/app/app.dart';
import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/app/theme/theme_providers.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:almanac/dev/theme_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 keeps the Override type out of its main export.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_environment_services.dart';

/// Pins the environment so the app under test is not affected by the real
/// date, time or device time zone.
List<Override> _pinnedEnvironment({
  DateTime? now,
  DateTime? sunrise,
  DateTime? sunset,
}) => [
  // No background refresh timer, so no timers outlive the test.
  environmentRefreshEnabledProvider.overrideWithValue(false),
  clockProvider.overrideWithValue(() => now ?? DateTime.utc(2025, 7, 15, 12)),
  locationServiceProvider.overrideWithValue(
    FakeLocationService(TestLocations.london),
  ),
  solarServiceProvider.overrideWithValue(
    FakeSolarService(
      sunrise: sunrise ?? DateTime.utc(2025, 7, 15, 5),
      sunset: sunset ?? DateTime.utc(2025, 7, 15, 21),
    ),
  ),
];

void main() {
  testWidgets('app launches on Today and can navigate to other tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(overrides: _pinnedEnvironment(), child: const AlmanacApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Wellbeing'), findsOneWidget);
    expect(find.text('Rhythms'), findsOneWidget);
    expect(find.text('Nature'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);

    await tester.tap(find.text('Nature'));
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('bottom navigation exposes all five destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(overrides: _pinnedEnvironment(), child: const AlmanacApp()),
    );
    await tester.pumpAndSettle();

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.destinations.length, 5);
  });

  testWidgets('the app dresses itself in the season it detects', (
    tester,
  ) async {
    // Mid-July in London, at midday: summer, in daylight.
    await tester.pumpWidget(
      ProviderScope(overrides: _pinnedEnvironment(), child: const AlmanacApp()),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    final context = tester.element(find.byType(NavigationBar));

    expect(context.palette, same(SummerPalettes.day));
    expect(
      Theme.of(context).scaffoldBackgroundColor,
      SummerPalettes.day.background,
    );
    expect(scaffold, isNotNull);
  });

  testWidgets('the same app at night wears the night palette', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // 23:00, well after the 21:00 sunset.
        overrides: _pinnedEnvironment(now: DateTime.utc(2025, 7, 15, 23)),
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(NavigationBar));

    expect(context.palette, same(SummerPalettes.night));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('winter in the southern hemisphere is winter, in July', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          environmentRefreshEnabledProvider.overrideWithValue(false),
          clockProvider.overrideWithValue(() => DateTime.utc(2025, 7, 15, 0)),
          locationServiceProvider.overrideWithValue(
            FakeLocationService(TestLocations.wellington),
          ),
          solarServiceProvider.overrideWithValue(
            FakeSolarService(
              sunrise: DateTime.utc(2025, 7, 14, 19, 30),
              sunset: DateTime.utc(2025, 7, 15, 5, 10),
            ),
          ),
        ],
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(NavigationBar));

    expect(context.palette.name, 'Winter Day');
  });

  group('developer preview', () {
    testWidgets('overrides the detected season and time of day', (
      tester,
    ) async {
      final container = ProviderContainer(overrides: _pinnedEnvironment());
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AlmanacApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Detected: summer day.
      expect(
        tester.element(find.byType(NavigationBar)).palette,
        same(SummerPalettes.day),
      );

      container
          .read(themePreviewProvider.notifier)
          .select(
            const ThemePreviewSelection(season: Season.winter, isNight: true),
          );
      await tester.pumpAndSettle();

      expect(
        tester.element(find.byType(NavigationBar)).palette,
        same(WinterPalettes.night),
      );

      // Handing control back returns to the detected environment.
      container.read(themePreviewProvider.notifier).clear();
      await tester.pumpAndSettle();

      expect(
        tester.element(find.byType(NavigationBar)).palette,
        same(SummerPalettes.day),
      );
    });

    testWidgets('can reach all eight season and phase combinations', (
      tester,
    ) async {
      final container = ProviderContainer(overrides: _pinnedEnvironment());
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

          seen.add(tester.element(find.byType(NavigationBar)).palette.name);
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
      final container = ProviderContainer(overrides: _pinnedEnvironment());
      addTearDown(container.dispose);

      container
          .read(themePreviewProvider.notifier)
          .select(
            const ThemePreviewSelection(season: Season.autumn, isNight: false),
          );

      expect(container.read(activePaletteProvider), same(AutumnPalettes.day));
    });

    test('before the environment resolves, the season is still correct', () {
      final container = ProviderContainer(overrides: _pinnedEnvironment());
      addTearDown(container.dispose);

      // Read the palette without awaiting the async environment.
      expect(container.read(activePaletteProvider), same(SummerPalettes.day));
    });
  });
}
