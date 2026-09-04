import 'package:flutter/foundation.dart';

import 'geo_location.dart';

/// Everything the app can know about its access to the user's position.
///
/// A sealed hierarchy rather than a scatter of booleans (`hasLocation`,
/// `locationDenied`, `permissionAsked`…): those can express nonsense
/// combinations, whereas exactly one of these is true at a time and
/// `switch` over them is checked by the compiler.
@immutable
sealed class LocationState {
  const LocationState();

  /// The position, when there is one. Null in every state but
  /// [LocationAvailable].
  GeoLocation? get location => null;

  /// Whether asking for permission could still succeed. False once the
  /// user has permanently denied it — at that point only the system
  /// settings can change the answer, so the app must stop asking.
  bool get canRequest => switch (this) {
    LocationPermissionNotRequested() => true,
    LocationPermissionDenied() => true,
    LocationUnavailable() => true,
    LocationPermissionPermanentlyDenied() => false,
    LocationAvailable() => false,
  };
}

/// The app has never asked. This is the state on first launch, and it is
/// where the app stays until the user actively chooses to share location.
final class LocationPermissionNotRequested extends LocationState {
  const LocationPermissionNotRequested();
}

/// The user declined. They may be asked again later, but only if they
/// initiate it — the app never re-prompts on its own.
final class LocationPermissionDenied extends LocationState {
  const LocationPermissionDenied();
}

/// The user declined in a way the system will not prompt for again.
/// Enabling location now requires a trip to system settings.
final class LocationPermissionPermanentlyDenied extends LocationState {
  const LocationPermissionPermanentlyDenied();
}

/// Permission is not the problem — the position could not be obtained.
/// Location services are switched off, the platform failed, or the fix
/// was invalid.
final class LocationUnavailable extends LocationState {
  const LocationUnavailable([this.reason]);

  /// Developer-facing detail. Not shown to the user as-is.
  final String? reason;

  @override
  String toString() => 'LocationUnavailable(${reason ?? 'no reason given'})';
}

/// The app knows where the user is.
final class LocationAvailable extends LocationState {
  const LocationAvailable(this.location);

  @override
  final GeoLocation location;

  @override
  String toString() => 'LocationAvailable($location)';
}
