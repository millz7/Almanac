import 'package:flutter/foundation.dart';

/// Which half of the world the user is in. Determines whether the June
/// solstice means summer or winter.
///
/// This is the app's only representation of a hemisphere — never strings
/// like "north"/"south".
enum Hemisphere {
  northern('Northern Hemisphere'),
  southern('Southern Hemisphere');

  const Hemisphere(this.label);

  /// Human-readable name, for onboarding and future settings UI.
  final String label;

  /// The hemisphere a latitude falls in.
  ///
  /// **Equator rule:** latitude 0.0 is treated as [northern]. The choice is
  /// arbitrary but it must be deterministic — an "undefined" third state
  /// would have to be handled by every caller, and the four-season model
  /// does not describe equatorial climates anyway. Someone on the equator
  /// can override this with the manual hemisphere choice in onboarding.
  static Hemisphere ofLatitude(double latitude) =>
      latitude < 0 ? Hemisphere.southern : Hemisphere.northern;
}

/// A precise position on the Earth.
///
/// This type exists **only when the app genuinely knows where the user
/// is** — that is, when location permission was granted and a fix was
/// obtained. It is never fabricated, and there is no "fallback" instance:
/// when location is unknown the app holds `null` here and falls back to
/// the hemisphere the user chose. See [LocationState].
///
/// The time zone is deliberately not part of this type; see
/// [LocalTimeZone].
@immutable
class GeoLocation {
  /// For known-good coordinates, such as constants in tests.
  const GeoLocation({required this.latitude, required this.longitude})
    : assert(
        latitude >= -90 && latitude <= 90,
        'latitude must be between -90 and 90',
      ),
      assert(
        longitude >= -180 && longitude <= 180,
        'longitude must be between -180 and 180',
      );

  /// For coordinates arriving from the platform, which cannot be trusted
  /// to be in range or even to be numbers. Returns null rather than
  /// throwing, so a bad fix degrades to "location unavailable" instead of
  /// crashing the app.
  static GeoLocation? tryCreate({
    required double latitude,
    required double longitude,
  }) {
    if (latitude.isNaN || longitude.isNaN) return null;
    if (latitude < -90 || latitude > 90) return null;
    if (longitude < -180 || longitude > 180) return null;
    return GeoLocation(latitude: latitude, longitude: longitude);
  }

  /// Degrees north (positive) or south (negative) of the equator.
  final double latitude;

  /// Degrees east (positive) or west (negative) of Greenwich.
  final double longitude;

  /// The hemisphere this position is in. See [Hemisphere.ofLatitude] for
  /// how the equator is handled.
  Hemisphere get hemisphere => Hemisphere.ofLatitude(latitude);

  @override
  bool operator ==(Object other) =>
      other is GeoLocation &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoLocation(lat: $latitude, lon: $longitude)';
}
