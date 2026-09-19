import 'dart:io';

import 'package:almanac/app/app.dart';
import 'package:almanac/core/environment/day_night.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:almanac/features/environment/domain/environment_artwork.dart';
import 'package:almanac/features/environment/presentation/environment_text.dart';
import 'package:almanac/features/environment/presentation/widgets/environment_artwork_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// The artwork contract.
///
/// The Environment's landscape is sixteen approved painted plates. These
/// tests are about the plates being installed, found, and correctly
/// chosen — not about how a painter draws, because there is no longer a
/// painter to draw one.
void main() {
  setUpAll(useTimeZoneDatabase);

  group('the plates are installed', () {
    test('there are exactly sixteen, and no more', () {
      expect(EnvironmentArtwork.all, hasLength(16));
      expect(EnvironmentArtwork.all.toSet(), hasLength(16));

      final onDisk = Directory(EnvironmentArtwork.directory)
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.webp'))
          .map((file) => file.path)
          .toList();
      expect(onDisk, hasLength(16));
    });

    test('every plate the app can ask for exists on disk', () {
      for (final asset in EnvironmentArtwork.all) {
        expect(
          File(asset).existsSync(),
          isTrue,
          reason: '$asset is missing from the bundle',
        );
      }
    });

    test('and every file on disk is one the app can ask for', () {
      // Nothing shipped that nothing selects, and nothing selected that
      // is not shipped.
      final onDisk =
          Directory(EnvironmentArtwork.directory)
              .listSync()
              .whereType<File>()
              .where((file) => file.path.endsWith('.webp'))
              .map((file) => file.path)
              .toList()
            ..sort();

      expect(onDisk, EnvironmentArtwork.all.toList()..sort());
    });

    test('the directory is registered for bundling', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('${EnvironmentArtwork.directory}/'));
    });

    test('and nothing is fetched', () {
      // Bundled, local, offline. A plate is an asset path, never a URL.
      for (final asset in EnvironmentArtwork.all) {
        expect(asset.startsWith('assets/'), isTrue);
        expect(asset.contains('http'), isFalse);
      }
    });
  });

  group('every season at every light resolves to one plate', () {
    test('all sixteen mappings, named explicitly', () {
      const expected = {
        (Season.spring, EnvironmentLightState.sunrise):
            'assets/environment/spring_sunrise.webp',
        (Season.spring, EnvironmentLightState.day):
            'assets/environment/spring_day.webp',
        (Season.spring, EnvironmentLightState.sunset):
            'assets/environment/spring_sunset.webp',
        (Season.spring, EnvironmentLightState.night):
            'assets/environment/spring_night.webp',
        (Season.summer, EnvironmentLightState.sunrise):
            'assets/environment/summer_sunrise.webp',
        (Season.summer, EnvironmentLightState.day):
            'assets/environment/summer_day.webp',
        (Season.summer, EnvironmentLightState.sunset):
            'assets/environment/summer_sunset.webp',
        (Season.summer, EnvironmentLightState.night):
            'assets/environment/summer_night.webp',
        (Season.autumn, EnvironmentLightState.sunrise):
            'assets/environment/autumn_sunrise.webp',
        (Season.autumn, EnvironmentLightState.day):
            'assets/environment/autumn_day.webp',
        (Season.autumn, EnvironmentLightState.sunset):
            'assets/environment/autumn_sunset.webp',
        (Season.autumn, EnvironmentLightState.night):
            'assets/environment/autumn_night.webp',
        (Season.winter, EnvironmentLightState.sunrise):
            'assets/environment/winter_sunrise.webp',
        (Season.winter, EnvironmentLightState.day):
            'assets/environment/winter_day.webp',
        (Season.winter, EnvironmentLightState.sunset):
            'assets/environment/winter_sunset.webp',
        (Season.winter, EnvironmentLightState.night):
            'assets/environment/winter_night.webp',
      };

      expect(expected, hasLength(16));
      expected.forEach((key, asset) {
        final (season, light) = key;
        expect(
          EnvironmentArtwork.forState(season: season, light: light),
          asset,
          reason: '${season.name} ${light.name}',
        );
      });
    });

    test('and no two combinations share a plate', () {
      final seen = <String, String>{};
      for (final season in Season.values) {
        for (final light in EnvironmentLightState.values) {
          final asset = EnvironmentArtwork.forState(
            season: season,
            light: light,
          );
          expect(
            seen.containsKey(asset),
            isFalse,
            reason:
                '$asset is used by both ${seen[asset]} and '
                '${season.name} ${light.name}',
          );
          seen[asset] = '${season.name} ${light.name}';
        }
      }
      expect(seen, hasLength(16));
    });

    test('day maps to day, sunrise to sunrise, sunset to sunset, night '
        'to night', () {
      for (final season in Season.values) {
        for (final light in EnvironmentLightState.values) {
          final asset = EnvironmentArtwork.forState(
            season: season,
            light: light,
          );
          expect(asset, contains(season.name));
          expect(asset, endsWith('_${light.name}.webp'));
        }
      }
    });
  });

  group('the real day/night state chooses the light', () {
    DayNightState at(DayPhase phase) =>
        DayNightState(phase: phase, daylight: phase == DayPhase.day ? 1 : 0.5);

    test('dawn is sunrise, dusk is sunset, and the rest are themselves', () {
      // A pure adaptation layer over the app's own calculated phase —
      // no clock thresholds, and no second daylight model.
      expect(
        EnvironmentLightState.of(at(DayPhase.dawn)),
        EnvironmentLightState.sunrise,
      );
      expect(
        EnvironmentLightState.of(at(DayPhase.day)),
        EnvironmentLightState.day,
      );
      expect(
        EnvironmentLightState.of(at(DayPhase.dusk)),
        EnvironmentLightState.sunset,
      );
      expect(
        EnvironmentLightState.of(at(DayPhase.night)),
        EnvironmentLightState.night,
      );
    });
  });

  group('warming the next plate', () {
    test('the light states run in the order a day runs', () {
      // The plate kept warm is the next light state in the *same*
      // season, so the order below is what makes "adjacent" mean
      // "later today" rather than "a different season".
      expect(EnvironmentLightState.values, [
        EnvironmentLightState.sunrise,
        EnvironmentLightState.day,
        EnvironmentLightState.sunset,
        EnvironmentLightState.night,
      ]);
    });
  });

  group('the retired painter is gone, not hidden', () {
    test('its files were deleted', () {
      for (final path in [
        'lib/features/environment/domain/almanac_landscape.dart',
        'lib/features/environment/domain/landscape_appearance.dart',
        'lib/features/environment/presentation/widgets/'
            'almanac_landscape_view.dart',
      ]) {
        expect(File(path).existsSync(), isFalse, reason: path);
      }
    });

    test('and nothing in the app still names it', () {
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) {
            final code = file.readAsStringSync();
            return code.contains('AlmanacLandscape') ||
                code.contains('LandscapeAppearance') ||
                code.contains('LandscapePainter') ||
                code.contains('AlmanacLandscapeView');
          })
          .map((file) => file.path);

      expect(offenders, isEmpty);
    });
  });

  group('the Environment shows the plate', () {
    Future<void> open(
      WidgetTester tester, {
      required DateTime now,
      Size surface = const Size(390, 844),
      double textScale = 1,
    }) async {
      tester.view.physicalSize = surface * 2;
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        ProviderScope(
          overrides: environmentOverrides(
            now: now,
            locationState: const LocationAvailable(TestLocations.london),
          ),
          child: const AlmanacApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    String plate(WidgetTester tester) => tester
        .widget<EnvironmentArtworkView>(find.byType(EnvironmentArtworkView))
        .asset;

    testWidgets('a summer midday shows the summer day plate', (tester) async {
      await open(tester, now: DateTime.utc(2025, 7, 15, 11));
      expect(plate(tester), 'assets/environment/summer_day.webp');
    });

    testWidgets('a winter midnight shows the winter night plate', (
      tester,
    ) async {
      await open(tester, now: DateTime.utc(2025, 1, 15, 22));
      expect(plate(tester), 'assets/environment/winter_night.webp');
    });

    testWidgets('and a change of light changes the plate', (tester) async {
      await open(tester, now: DateTime.utc(2025, 1, 15, 12));
      expect(plate(tester), 'assets/environment/winter_day.webp');

      await open(tester, now: DateTime.utc(2025, 1, 15, 22));
      expect(plate(tester), 'assets/environment/winter_night.webp');
    });

    testWidgets('a change of season changes the plate', (tester) async {
      await open(tester, now: DateTime.utc(2025, 10, 15, 11));
      expect(plate(tester), 'assets/environment/autumn_day.webp');

      await open(tester, now: DateTime.utc(2025, 4, 20, 11));
      expect(plate(tester), 'assets/environment/spring_day.webp');
    });

    testWidgets('the artwork is never distorted', (tester) async {
      await open(tester, now: DateTime.utc(2025, 7, 15, 11));

      // The frame holds the plates' own ratio, so the fit has nothing to
      // crop and nothing to stretch.
      final box = tester.getSize(find.byType(EnvironmentArtworkView));
      expect(
        box.width / box.height,
        closeTo(EnvironmentArtworkView.aspectRatio, 0.01),
      );
      expect(
        tester
            .widget<Image>(
              find.descendant(
                of: find.byType(EnvironmentArtworkView),
                matching: find.byType(Image),
              ),
            )
            .fit,
        BoxFit.cover,
      );
    });

    testWidgets('and it is decorative', (tester) async {
      await open(tester, now: DateTime.utc(2025, 7, 15, 11));

      expect(
        find.descendant(
          of: find.byType(EnvironmentArtworkView),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });

    for (final (name, surface) in [
      ('a phone', Size(390, 844)),
      ('a tablet', Size(834, 1194)),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$name at ${scale}x keeps the artwork square-on', (
          tester,
        ) async {
          await open(
            tester,
            now: DateTime.utc(2025, 7, 15, 11),
            surface: surface,
            textScale: scale,
          );

          expect(tester.takeException(), isNull);

          // The tagline survives every size.
          expect(find.text(EnvironmentText.tagline), findsOneWidget);

          final page = find.byType(Scrollable).first;

          // At double text size the masthead and the date line alone
          // fill a phone, so the painting starts below the fold — which
          // is the point: the page grows and scrolls rather than
          // squeezing the words into the picture. Bring it into view,
          // then measure it.
          await tester.scrollUntilVisible(
            find.byType(EnvironmentArtworkView),
            240,
            scrollable: page,
          );
          final box = tester.getSize(find.byType(EnvironmentArtworkView));
          expect(
            box.width / box.height,
            closeTo(EnvironmentArtworkView.aspectRatio, 0.01),
            reason: '$name at ${scale}x',
          );

          // And the tides stay honest all the way down.
          await tester.scrollUntilVisible(
            find.text(EnvironmentText.tidesValue),
            240,
            scrollable: page,
          );
          expect(find.text(EnvironmentText.tidesValue), findsOneWidget);
        });
      }
    }

    testWidgets('the artwork uses more width than the words do', (
      tester,
    ) async {
      await open(
        tester,
        now: DateTime.utc(2025, 7, 15, 11),
        surface: const Size(834, 1194),
      );

      final artwork = tester.getSize(find.byType(EnvironmentArtworkView)).width;
      final words = tester.getSize(find.text(EnvironmentText.tagline)).width;

      // A wider Almanac page, not a phone layout stranded in the middle
      // of a tablet.
      expect(artwork, greaterThan(640));
      expect(artwork, greaterThan(words));
    });
  });
}
