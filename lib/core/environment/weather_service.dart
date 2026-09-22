import 'geo_location.dart';
import 'local_time_zone.dart';
import 'weather.dart';

/// Fetches a forecast for a position. Behind an interface — the same
/// shape as SolarService/MoonService/SeasonService — so Almanac is not
/// tightly coupled to Open-Meteo or to the network at all; a test
/// substitutes a fake that never touches a socket.
abstract interface class WeatherService {
  /// Throws [WeatherServiceFailure] on any network, HTTP or parsing
  /// failure. Callers — see `WeatherController` — are expected to catch
  /// it and fall back gracefully rather than let it reach the UI.
  Future<WeatherSnapshot> fetch({
    required GeoLocation location,
    required LocalTimeZone timeZone,
    required DateTime now,
  });
}
