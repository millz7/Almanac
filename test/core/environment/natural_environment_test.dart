import 'package:almanac/core/environment/day_night.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/natural_environment.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';

void main() {
  /// Builds a container with the clock and both async services pinned, so
  /// the resolved environment is fully deterministic.
  ProviderContainer containerAt({
    required DateTime now,
    required GeoLocation location,
    required DateTime sunrise,
    required DateTime sunset,
  }) {
    final container = ProviderContainer(
      overrides: [
        environmentRefreshEnabledProvider.overrideWithValue(false),
        clockProvider.overrideWithValue(() => now),
        locationServiceProvider.overrideWithValue(
          FakeLocationService(location),
        ),
        solarServiceProvider.overrideWithValue(
          FakeSolarService(sunrise: sunrise, sunset: sunset),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<NaturalEnvironment> resolve(ProviderContainer container) =>
      container.read(naturalEnvironmentProvider.future);

  test('resolves season and day/night from the injected services', () async {
    final container = containerAt(
      now: DateTime.utc(2025, 7, 15, 12),
      location: TestLocations.london,
      sunrise: DateTime.utc(2025, 7, 15, 5),
      sunset: DateTime.utc(2025, 7, 15, 21),
    );

    final environment = await resolve(container);

    expect(environment.season.season, Season.summer);
    expect(environment.dayNight.phase, DayPhase.day);
    expect(environment.dayNight.daylight, 1);
    expect(environment.location, same(TestLocations.london));
  });

  test('the same instant gives opposite seasons in each hemisphere', () async {
    final now = DateTime.utc(2025, 7, 15, 12);

    final northern = await resolve(
      containerAt(
        now: now,
        location: TestLocations.london,
        sunrise: DateTime.utc(2025, 7, 15, 5),
        sunset: DateTime.utc(2025, 7, 15, 21),
      ),
    );
    final southern = await resolve(
      containerAt(
        now: now,
        location: TestLocations.wellington,
        sunrise: DateTime.utc(2025, 7, 14, 19),
        sunset: DateTime.utc(2025, 7, 15, 5),
      ),
    );

    expect(northern.season.season, Season.summer);
    expect(southern.season.season, Season.winter);
  });

  test('night is reported when the instant falls outside the sun', () async {
    final container = containerAt(
      now: DateTime.utc(2025, 1, 20, 2),
      location: TestLocations.london,
      sunrise: DateTime.utc(2025, 1, 20, 8),
      sunset: DateTime.utc(2025, 1, 20, 16),
    );

    final environment = await resolve(container);

    expect(environment.season.season, Season.winter);
    expect(environment.dayNight.phase, DayPhase.night);
    expect(environment.dayNight.daylight, 0);
  });

  test('mid-dusk reports a partial daylight value', () async {
    final sunset = DateTime.utc(2025, 4, 20, 19);
    final container = containerAt(
      now: sunset,
      location: TestLocations.london,
      sunrise: DateTime.utc(2025, 4, 20, 6),
      sunset: sunset,
    );

    final environment = await resolve(container);

    expect(environment.dayNight.phase, DayPhase.dusk);
    expect(environment.dayNight.daylight, closeTo(0.5, 0.01));
    expect(environment.dayNight.isTransitioning, isTrue);
  });
}
