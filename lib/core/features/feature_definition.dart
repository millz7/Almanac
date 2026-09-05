import 'package:flutter/widgets.dart';

import 'feature_id.dart';

/// Everything the app needs to know about one feature in order to show
/// it, name it and navigate to it.
///
/// This is the only place a feature's wording, icon or route is written
/// down. Screens, the navigation bar and the Almanac drawer all read from
/// here, so adding a feature is one entry in [FeatureRegistry] rather
/// than a search for every place its name was typed.
@immutable
class FeatureDefinition {
  const FeatureDefinition({
    required this.id,
    required this.name,
    required this.shortName,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.description,
    required this.placeholderMessage,
    this.isCore = false,
  });

  final FeatureId id;

  /// The full, proper name: "Nature Log". Used everywhere there is room,
  /// and always used as the accessibility label — even when the visible
  /// navigation label has been shortened.
  final String name;

  /// The deliberate short form for a crowded navigation bar: "Nature".
  ///
  /// A chosen word, never a truncation. The app must never render
  /// "Nature..." — see `AlmanacNavigationBar`.
  final String shortName;

  final IconData icon;
  final IconData selectedIcon;

  /// The route this feature owns. Registered for every feature whether or
  /// not the user has chosen it, so re-enabling one works immediately.
  final String route;

  /// A short line for the Almanac drawer, saying what choosing this would
  /// add.
  final String description;

  /// What the feature's screen says while it is not built yet.
  final String placeholderMessage;

  /// True for the one feature that is part of the app rather than a
  /// choice. A core feature is never offered for selection and can never
  /// be switched off.
  final bool isCore;

  @override
  String toString() => 'FeatureDefinition(${id.name})';
}
