import 'dart:io';

import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/features/garden/application/garden_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

const auckland = GeoLocation(latitude: -36.85, longitude: 174.76);
const dunedin = GeoLocation(latitude: -45.87, longitude: 170.5);
const london = GeoLocation(latitude: 51.51, longitude: -0.13);

void main() {
  setUpAll(useTimeZoneDatabase);

  ProviderContainer containerWith({
    DateTime? now,
    Hemisphere hemisphere = Hemisphere.southern,
    LocationState? locationState,
  }) {
    final container = ProviderContainer(
      overrides: environmentOverrides(
        now: now,
        hemisphere: hemisphere,
        locationState: locationState,
      ),
    );
    addTearDown(container.dispose);
    return container;
  }

  group('Garden agrees with the Environment', () {
    test('it reads the same date the rest of the app does', () {
      final container = containerWith(now: DateTime.utc(2026, 9, 7, 12));

      // The shared seam, not a clock of its own.
      expect(container.read(todayProvider).month, 9);
      expect(container.read(todayProvider).day, 7);
    });

    test('a southern date resolves a southern guide and season', () {
      final container = containerWith(
        now: DateTime.utc(2026, 1, 15, 12),
        hemisphere: Hemisphere.southern,
      );

      // Mid-January in the south is summer, and the Garden's guide is
      // the southern one.
      expect(container.read(currentSeasonProvider), Season.summer);
      expect(
        container.read(gardeningGuideProvider).region,
        GardeningRegion.genericSouthern,
      );
    });

    test('a northern date resolves a northern guide and season', () {
      final container = containerWith(
        now: DateTime.utc(2026, 1, 15, 12),
        hemisphere: Hemisphere.northern,
      );

      // The same instant, the other hemisphere: winter, northern guide.
      expect(container.read(currentSeasonProvider), Season.winter);
      expect(
        container.read(gardeningGuideProvider).region,
        GardeningRegion.genericNorthern,
      );
    });

    test('a shared location gives a place-based band', () {
      final container = containerWith(
        locationState: const LocationAvailable(auckland),
      );

      final guide = container.read(gardeningGuideProvider);
      expect(guide.region, GardeningRegion.nzNorthern);
      expect(guide.source, GuideSource.location);
      expect(guide.isLocationBacked, isTrue);
    });

    test('and the band follows the position, not the preference', () {
      final container = containerWith(
        hemisphere: Hemisphere.northern,
        locationState: const LocationAvailable(dunedin),
      );

      // Location wins for calculation, exactly as the Environment
      // resolves it — and the stored preference is left alone.
      expect(
        container.read(gardeningGuideProvider).region,
        GardeningRegion.nzSouthern,
      );
      expect(
        container.read(userSettingsProvider).hemisphere,
        Hemisphere.northern,
      );
    });

    test('a location outside New Zealand degrades honestly', () {
      final container = containerWith(
        locationState: const LocationAvailable(london),
      );

      expect(
        container.read(gardeningGuideProvider).region,
        GardeningRegion.genericNorthern,
      );
    });
  });

  group('with no location', () {
    test('it uses the hemisphere guide, and says which', () {
      final container = containerWith(hemisphere: Hemisphere.southern);

      final guide = container.read(gardeningGuideProvider);
      expect(guide.region, GardeningRegion.genericSouthern);
      expect(guide.source, GuideSource.hemisphere);
      expect(guide.isLocationBacked, isFalse);
      expect(guide.region.label, 'General Southern Hemisphere guide');
    });

    test('and the feature still works', () {
      final container = containerWith(
        now: DateTime.utc(2026, 10, 15, 12),
        hemisphere: Hemisphere.southern,
      );

      expect(container.read(generalGuideProvider).sow, isNotEmpty);
    });

    test('permanently denied location is still a working guide', () {
      final container = containerWith(
        locationState: const LocationPermissionPermanentlyDenied(),
        hemisphere: Hemisphere.southern,
      );

      expect(
        container.read(gardeningGuideProvider).region,
        GardeningRegion.genericSouthern,
      );
      expect(container.read(generalGuideProvider).sow, isA<List>());
    });
  });

  group('what Garden does not do', () {
    test('it never asks for location', () async {
      final service = FakeLocationService(
        checkResult: const LocationPermissionNotRequested(),
      );
      final container = ProviderContainer(
        overrides: environmentOverrides(locationService: service),
      );
      addTearDown(container.dispose);

      // Reading everything the Garden reads must not prompt anybody.
      container.read(gardeningGuideProvider);
      container.read(generalGuideProvider);
      container.read(personalGuideProvider);
      await container.read(myGardenProvider.future);

      expect(service.requestCount, 0);
      expect(container.read(locationStateProvider), isA<LocationState>());
    });

    test('it calculates no season, hemisphere or date of its own', () {
      final sources = Directory('lib/features/garden')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in sources) {
        final code = file
            .readAsLinesSync()
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');

        for (final forbidden in [
          'DateTime.now',
          'seasonAt(',
          'SeasonService',
          'ofLatitude',
          'requestAccess',
          'Geolocator',
        ]) {
          expect(
            code.contains(forbidden),
            isFalse,
            reason: '${file.path} uses $forbidden',
          );
        }
      }
    });

    test('it asks for no new permission', () {
      // The declared permissions, not the prose: the manifest's own
      // comment explains that fine location is deliberately not asked
      // for, and a check that failed on that sentence would be
      // measuring the wrong thing.
      final declared = File('android/app/src/main/AndroidManifest.xml')
          .readAsLinesSync()
          .where((line) => line.contains('uses-permission'))
          .join('\n');

      expect(declared, contains('ACCESS_COARSE_LOCATION'));
      expect(declared, isNot(contains('ACCESS_FINE_LOCATION')));
      expect(declared, isNot(contains('ACCESS_BACKGROUND_LOCATION')));
      expect(declared, isNot(contains('CAMERA')));
      expect(declared, isNot(contains('RECORD_AUDIO')));
    });
  });
}
