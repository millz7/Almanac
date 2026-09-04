import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_providers.dart';
import 'day_night.dart';
import 'geo_location.dart';
import 'geolocator_location_service.dart';
import 'local_time_zone.dart';
import 'location_service.dart';
import 'location_state.dart';
import 'natural_environment.dart';
import 'season.dart';
import 'season_service.dart';
import 'solar_service.dart';

/// The app's clock, injected so tests can pin "now" to a fixed instant.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The device's time zone. Always available, no permission needed.
final timeZoneProvider = Provider<LocalTimeZone>(
  (ref) => LocalTimeZone.ofDevice(),
);

/// The platform location service. Tests override it; nothing else in the
/// app knows which implementation is behind it.
final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

/// Sunrise/sunset source. Currently a documented placeholder.
final solarServiceProvider = Provider<SolarService>(
  (ref) => const PlaceholderSolarService(),
);

/// Season calculation. Real astronomy, no placeholder needed.
final seasonServiceProvider = Provider<SeasonService>(
  (ref) => const AstronomicalSeasonService(),
);

/// The hemisphere assumed when the app knows nothing at all — no location
/// and no choice yet.
///
/// This is a **technical** fallback for rendering the very first frame of
/// onboarding, not an assumption about the user. As soon as they choose,
/// their choice takes over; it is never used to decide anybody's season
/// after that.
const kTechnicalFallbackHemisphere = Hemisphere.northern;

/// The app's access to the user's position.
///
/// Starts out as "never asked" and only changes when the app checks
/// ([refresh], which never prompts) or the user asks for it
/// ([requestAccess], the only thing that can show a permission dialog).
final locationStateProvider =
    NotifierProvider<LocationController, LocationState>(LocationController.new);

class LocationController extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationPermissionNotRequested();

  /// Re-checks permission without prompting. Called at startup and on
  /// resume, so permission granted or revoked in system settings is
  /// picked up.
  Future<void> refresh() async {
    state = await _guard(
      () => ref.read(locationServiceProvider).currentState(),
    );
  }

  /// Asks the user for location access. Only ever called from a
  /// deliberate tap.
  Future<void> requestAccess() async {
    state = await _guard(
      () => ref.read(locationServiceProvider).requestAccess(),
    );
  }

  /// The app must survive any failure down in the platform layer: without
  /// location it simply keeps using the hemisphere the user chose.
  Future<LocationState> _guard(Future<LocationState> Function() read) async {
    try {
      return await read();
    } on Object catch (error) {
      return LocationUnavailable('location lookup failed: $error');
    }
  }
}

/// Which hemisphere the app should use, and where that came from.
///
/// Priority, as required by the product rules:
///
/// 1. A real latitude, when the user has shared their location.
/// 2. Otherwise the hemisphere they chose themselves.
/// 3. Otherwise — only before onboarding — a technical fallback.
///
/// Note what this does *not* do: when location becomes available it is
/// used for calculations, but the user's stored preference is left
/// exactly as they set it. The two are kept side by side rather than one
/// silently overwriting the other.
final resolvedHemisphereProvider = Provider<ResolvedHemisphere>((ref) {
  final location = ref.watch(locationStateProvider).location;
  if (location != null) {
    return ResolvedHemisphere(
      hemisphere: location.hemisphere,
      source: HemisphereSource.derivedFromLocation,
    );
  }

  final chosen = ref.watch(userSettingsProvider).hemisphere;
  if (chosen != null) {
    return ResolvedHemisphere(
      hemisphere: chosen,
      source: HemisphereSource.userSelected,
    );
  }

  return const ResolvedHemisphere(
    hemisphere: kTechnicalFallbackHemisphere,
    source: HemisphereSource.technicalFallback,
  );
});

/// Whether the environment schedules its own refreshes (see
/// [NaturalEnvironmentNotifier._scheduleNextRefresh]).
///
/// Always true in the running app. Tests override it to false so a
/// long-lived timer is not left pending behind a finished test.
final environmentRefreshEnabledProvider = Provider<bool>((ref) => true);

/// The single source of truth for the user's natural environment.
///
/// Resolves hemisphere → season → sunrise/sunset → day/night, then
/// schedules itself to re-resolve when something can actually have
/// changed (see [_scheduleNextRefresh]). It never polls on a short
/// interval. Because it watches [resolvedHemisphereProvider], choosing a
/// hemisphere in onboarding recomputes the season immediately.
final naturalEnvironmentProvider =
    AsyncNotifierProvider<NaturalEnvironmentNotifier, NaturalEnvironment>(
      NaturalEnvironmentNotifier.new,
    );

/// How often the state refreshes *while* easing through dawn or dusk.
/// Only active during the twilight window, so this costs roughly twenty
/// extra rebuilds a day rather than one a second.
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
    final timeZone = ref.watch(timeZoneProvider);
    final resolved = ref.watch(resolvedHemisphereProvider);
    final location = ref.watch(locationStateProvider).location;

    final season = ref
        .watch(seasonServiceProvider)
        .seasonAt(now, resolved.hemisphere);
    final events = await ref
        .watch(solarServiceProvider)
        .eventsFor(instant: now, timeZone: timeZone, location: location);
    final dayNight = resolveDayNight(instant: now, events: events);

    if (ref.watch(environmentRefreshEnabledProvider)) {
      _scheduleNextRefresh(
        now: now,
        timeZone: timeZone,
        season: season,
        dayNight: dayNight,
      );
    }

    return NaturalEnvironment(
      hemisphere: resolved.hemisphere,
      hemisphereSource: resolved.source,
      timeZone: timeZone,
      season: season,
      dayNight: dayNight,
      location: location,
    );
  }

  /// Re-resolves immediately. Called when the app returns to the
  /// foreground, since an unknown amount of time may have passed.
  void refresh() => ref.invalidateSelf();

  void _scheduleNextRefresh({
    required DateTime now,
    required LocalTimeZone timeZone,
    required SeasonState season,
    required DayNightState dayNight,
  }) {
    _refreshTimer?.cancel();

    final target = _earliest([
      _nextDayNightChange(now, timeZone, dayNight),
      season.endsAt,
    ]);

    final delay = target.difference(now.toUtc());
    _refreshTimer = Timer(_clampDelay(delay), () => ref.invalidateSelf());
  }

  /// When the day/night state can next differ.
  DateTime _nextDayNightChange(
    DateTime now,
    LocalTimeZone timeZone,
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
    return timeZone.midnightOf(now).add(const Duration(days: 1));
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
