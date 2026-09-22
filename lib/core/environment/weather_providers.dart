import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'environment_providers.dart';
import 'geo_location.dart';
import 'open_meteo_weather_service.dart';
import 'weather.dart';
import 'weather_service.dart';

/// How long a fetched forecast is trusted before the app asks again.
///
/// Weather freshness is a different question from GPS freshness — see
/// `kPositionMaxAge` — and deliberately looser: a forecast is still a
/// reasonable description of "now" three-quarters of an hour after it
/// was fetched, and fetching more often than this would mean nothing
/// more than spending more of the free tier's daily allowance for no
/// real benefit to what the app says.
const kWeatherCacheDuration = Duration(minutes: 45);

/// The weather source. Behind an interface, like every other environment
/// service, so a test never touches the network.
final weatherServiceProvider = Provider<WeatherService>(
  (ref) => const OpenMeteoWeatherService(),
);

/// The most recent forecast, or null.
///
/// **Reads the shared location; never acquires its own.** This watches
/// [locationStateProvider] — the same position Environment, Garden and
/// everything else already share — and never calls a location service
/// directly. "One place, one clock, one Almanac" holds for weather too.
///
/// **Foreground-only, and genuinely cached.** [build] re-runs whenever
/// the shared location changes (which includes a resume-time re-check
/// that often reports the identical fix as a new object), but it only
/// makes a real request when the held forecast is missing, for a
/// different position, or older than [kWeatherCacheDuration] — see
/// [_stillFresh]. There is no timer here and no polling loop: the only
/// things that can trigger a rebuild are a location change or something
/// explicitly invalidating this provider.
///
/// Null covers every reason there is nothing to show — no location
/// permission, no network, a provider failure, an unparseable response —
/// deliberately without distinguishing them to a consumer: every
/// feature's answer to "is there weather to say something about?" is one
/// null check, and the Almanac stays fully usable either way.
final weatherControllerProvider =
    AsyncNotifierProvider<WeatherController, WeatherSnapshot?>(
      WeatherController.new,
    );

class WeatherController extends AsyncNotifier<WeatherSnapshot?> {
  /// The last snapshot this controller actually fetched, kept outside
  /// Riverpod's own state so a rebuild triggered by an unrelated
  /// location-object change can decide to reuse it without an `await`.
  WeatherSnapshot? _lastFetch;

  @override
  Future<WeatherSnapshot?> build() async {
    final location = ref.watch(locationStateProvider).location;
    if (location == null) {
      // No location shared: no request is made at all, not even a
      // coarse or IP-based guess.
      _lastFetch = null;
      return null;
    }

    final now = ref.watch(clockProvider)();
    final cached = _lastFetch;
    if (cached != null && _stillFresh(cached, location, now)) {
      return cached;
    }

    try {
      final snapshot = await ref
          .read(weatherServiceProvider)
          .fetch(
            location: location,
            timeZone: ref.read(timeZoneProvider),
            now: now,
          );
      _lastFetch = snapshot;
      return snapshot;
    } on Object {
      // A network failure, a timeout, or a response that could not be
      // parsed. A still-usable cached forecast for roughly the same
      // place is better than nothing; otherwise there is simply no
      // weather this time, and the app carries on without it.
      if (cached != null &&
          _sameApproximateLocation(cached.location, location)) {
        return cached;
      }
      return null;
    }
  }

  bool _stillFresh(
    WeatherSnapshot cached,
    GeoLocation location,
    DateTime now,
  ) =>
      _sameApproximateLocation(cached.location, location) &&
      !cached.isStaleAt(now, kWeatherCacheDuration);

  /// Whether two positions are close enough that the same forecast
  /// reasonably describes both — rounded to the same precision the
  /// network request itself uses, so a few metres of GPS jitter between
  /// reads never counts as "moved".
  bool _sameApproximateLocation(GeoLocation a, GeoLocation b) =>
      (a.latitude - b.latitude).abs() < 0.01 &&
      (a.longitude - b.longitude).abs() < 0.01;
}
