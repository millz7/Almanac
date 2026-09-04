import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

void main() {
  setUpAll(useTimeZoneDatabase);

  final now = DateTime.utc(2025, 7, 15, 12);

  ProviderContainer containerWith(
    FakeLocationService service, {
    LocationState? startingState,
  }) {
    final container = ProviderContainer(
      overrides: environmentOverrides(
        now: now,
        locationService: service,
        locationState: startingState,
      ),
    );
    addTearDown(container.dispose);
    return container;
  }

  group('the app does not read the position more than it needs to', () {
    test('a fresh fix is reused rather than re-read', () async {
      final service = FakeLocationService(
        checkResult: LocationAvailable(
          TestLocations.wellington,
          obtainedAt: now.subtract(const Duration(minutes: 2)),
        ),
      );
      final container = containerWith(
        service,
        startingState: LocationAvailable(
          TestLocations.wellington,
          obtainedAt: now.subtract(const Duration(minutes: 2)),
        ),
      );

      await container.read(locationStateProvider.notifier).refresh();

      expect(
        service.checkCount,
        0,
        reason: 'a two-minute-old fix does not need replacing',
      );
    });

    test('a stale fix is re-read', () async {
      final service = FakeLocationService(
        checkResult: LocationAvailable(
          TestLocations.wellington,
          obtainedAt: now,
        ),
      );
      final container = containerWith(
        service,
        startingState: LocationAvailable(
          TestLocations.wellington,
          // Older than the maximum age.
          obtainedAt: now.subtract(kPositionMaxAge * 2),
        ),
      );

      await container.read(locationStateProvider.notifier).refresh();

      expect(service.checkCount, 1);
    });

    test('a fix with no timestamp is treated as stale', () async {
      final service = FakeLocationService(
        checkResult: const LocationAvailable(TestLocations.wellington),
      );
      final container = containerWith(
        service,
        startingState: const LocationAvailable(TestLocations.wellington),
      );

      await container.read(locationStateProvider.notifier).refresh();

      expect(service.checkCount, 1);
    });

    test('forcing a refresh always re-reads, however fresh the fix', () async {
      final service = FakeLocationService(
        checkResult: LocationAvailable(
          TestLocations.wellington,
          obtainedAt: now,
        ),
      );
      final container = containerWith(
        service,
        startingState: LocationAvailable(
          TestLocations.wellington,
          obtainedAt: now,
        ),
      );

      await container.read(locationStateProvider.notifier).refresh(force: true);

      expect(service.checkCount, 1);
    });

    test('with no fix yet, a refresh does ask the platform', () async {
      final service = FakeLocationService();
      final container = containerWith(service);

      await container.read(locationStateProvider.notifier).refresh();

      expect(service.checkCount, 1);
      // Checking is not prompting.
      expect(service.requestCount, 0);
    });
  });

  group('fix metadata', () {
    test('accuracy and age travel with the state', () {
      final obtained = now.subtract(const Duration(minutes: 5));
      final state = LocationAvailable(
        TestLocations.wellington,
        accuracyMetres: 1200,
        obtainedAt: obtained,
      );

      expect(state.accuracyMetres, 1200);
      expect(state.obtainedAt, obtained);
      expect(state.isStaleAt(now, const Duration(minutes: 15)), isFalse);
      expect(state.isStaleAt(now, const Duration(minutes: 2)), isTrue);
    });
  });

  group('opening system settings', () {
    test('is delegated to the platform, not reinvented', () async {
      final service = FakeLocationService();
      final container = containerWith(service);

      final opened = await container
          .read(locationStateProvider.notifier)
          .openSystemSettings();

      expect(opened, isTrue);
      expect(service.openSettingsCount, 1);
    });

    test('a platform failure is reported rather than thrown', () async {
      final container = ProviderContainer(
        overrides: environmentOverrides(
          now: now,
          locationService: const ThrowingLocationService(),
        ),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(locationStateProvider.notifier).openSystemSettings(),
        completion(isFalse),
      );
    });
  });
}
