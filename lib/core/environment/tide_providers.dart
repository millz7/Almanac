import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'environment_providers.dart';
import 'geo_location.dart';
import 'open_meteo_marine_tide_service.dart';
import 'tide.dart';
import 'tide_service.dart';

/// How long a fetched tide curve is trusted before the app asks again.
///
/// The same reasoning as `kWeatherCacheDuration`, and deliberately the
/// same duration: tide freshness, like weather freshness, is a
/// different question from GPS freshness, and asking the marine
/// endpoint more often than this would spend more of the free tier's
/// daily allowance for no change a person would actually notice.
const kTideCacheDuration = Duration(minutes: 45);

/// The tide source. Behind an interface, like every other environment
/// service, so a test never touches the network.
final tideServiceProvider = Provider<TideService>(
  (ref) => const OpenMeteoMarineTideService(),
);

/// The tide, right now: which of the four [TideState]s applies, and the
/// curve when there is one.
///
/// **Reads the shared location; never acquires its own.** Exactly the
/// same rule as [weatherControllerProvider] — "one place, one clock, one
/// Almanac" — and the same reason there is no timer and no polling loop
/// here: [build] re-runs only when [locationStateProvider] changes or
/// something explicitly invalidates this provider, and even then makes a
/// real request only when the held state is missing, for a different
/// position, or older than [kTideCacheDuration].
///
/// **A known "no data here" answer is cached too**, not just a
/// successful fetch — see [TideController.build] — which is what keeps a
/// clearly inland position from being asked again every time this
/// provider happens to rebuild.
final tideControllerProvider = AsyncNotifierProvider<TideController, TideState>(
  TideController.new,
);

class TideController extends AsyncNotifier<TideState> {
  /// The most recent state this controller actually resolved, and where
  /// and when it resolved it — kept outside Riverpod's own state, the
  /// same way `WeatherController` keeps its last fetch, so a rebuild
  /// triggered by an unrelated change can decide to reuse it without an
  /// `await`.
  TideState? _lastState;
  GeoLocation? _lastLocation;
  DateTime? _lastResolvedAt;

  /// The request already on its way, and where it is for — the same
  /// one-at-a-time rule as the weather's.
  Future<TideFetchResult>? _inFlight;
  GeoLocation? _inFlightFor;

  Future<TideFetchResult> _fetchOnce(GeoLocation location, DateTime now) {
    final pending = _inFlight;
    final pendingFor = _inFlightFor;
    if (pending != null &&
        pendingFor != null &&
        _sameApproximateLocation(pendingFor, location)) {
      return pending;
    }
    final request = ref
        .read(tideServiceProvider)
        .fetch(
          location: location,
          timeZone: ref.read(timeZoneProvider),
          now: now,
        );
    _inFlight = request;
    _inFlightFor = location;
    void settle() {
      if (identical(_inFlight, request)) _inFlight = null;
    }

    request.then((_) => settle(), onError: (Object _) => settle());
    return request;
  }

  @override
  Future<TideState> build() async {
    final location = ref.watch(locationStateProvider).location;
    if (location == null) {
      _lastState = null;
      _lastLocation = null;
      _lastResolvedAt = null;
      // No location shared: no request is made at all, not even a
      // coarse or IP-based guess.
      return const TideLocationRequired();
    }

    final now = ref.watch(clockProvider)();
    if (_stillFresh(location, now)) return _lastState!;

    try {
      final result = await _fetchOnce(location, now);
      final state = switch (result) {
        TideFetchData(:final snapshot) => TideAvailable(snapshot),
        TideFetchNoData() => const TideUnavailableForLocation(),
      };
      _lastState = state;
      _lastLocation = location;
      _lastResolvedAt = now;
      return state;
    } on Object {
      // A network failure, a timeout, or a response that could not be
      // parsed. A still-usable cached curve for roughly the same place
      // is better than nothing; otherwise the honest answer is that the
      // provider is unreachable, not a guess dressed up as a reading.
      final cached = _lastState;
      if (cached is TideAvailable &&
          _sameApproximateLocation(cached.snapshot.location, location) &&
          _covers(cached.snapshot, now)) {
        return cached;
      }
      return const TideProviderUnavailable();
    }
  }

  /// Whether a held curve still reaches past [now] — a tide curve is a
  /// prediction, so an older one stays true for as long as it runs, but
  /// no longer.
  bool _covers(TideSnapshot snapshot, DateTime now) =>
      snapshot.samples.isNotEmpty &&
      !snapshot.samples.first.time.isAfter(now.toUtc()) &&
      snapshot.samples.last.time.isAfter(now.toUtc());

  bool _stillFresh(GeoLocation location, DateTime now) {
    final resolvedAt = _lastResolvedAt;
    final resolvedLocation = _lastLocation;
    if (resolvedAt == null || resolvedLocation == null) return false;
    if (!_sameApproximateLocation(resolvedLocation, location)) return false;
    return now.toUtc().difference(resolvedAt.toUtc()) <= kTideCacheDuration;
  }

  /// Whether two positions are close enough that the same tide answer —
  /// a curve, or "nothing here" — reasonably describes both. The same
  /// precision the network request itself rounds to, so a few metres of
  /// GPS jitter between reads never counts as "moved".
  bool _sameApproximateLocation(GeoLocation a, GeoLocation b) =>
      (a.latitude - b.latitude).abs() < 0.01 &&
      (a.longitude - b.longitude).abs() < 0.01;
}
