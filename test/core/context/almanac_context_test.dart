import 'dart:io';

import 'package:almanac/core/context/almanac_context.dart';
import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/moon_service.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/features/cycle/application/cycle_providers.dart'
    as cycle;
import 'package:almanac/features/garden/application/garden_providers.dart'
    as garden;
import 'package:almanac/features/nature_log/application/nature_log_providers.dart'
    as nature;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// A moon pinned to one phase, so a test about the shared context is not
/// also a test of the date it happens to be.
class _FixedMoonService implements MoonService {
  const _FixedMoonService(this.state);

  final MoonPhaseState state;

  @override
  MoonPhaseState phaseAt(DateTime instant) => state;
}

const _newMoon = MoonPhaseState(
  phase: MoonPhase.newMoon,
  elongationDegrees: 2,
  illuminatedFraction: 0.001,
);

const wellington = GeoLocation(latitude: -41.29, longitude: 174.78);

void main() {
  setUpAll(useTimeZoneDatabase);

  ProviderContainer containerWith({
    DateTime? now,
    Hemisphere hemisphere = Hemisphere.northern,
    Set<FeatureId> features = const {},
    LocationState? locationState,
    MoonService? moonService,
  }) {
    final container = ProviderContainer(
      overrides: [
        ...environmentOverrides(
          now: now,
          hemisphere: hemisphere,
          features: features,
          locationState: locationState,
        ),
        if (moonService != null)
          moonServiceProvider.overrideWithValue(moonService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('one source of each fact', () {
    test('one date, shared by every feature that has one', () {
      final container = containerWith(now: DateTime.utc(2026, 9, 7, 12));

      // Not four providers that agree: one provider, re-exported. The
      // identity is the test — agreement can be a coincidence.
      expect(todayProvider, same(cycle.todayProvider));
      expect(todayProvider, same(garden.todayProvider));
      expect(todayProvider, same(nature.todayProvider));
      expect(container.read(todayProvider), const CalendarDate(2026, 9, 7));
    });

    test('one season, and the shared moment carries that one', () {
      final container = containerWith(
        now: DateTime.utc(2026, 1, 15, 12),
        hemisphere: Hemisphere.southern,
      );

      expect(container.read(currentSeasonProvider), Season.summer);
      expect(
        container.read(almanacMomentProvider).season,
        container.read(currentSeasonProvider),
      );
    });

    test('one moon, from the service the environment already asks', () {
      final container = containerWith(
        moonService: const _FixedMoonService(_newMoon),
      );

      expect(container.read(currentMoonProvider).phase, MoonPhase.newMoon);
      expect(
        container.read(almanacMomentProvider).moon.phase,
        MoonPhase.newMoon,
      );
    });

    test('and the moon the environment resolved wins once it has', () async {
      final container = containerWith(
        moonService: const _FixedMoonService(_newMoon),
        locationState: const LocationAvailable(wellington),
      );

      // Before the environment resolves, the selector falls back to the
      // same service; afterwards it reads the resolved value. Either
      // way there is one answer.
      final early = container.read(currentMoonProvider).phase;
      await container.read(naturalEnvironmentProvider.future);
      expect(container.read(currentMoonProvider).phase, early);
      expect(
        container.read(currentMoonProvider).phase,
        container.read(naturalEnvironmentProvider).value!.moon.phase,
      );
    });

    test('one hemisphere, the one the environment resolved', () {
      final container = containerWith(
        hemisphere: Hemisphere.northern,
        locationState: const LocationAvailable(wellington),
      );

      // A southern position while the preference says north: the
      // context follows the position, exactly as the Environment does.
      expect(
        container.read(almanacMomentProvider).hemisphere,
        Hemisphere.southern,
      );
    });

    test('daylight says nothing until it is actually known', () async {
      final container = containerWith();

      expect(container.read(currentDaylightProvider), isNull);
      expect(container.read(almanacMomentProvider).hasDaylight, isFalse);

      await container.read(naturalEnvironmentProvider.future);

      expect(container.read(currentDaylightProvider), isNotNull);
      expect(container.read(almanacMomentProvider).hasDaylight, isTrue);
    });

    test('the moment is a value, and says nothing revealing', () {
      final container = containerWith(
        now: DateTime.utc(2026, 9, 7, 12),
        moonService: const _FixedMoonService(_newMoon),
      );

      final moment = container.read(almanacMomentProvider);
      expect(moment, container.read(almanacMomentProvider));
      expect(moment.toString(), contains('New Moon'));
      expect(moment.toString(), isNot(contains('latitude')));
    });
  });

  group('feature availability', () {
    test('reflects what the user actually chose', () {
      final container = containerWith(
        features: {FeatureId.meditation, FeatureId.garden},
      );

      expect(
        container.read(featureAvailableProvider(FeatureId.meditation)),
        isTrue,
      );
      expect(
        container.read(featureAvailableProvider(FeatureId.garden)),
        isTrue,
      );
      expect(
        container.read(featureAvailableProvider(FeatureId.cookbook)),
        isFalse,
      );
    });

    test('the Environment is always available, chosen or not', () {
      final container = containerWith();

      expect(
        container.read(featureAvailableProvider(FeatureId.environment)),
        isTrue,
      );
      expect(
        container.read(almanacFeaturesProvider).chosen,
        isNot(contains(FeatureId.environment)),
      );
    });

    test('and it changes the moment the Almanac does', () async {
      final container = containerWith();
      expect(
        container.read(featureAvailableProvider(FeatureId.meditation)),
        isFalse,
      );

      await container
          .read(userSettingsProvider.notifier)
          .setFeatureChosen(FeatureId.meditation, true);

      expect(
        container.read(featureAvailableProvider(FeatureId.meditation)),
        isTrue,
      );

      await container
          .read(userSettingsProvider.notifier)
          .setFeatureChosen(FeatureId.meditation, false);

      expect(
        container.read(featureAvailableProvider(FeatureId.meditation)),
        isFalse,
      );
    });

    test('every feature can be asked about, with no gaps', () {
      final container = containerWith(features: FeatureId.values.toSet());

      for (final id in FeatureId.values) {
        expect(
          container.read(featureAvailableProvider(id)),
          isTrue,
          reason: id.name,
        );
      }
    });
  });

  group('contextual intents', () {
    test('are values: the same context is the same intent', () {
      expect(
        const MoonMeditationIntent(MoonPhase.fullMoon),
        const MoonMeditationIntent(MoonPhase.fullMoon),
      );
      expect(
        const MoonMeditationIntent(MoonPhase.fullMoon),
        isNot(const MoonMeditationIntent(MoonPhase.newMoon)),
      );
    });

    test('name their destination and read the same way every time', () {
      for (final phase in MoonPhase.values) {
        final intent = MoonMeditationIntent(phase);
        expect(intent.destination, FeatureId.meditation);
        expect(intent.heading, "For today's ${phase.label}");
        // Deterministic: no clock, no store, no position behind it.
        expect(intent.heading, MoonMeditationIntent(phase).heading);
      }
    });

    test('nothing is waiting until a doorway opens one', () {
      final container = containerWith();

      expect(container.read(almanacIntentProvider), isNull);
      expect(
        container
            .read(almanacIntentProvider.notifier)
            .take(FeatureId.meditation),
        isNull,
      );
    });

    test('the destination takes it once, and it is then gone', () {
      final container = containerWith();
      final intents = container.read(almanacIntentProvider.notifier);

      intents.open(const MoonMeditationIntent(MoonPhase.newMoon));

      expect(
        intents.take(FeatureId.meditation),
        const MoonMeditationIntent(MoonPhase.newMoon),
      );
      // Taken means spent: a second arrival finds nothing.
      expect(intents.take(FeatureId.meditation), isNull);
      expect(container.read(almanacIntentProvider), isNull);
    });

    test('somewhere else cannot take it by accident', () {
      final container = containerWith();
      final intents = container.read(almanacIntentProvider.notifier);

      intents.open(const MoonMeditationIntent(MoonPhase.newMoon));

      expect(intents.take(FeatureId.cookbook), isNull);
      // And it is still there for the destination it was meant for.
      expect(intents.take(FeatureId.meditation), isNotNull);
    });
  });

  group('what the shared context does not do', () {
    test('reading all of it asks for no location', () async {
      final service = FakeLocationService(
        checkResult: const LocationPermissionNotRequested(),
      );
      final container = ProviderContainer(
        overrides: environmentOverrides(locationService: service),
      );
      addTearDown(container.dispose);

      container.read(almanacMomentProvider);
      container.read(currentMoonProvider);
      container.read(currentDaylightProvider);
      container.read(almanacFeaturesProvider);
      container.read(featureAvailableProvider(FeatureId.meditation));

      expect(service.requestCount, 0);
    });

    test('it calculates no season, moon or date of its own', () {
      final sources = Directory('lib/core/context')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      expect(sources, isNotEmpty);
      for (final file in sources) {
        // Comments are prose about the design; the check is about the
        // code.
        final code = file
            .readAsLinesSync()
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');

        for (final forbidden in [
          'DateTime.now',
          'seasonAt(',
          'MoonCalculator',
          'phaseAt(DateTime',
          'ofLatitude',
          'requestAccess',
          'Geolocator',
          'latitude',
          'longitude',
        ]) {
          expect(
            code.contains(forbidden),
            isFalse,
            reason: '${file.path} uses $forbidden',
          );
        }
      }
    });

    test('it keeps no history and persists nothing', () {
      final code = Directory('lib/core/context')
          .listSync(recursive: true)
          .whereType<File>()
          .expand((file) => file.readAsLinesSync())
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');

      for (final forbidden in [
        'SharedPreferences',
        'Store',
        'jsonEncode',
        'http',
        'history',
      ]) {
        expect(code, isNot(contains(forbidden)), reason: forbidden);
      }
    });

    test('reading everything twice settles, with no circular dependency', () {
      final container = containerWith(
        features: {FeatureId.meditation},
        moonService: const _FixedMoonService(_newMoon),
      );

      // A cycle between these would not return at all; that it does, and
      // returns the same values, is the assertion.
      final first = container.read(almanacMomentProvider);
      final second = container.read(almanacMomentProvider);
      expect(first, second);
      expect(
        container.read(almanacFeaturesProvider).includes(FeatureId.meditation),
        isTrue,
      );
    });
  });
}
