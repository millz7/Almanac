import 'package:flutter/foundation.dart';

import '../environment/geo_location.dart';

/// The small set of choices the user has made, persisted between launches.
///
/// Deliberately tiny. Precise location is **not** stored here: the app
/// asks the platform for a position when it needs one, so there is no
/// copy of the user's whereabouts sitting on disk.
@immutable
class UserSettings {
  const UserSettings({this.hemisphere, this.locationIntroSeen = false});

  /// The hemisphere the user chose during onboarding, or null if they
  /// have not chosen yet. Null is what makes onboarding appear.
  ///
  /// This is never overwritten by a location-derived hemisphere — it is
  /// the user's stated preference, and it remains the fallback whenever
  /// precise location is unavailable.
  final Hemisphere? hemisphere;

  /// Whether the user has been shown the explanation of what location is
  /// for. Recorded so the app introduces it once and then leaves them
  /// alone, whichever way they answered.
  final bool locationIntroSeen;

  UserSettings copyWith({Hemisphere? hemisphere, bool? locationIntroSeen}) =>
      UserSettings(
        hemisphere: hemisphere ?? this.hemisphere,
        locationIntroSeen: locationIntroSeen ?? this.locationIntroSeen,
      );

  @override
  bool operator ==(Object other) =>
      other is UserSettings &&
      other.hemisphere == hemisphere &&
      other.locationIntroSeen == locationIntroSeen;

  @override
  int get hashCode => Object.hash(hemisphere, locationIntroSeen);

  @override
  String toString() =>
      'UserSettings(hemisphere: ${hemisphere?.name ?? 'unset'}, '
      'locationIntroSeen: $locationIntroSeen)';
}
