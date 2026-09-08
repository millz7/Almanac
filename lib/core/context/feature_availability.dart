import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/feature_registry.dart';
import '../settings/settings_providers.dart';

/// The one answer to "is this feature currently part of the user's
/// Almanac?".
///
/// Every cross-feature doorway asks this and nothing else. Before it
/// existed the question could be answered three different ways on three
/// different pages, which is how a stale doorway to a removed feature
/// gets shipped.
///
/// The Environment is always available: it is the living Almanac the
/// whole app is built around, and the user cannot remove it.
@immutable
class AlmanacFeatures {
  const AlmanacFeatures(this.chosen);

  /// The optional features the user has chosen. Never contains
  /// [FeatureId.environment], which is not a choice.
  final Set<FeatureId> chosen;

  bool includes(FeatureId id) =>
      id == FeatureId.environment || chosen.contains(id);

  @override
  bool operator ==(Object other) =>
      other is AlmanacFeatures && setEquals(other.chosen, chosen);

  @override
  int get hashCode => Object.hashAllUnordered(chosen);

  @override
  String toString() =>
      'AlmanacFeatures(${[for (final id in chosen) id.name].join(', ')})';
}

/// What the user's Almanac currently contains.
///
/// Derived from the persisted settings, so it changes the moment they add
/// or remove something — which is what makes a doorway appear and
/// disappear on its own rather than after a restart.
final almanacFeaturesProvider = Provider<AlmanacFeatures>(
  (ref) => AlmanacFeatures({
    for (final feature in ref.watch(userSettingsProvider).chosenFeatures)
      feature.id,
  }),
);

/// Whether one feature is part of the Almanac right now.
///
/// A family so a page can depend on the availability of exactly the one
/// feature it offers a doorway to, and rebuild only when that changes.
final featureAvailableProvider = Provider.family<bool, FeatureId>(
  (ref, id) => ref.watch(almanacFeaturesProvider).includes(id),
);
