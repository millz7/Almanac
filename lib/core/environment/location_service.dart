import 'location_state.dart';

/// The app's only route to the user's position.
///
/// Nothing above this interface knows that Android, permissions or
/// geolocator exist. The two methods are deliberately different:
/// [currentState] must never show a permission dialog, while
/// [requestAccess] is the one place that may.
abstract interface class LocationService {
  /// Reports the current state **without prompting**.
  ///
  /// Safe to call on every launch and on resume: it is how the app
  /// notices that permission was granted or revoked in system settings.
  Future<LocationState> currentState();

  /// Whether permission is still granted and location services are still
  /// on — checked **without prompting and without reading a position**.
  ///
  /// The cheap question asked on resume while a fix is still fresh: a
  /// permission revoked in system settings, or a one-time grant that has
  /// lapsed, must not leave the app claiming a location it no longer
  /// has.
  Future<bool> stillPermitted();

  /// Asks the user for permission, then tries to obtain a position.
  ///
  /// Only ever called in response to a deliberate user action. Returns
  /// the resulting state; it does not throw for an ordinary refusal.
  Future<LocationState> requestAccess();

  /// Opens the platform's own settings page for this app, which is the
  /// only route back once the user has permanently denied permission.
  ///
  /// Returns whether the page could be opened.
  Future<bool> openSystemSettings();
}

/// A location service that always reports "unavailable".
///
/// Used as a safe default where no platform is present — tests, and any
/// build without the platform implementation wired up. The app must work
/// with this, since it is indistinguishable from a user who declines.
class UnavailableLocationService implements LocationService {
  const UnavailableLocationService();

  @override
  Future<LocationState> currentState() async =>
      const LocationUnavailable('no location service configured');

  @override
  Future<bool> stillPermitted() async => false;

  @override
  Future<LocationState> requestAccess() async =>
      const LocationUnavailable('no location service configured');

  @override
  Future<bool> openSystemSettings() async => false;
}
