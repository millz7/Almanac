import 'package:flutter/foundation.dart';

import '../environment/geo_location.dart';
import '../features/feature_registry.dart';

/// A sentinel meaning "leave this alone", for [UserSettings.copyWith].
///
/// Needed because the name is nullable and clearing it is a real
/// operation: without this, `copyWith(name: null)` could not be told
/// apart from `copyWith()`.
const _keep = Object();

/// The small set of choices the user has made, persisted between
/// launches.
///
/// Deliberately tiny, and deliberately local. There is no account, no
/// identifier and nothing that leaves the device. Precise location is
/// **not** stored here either: the app asks the platform for a position
/// when it needs one, so there is no copy of the user's whereabouts
/// sitting on disk.
@immutable
class UserSettings {
  const UserSettings({
    this.name,
    this.nameAsked = false,
    this.hemisphere,
    this.locationIntroSeen = false,
    this.features = const {},
    this.onboardingCompleted = false,
  });

  /// What the user would like to be called, or null if they have not said.
  ///
  /// Optional on purpose. It is used for one thing — the title of their
  /// Almanac — and someone who skips the question gets "Your Almanac"
  /// instead of being nagged.
  final String? name;

  /// Whether the name question has been put to them.
  ///
  /// A separate flag because a null name is a perfectly good answer, so
  /// "no name" cannot be used to mean "not asked yet".
  final bool nameAsked;

  /// The hemisphere the user chose during onboarding, or null if they
  /// have not chosen yet.
  ///
  /// This is never overwritten by a location-derived hemisphere — it is
  /// the user's stated preference, and it remains the fallback whenever
  /// precise location is unavailable. See `ResolvedHemisphere`.
  final Hemisphere? hemisphere;

  /// Whether the user has been shown the explanation of what location is
  /// for. Recorded so the app introduces it once and then leaves them
  /// alone, whichever way they answered.
  final bool locationIntroSeen;

  /// The parts of the app the user has asked for.
  ///
  /// Never contains [FeatureId.environment]: the Environment is part of
  /// the app rather than a choice, so storing it as one would invite code
  /// that could switch it off. An empty set is a valid answer.
  final Set<FeatureId> features;

  /// Whether first-launch setup has been finished.
  ///
  /// The authoritative flag. The individual answers above cannot stand in
  /// for it, because every one of them has a legitimate "no" — no name,
  /// no location, no features.
  final bool onboardingCompleted;

  /// The chosen features in registry order, so the navigation bar and the
  /// drawer agree on the order regardless of the order they were picked.
  List<FeatureDefinition> get chosenFeatures => [
    for (final feature in FeatureRegistry.optional)
      if (features.contains(feature.id)) feature,
  ];

  /// Whether [id] is part of this Almanac. The Environment always is.
  bool includes(FeatureId id) =>
      id == FeatureId.environment || features.contains(id);

  /// Pass `name: null` to clear the name; omit it to leave it as it is.
  UserSettings copyWith({
    Object? name = _keep,
    bool? nameAsked,
    Hemisphere? hemisphere,
    bool? locationIntroSeen,
    Set<FeatureId>? features,
    bool? onboardingCompleted,
  }) => UserSettings(
    name: name == _keep ? this.name : name as String?,
    nameAsked: nameAsked ?? this.nameAsked,
    hemisphere: hemisphere ?? this.hemisphere,
    locationIntroSeen: locationIntroSeen ?? this.locationIntroSeen,
    features: features ?? this.features,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
  );

  @override
  bool operator ==(Object other) =>
      other is UserSettings &&
      other.name == name &&
      other.nameAsked == nameAsked &&
      other.hemisphere == hemisphere &&
      other.locationIntroSeen == locationIntroSeen &&
      setEquals(other.features, features) &&
      other.onboardingCompleted == onboardingCompleted;

  @override
  int get hashCode => Object.hash(
    name,
    nameAsked,
    hemisphere,
    locationIntroSeen,
    Object.hashAllUnordered(features),
    onboardingCompleted,
  );

  @override
  String toString() =>
      'UserSettings(name: ${name ?? 'none'}, asked: $nameAsked, '
      'hemisphere: ${hemisphere?.name ?? 'unset'}, '
      'locationIntroSeen: $locationIntroSeen, '
      'features: {${features.map((f) => f.name).join(', ')}}, '
      'onboardingCompleted: $onboardingCompleted)';
}
