import 'dart:io';

import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/features/cycle/application/cycle_providers.dart'
    as cycle;
import 'package:almanac/features/garden/application/garden_providers.dart'
    as garden;
import 'package:almanac/features/nature_log/application/nature_log_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

const auckland = GeoLocation(latitude: -36.85, longitude: 174.76);
const dunedin = GeoLocation(latitude: -45.87, longitude: 170.5);
const chathams = GeoLocation(latitude: -43.95, longitude: 176.55);
const london = GeoLocation(latitude: 51.51, longitude: -0.13);
const sydney = GeoLocation(latitude: -33.87, longitude: 151.21);

void main() {
  setUpAll(useTimeZoneDatabase);

  ProviderContainer containerWith({
    DateTime? now,
    Hemisphere hemisphere = Hemisphere.southern,
    LocationState? locationState,
    NatureLogStore? natureLogStore,
  }) {
    final container = ProviderContainer(
      overrides: environmentOverrides(
        now: now,
        hemisphere: hemisphere,
        locationState: locationState,
        natureLogStore: natureLogStore,
        timeZone: TestTimeZones.wellington,
      ),
    );
    addTearDown(container.dispose);
    return container;
  }

  group('the Nature Log reads the environment the app already resolved', () {
    test('it reads the same day as Cycle and Garden', () {
      final container = containerWith(now: DateTime.utc(2026, 9, 7, 0));

      // One date seam, shared. The Nature Log does not have a
      // `todayProvider` of its own that happens to agree: it re-exports
      // the one Cycle and Garden re-export, and these are the same
      // object.
      expect(todayProvider, same(cycle.todayProvider));
      expect(todayProvider, same(garden.todayProvider));
      expect(container.read(todayProvider), const CalendarDate(2026, 9, 7));
    });

    test('it reads the same season the Environment shows', () {
      final january = containerWith(now: DateTime.utc(2026, 1, 15, 0));
      final july = containerWith(now: DateTime.utc(2026, 7, 15, 0));

      // Southern hemisphere: January is summer, July is winter. The
      // Nature Log never works this out itself; it asks.
      expect(january.read(currentSeasonProvider), Season.summer);
      expect(july.read(currentSeasonProvider), Season.winter);
    });

    test('the season follows the hemisphere, like everywhere else', () {
      final container = containerWith(
        now: DateTime.utc(2026, 1, 15, 12),
        hemisphere: Hemisphere.northern,
      );

      expect(container.read(currentSeasonProvider), Season.winter);
    });

    test('the suggestions follow the month, and only the month', () {
      final september = containerWith(now: DateTime.utc(2026, 9, 15, 0));
      final march = containerWith(now: DateTime.utc(2026, 3, 15, 0));

      final spring = september.read(aroundNowProvider);
      final autumn = march.read(aroundNowProvider);

      expect(spring.today.month, 9);
      expect(autumn.today.month, 3);
      // Two different times of year say different things. If they did
      // not, the seasonal notes would be decoration.
      expect(
        spring.suggestions.map((s) => s.item.id).toSet(),
        isNot(autumn.suggestions.map((s) => s.item.id).toSet()),
      );
    });
  });

  group('coverage', () {
    test('a position in New Zealand gets the New Zealand guide', () {
      final container = containerWith(
        locationState: const LocationAvailable(auckland),
      );

      final guide = container.read(natureGuideProvider);
      expect(guide.coverage, NatureCoverage.newZealand);
      expect(guide.source, NatureCoverageSource.location);
      expect(guide.isUnconfirmed, isFalse);
      expect(container.read(aroundNowProvider).suggestions, isNotEmpty);
    });

    test('and so do the far south and the Chathams', () {
      for (final position in [dunedin, chathams]) {
        final container = containerWith(
          locationState: LocationAvailable(position),
        );

        expect(
          container.read(natureGuideProvider).coverage,
          NatureCoverage.newZealand,
          reason: '$position',
        );
      }
    });

    test('a position outside it gets no guide, and no NZ species', () {
      for (final position in [london, sydney]) {
        final container = containerWith(
          locationState: LocationAvailable(position),
        );

        final guide = container.read(natureGuideProvider);
        expect(guide.coverage, NatureCoverage.unsupported, reason: '$position');
        expect(guide.source, NatureCoverageSource.location);
        // The important half: somebody in London is not told to look
        // out for a tūī.
        expect(
          container.read(aroundNowProvider).suggestions,
          isEmpty,
          reason: '$position',
        );
      }
    });

    test('the southern hemisphere with no position is offered it, hedged', () {
      final container = containerWith(hemisphere: Hemisphere.southern);

      final guide = container.read(natureGuideProvider);
      expect(guide.coverage, NatureCoverage.newZealand);
      expect(guide.source, NatureCoverageSource.hemisphere);
      // Offered, and marked as a guess rather than a fact about where
      // they are.
      expect(guide.isUnconfirmed, isTrue);
    });

    test('the northern hemisphere with no position is offered nothing', () {
      final container = containerWith(hemisphere: Hemisphere.northern);

      expect(
        container.read(natureGuideProvider).coverage,
        NatureCoverage.unsupported,
      );
      expect(container.read(aroundNowProvider).suggestions, isEmpty);
    });

    test('a refused or denied permission is coverage by hemisphere', () {
      for (final state in const [
        LocationPermissionDenied(),
        LocationPermissionPermanentlyDenied(),
        LocationUnavailable(),
        LocationPermissionNotRequested(),
      ]) {
        final container = containerWith(
          locationState: state,
          hemisphere: Hemisphere.southern,
        );

        expect(
          container.read(natureGuideProvider).source,
          NatureCoverageSource.hemisphere,
          reason: '$state',
        );
      }
    });

    test('the position decides, not the stored preference', () {
      final container = containerWith(
        hemisphere: Hemisphere.northern,
        locationState: const LocationAvailable(auckland),
      );

      // A New Zealand position while the preference says north: the
      // guide follows the position, and the preference is left alone.
      expect(
        container.read(natureGuideProvider).coverage,
        NatureCoverage.newZealand,
      );
      expect(
        container.read(userSettingsProvider).hemisphere,
        Hemisphere.northern,
      );
    });
  });

  group('recording works wherever somebody is', () {
    test('with no location at all', () async {
      final container = containerWith(hemisphere: Hemisphere.northern);
      await container.read(natureLogProvider.future);

      await container
          .read(natureLogProvider.notifier)
          .recordCustom(
            name: 'A small brown bird',
            category: NatureCategory.bird,
          );

      // No guide, and the log still works: the coverage model gates
      // suggestions, never the user's own record.
      expect(container.read(aroundNowProvider).suggestions, isEmpty);
      expect(container.read(natureLogProvider).value!.length, 1);
    });

    test('and outside the guide, with a place in their own words', () async {
      final container = containerWith(
        locationState: const LocationAvailable(london),
      );
      await container.read(natureLogProvider.future);

      await container
          .read(natureLogProvider.notifier)
          .recordCustom(
            name: 'Robin',
            category: NatureCategory.bird,
            placeLabel: 'Hampstead Heath',
          );

      final observation = container.read(natureLogProvider).value!.recent.first;
      expect(observation.label, 'Robin');
      expect(observation.placeLabel, 'Hampstead Heath');
    });

    test('and the date recorded is the shared calendar day', () async {
      final container = containerWith(now: DateTime.utc(2026, 9, 7, 0));
      await container.read(natureLogProvider.future);

      await container
          .read(natureLogProvider.notifier)
          .recordFromBook(item: NatureBook.all.first);

      expect(
        container.read(natureLogProvider).value!.recent.first.date,
        container.read(todayProvider),
      );
    });
  });

  group('what the Nature Log does not do', () {
    test('opening it asks for no location', () async {
      final service = FakeLocationService(
        checkResult: const LocationPermissionNotRequested(),
      );
      final container = ProviderContainer(
        overrides: environmentOverrides(locationService: service),
      );
      addTearDown(container.dispose);

      // Everything the feature reads when it opens.
      container.read(natureGuideProvider);
      container.read(aroundNowProvider);
      container.read(currentSeasonProvider);
      container.read(todayProvider);
      await container.read(natureLogProvider.future);

      expect(service.requestCount, 0);
    });

    test('it persists no coordinates, whatever it was given', () async {
      final store = InMemoryNatureLogStore();
      final container = containerWith(
        locationState: const LocationAvailable(auckland),
        natureLogStore: store,
      );
      await container.read(natureLogProvider.future);

      await container
          .read(natureLogProvider.notifier)
          .recordCustom(
            name: 'Kingfisher',
            category: NatureCategory.bird,
            note: 'On the power line',
          );

      final stored = encodeLog(await store.read()).join('\n');
      // A position was available the whole time. None of it is here.
      expect(stored, contains('Kingfisher'));
      expect(stored, isNot(contains('-36.85')));
      expect(stored, isNot(contains('174.76')));
      expect(stored, isNot(contains('latitude')));
      expect(stored, isNot(contains('longitude')));
    });

    test(
      'it calculates no date, season, hemisphere or position of its own',
      () {
        final sources = Directory('lib/features/nature_log')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'));

        for (final file in sources) {
          // Comments are prose about the design; the check is about the
          // code. A doc comment saying "no coordinates, ever" must not
          // fail a test looking for coordinates.
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
            'GeoLocation(',
            'latitude:',
            'longitude:',
            'geocod',
            'http',
          ]) {
            expect(
              code.contains(forbidden),
              isFalse,
              reason: '${file.path} uses $forbidden',
            );
          }
        }
      },
    );

    test('it asks for no new permission', () {
      // The declared permissions only: the manifest's own comment
      // explains why fine location is absent, and a check that tripped
      // on that sentence would be measuring the wrong thing.
      final declared = File('android/app/src/main/AndroidManifest.xml')
          .readAsLinesSync()
          .where((line) => line.contains('uses-permission'))
          .join('\n');

      expect(declared, contains('ACCESS_COARSE_LOCATION'));
      expect(declared, isNot(contains('ACCESS_FINE_LOCATION')));
      expect(declared, isNot(contains('ACCESS_BACKGROUND_LOCATION')));
      expect(declared, isNot(contains('CAMERA')));
      expect(declared, isNot(contains('RECORD_AUDIO')));
      expect(declared, isNot(contains('READ_MEDIA_IMAGES')));
      expect(declared, isNot(contains('READ_EXTERNAL_STORAGE')));
    });
  });
}
