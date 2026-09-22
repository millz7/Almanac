import 'geo_location.dart';
import 'local_time_zone.dart';
import 'tide.dart';

/// What a fetch found: a usable curve, or a clean "nothing here" answer.
///
/// Distinct from [TideServiceFailure] — a location the marine model
/// genuinely has no water data for (well inland, say) is not an error,
/// it is a valid result the app should remember rather than retry.
sealed class TideFetchResult {
  const TideFetchResult();
}

/// A usable tide curve was returned.
final class TideFetchData extends TideFetchResult {
  const TideFetchData(this.snapshot);

  final TideSnapshot snapshot;
}

/// The provider answered, but had nothing usable for this position —
/// every sample in the requested window came back null or missing,
/// which is how Open-Meteo represents a grid cell with no marine data
/// (well inland, typically).
final class TideFetchNoData extends TideFetchResult {
  const TideFetchNoData();
}

/// Fetches a tide curve for a position. Behind an interface, like
/// [WeatherService], so a test never touches the network and the app is
/// not tightly coupled to Open-Meteo.
abstract interface class TideService {
  /// Throws [TideServiceFailure] on any network, HTTP or parsing
  /// failure. Callers — see `TideController` — are expected to catch it
  /// and fall back gracefully rather than let it reach the UI.
  Future<TideFetchResult> fetch({
    required GeoLocation location,
    required LocalTimeZone timeZone,
    required DateTime now,
  });
}
