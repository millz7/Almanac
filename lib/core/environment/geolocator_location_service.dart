import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'geo_location.dart';
import 'location_service.dart';
import 'location_state.dart';

/// The real platform location service.
///
/// This is the **only** file in the app that imports geolocator or knows
/// anything about Android permissions. Everything else works against
/// [LocationService] and [LocationState].
///
/// Two deliberate limits:
///
/// * Only "while in use" permission is ever requested. Background
///   location is never asked for, and [LocationPermission.always] is
///   treated the same as while-in-use — the app has no use for more.
/// * Position is requested at [LocationAccuracy.low], which on Android
///   is served by the coarse-location permission the app declares. That
///   is a few hundred metres to a few kilometres, which is ample for
///   seasons and sunrise/sunset, and it is markedly less intrusive than
///   a precise fix.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  /// How long to wait for a fix before giving up. A position that never
  /// arrives must not leave the user staring at a spinner.
  static const _timeout = Duration(seconds: 15);

  @override
  Future<LocationState> currentState() async {
    try {
      final permission = await Geolocator.checkPermission();
      final refusal = _refusalFor(permission);
      if (refusal != null) return refusal;
      return await _readPosition();
    } on Object catch (error) {
      // A failure to read location must never take the app down; the
      // user simply keeps the hemisphere they chose.
      return LocationUnavailable('checking location failed: $error');
    }
  }

  @override
  Future<LocationState> requestAccess() async {
    try {
      var permission = await Geolocator.checkPermission();

      // Asking again after a permanent denial does nothing on Android, so
      // report the state rather than pretending a prompt appeared.
      if (permission == LocationPermission.deniedForever) {
        return const LocationPermissionPermanentlyDenied();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
      }

      final refusal = _refusalFor(permission);
      if (refusal != null) return refusal;
      return await _readPosition();
    } on Object catch (error) {
      return LocationUnavailable('requesting location failed: $error');
    }
  }

  @override
  Future<bool> openSystemSettings() async {
    try {
      // The platform's own app-settings page. Once permission is
      // permanently denied this is the only way back, and Android gives
      // no way to re-prompt from inside the app.
      return await Geolocator.openAppSettings();
    } on Object catch (error) {
      debugPrint('Could not open app settings: $error');
      return false;
    }
  }

  /// Maps a permission result to a refusal state, or null when the app is
  /// allowed to read a position.
  LocationState? _refusalFor(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.denied => const LocationPermissionDenied(),
        LocationPermission.deniedForever =>
          const LocationPermissionPermanentlyDenied(),
        LocationPermission.unableToDetermine =>
          const LocationPermissionNotRequested(),
        LocationPermission.whileInUse || LocationPermission.always => null,
      };

  Future<LocationState> _readPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationUnavailable('location services are switched off');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: _timeout,
      ),
    );

    final location = GeoLocation.tryCreate(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (location == null) {
      return const LocationUnavailable('platform returned invalid coordinates');
    }
    return LocationAvailable(
      location,
      accuracyMetres: position.accuracy,
      obtainedAt: DateTime.now().toUtc(),
    );
  }
}
