import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'day_night.dart';
import 'geo_location.dart';
import 'location_service.dart';
import 'natural_environment.dart';
import 'season.dart';
import 'season_service.dart';
import 'solar_service.dart';

/// The app's clock, injected so tests can pin "now" to a fixed instant.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Where the user is. Swap the implementation here when the real location
/// service is built — nothing else needs to change.
final locationServiceProvider = Provider<LocationService>(
  (ref) => const DeviceOffsetLocationService(),
);

/// Sunrise/sunset source. Currently a documented placeholder.
final solarServiceProvider = Provider<SolarService>(
  (ref) => const PlaceholderSolarService(),
);

/// Season calculation. Real astronomy, no placeholder needed.
final seasonServiceProvider = Provider<SeasonService>(
  (ref) => const AstronomicalSeasonService(),
);

/// Hemisphere used before the real location has resolved. Only affects the
/// first frame or two; see [DeviceOffsetLocationService] for the caveat.
const kBootstrapHemisphere = Hemisphere.northern;

/// Whether the environment schedules its own refreshes (see
/// [NaturalEnvironmentNotifier._scheduleNextRefresh]).
///
/// Always true in the running app. Tests override it to false so a
/// long-lived timer is not left pending behind a finished test.
final environmentRefreshEnabledProvider = Provider<bool>((ref) => true);

/// The single source of truth for the user's natural environment.
///
/// Resolves location → season → sunrise/sunset → day/night once, then
/// schedules itself to re-resolve when something can actually have changed
/// (see [_scheduleNextRefresh]). It never polls on a short interval.
final naturalEnvironmentProvider =
    AsyncNotifierProvider<NaturalEnvironmentNotifier, NaturalEnvironment>(
      NaturalEnvironmentNotifier.new,
    );

/// How often the state refreshes *while* easing through dawn or dusk. Only
/// active during the twilight window, so this costs roughly twenty extra
/// rebuilds a day rather than one a second.
const kTwilightRefreshInterval = Duration(minutes: 2);

/// Upper bound on how long we will sleep between refreshes. A season
/// boundary can be months away; waking every few hours instead keeps the
/// state honest if the device clock or time zone changes underneath us.
const kMaxRefreshInterval = Duration(hours: 6);

class NaturalEnvironmentNotifier extends AsyncNotifier<NaturalEnvironment> {
  Timer? _refreshTimer;

  @override
  Future<NaturalEnvironment> build() async {
    ref.onDispose(() => _refreshTimer?.cancel());

    final now = ref.watch(clockProvider)();
    final location = await ref.watch(locationServiceProvider).currentLocation();
    final season = ref
        .watch(seasonServiceProvider)
        .seasonAt(now, location.hemisphere);
    final events = await ref
        .watch(solarServiceProvider)
        .eventsFor(location, now);
    final dayNight = resolveDayNight(instant: now, events: events);

    if (ref.watch(environmentRefreshEnabledProvider)) {
      _scheduleNextRefresh(
        now: now,
        location: location,
        season: season,
        dayNight: dayNight,
      );
    }

    return NaturalEnvironment(
      location: location,
      season: season,
      dayNight: dayNight,
    );
  }

  /// Re-resolves immediately. Called when the app returns to the
  /// foreground, since an unknown amount of time may have passed.
  void refresh() => ref.invalidateSelf();

  void _scheduleNextRefresh({
    required DateTime now,
    required GeoLocation location,
    required SeasonState season,
    required DayNightState dayNight,
  }) {
    _refreshTimer?.cancel();

    final target = _earliest([
      _nextDayNightChange(now, location, dayNight),
      season.endsAt,
    ]);

    final delay = target.difference(now.toUtc());
    _refreshTimer = Timer(_clampDelay(delay), () => ref.invalidateSelf());
  }

  /// When the day/night state can next differ.
  DateTime _nextDayNightChange(
    DateTime now,
    GeoLocation location,
    DayNightState dayNight,
  ) {
    // Mid-transition: step forward in small increments so the palette
    // eases rather than jumping.
    if (dayNight.isTransitioning) {
      return now.toUtc().add(kTwilightRefreshInterval);
    }
    // Known boundary later today.
    final next = dayNight.nextChangeAt;
    if (next != null) return next;
    // After dusk: tomorrow's sunrise needs tomorrow's solar events, so
    // wake at the start of the next local day and resolve again then.
    final localMidnight = location.localMidnight(now);
    return location.toInstant(localMidnight.add(const Duration(days: 1)));
  }

  Duration _clampDelay(Duration delay) {
    if (delay > kMaxRefreshInterval) return kMaxRefreshInterval;
    // Guard against a zero/negative delay spinning the timer.
    const minimum = Duration(seconds: 30);
    return delay < minimum ? minimum : delay;
  }

  DateTime _earliest(List<DateTime> instants) =>
      instants.reduce((a, b) => a.isBefore(b) ? a : b);
}
