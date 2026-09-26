import 'package:flutter/material.dart';

import 'feature_definition.dart';
import 'feature_id.dart';

export 'feature_definition.dart';
export 'feature_id.dart';

/// The catalogue of everything the app can contain.
///
/// One list, in the order features appear in the navigation bar and in
/// the Almanac drawer. Nothing else in the app hard-codes a feature name.
///
/// [environment] is first and is marked core: it is the living Almanac
/// the whole app is built around, so it is not offered as a choice and
/// cannot be switched off.
abstract final class FeatureRegistry {
  static const environment = FeatureDefinition(
    id: FeatureId.environment,
    name: 'Environment',
    shortName: 'Env',
    icon: Icons.wb_twilight_outlined,
    selectedIcon: Icons.wb_twilight,
    route: '/environment',
    description: 'The season, the sky, the sun and the moon where you are.',
    placeholderMessage: '',
    isCore: true,
  );

  /// The features a user chooses between, in display order.
  static const optional = <FeatureDefinition>[
    FeatureDefinition(
      id: FeatureId.meditation,
      name: 'Meditation',
      shortName: 'Med',
      icon: Icons.self_improvement_outlined,
      selectedIcon: Icons.self_improvement,
      route: '/meditation',
      description: 'Create stillness, reflect',
      placeholderMessage:
          'Space to sit still will live here — practices that follow the '
          'light rather than a clock.',
    ),
    FeatureDefinition(
      id: FeatureId.yoga,
      name: 'Yoga',
      shortName: 'Yoga',
      icon: Icons.accessibility_new_outlined,
      selectedIcon: Icons.accessibility_new,
      route: '/yoga',
      description: 'Movement that connects your body to the world around you',
      placeholderMessage:
          'Sequences to move through will live here, gentler in winter and '
          'brighter in summer.',
    ),
    FeatureDefinition(
      id: FeatureId.chakras,
      name: 'Chakras',
      shortName: 'Chak',
      icon: Icons.blur_circular_outlined,
      selectedIcon: Icons.blur_circular,
      route: '/chakras',
      description: 'The body\'s centres of energy.',
      placeholderMessage:
          'The seven centres, what they govern and how to work with them '
          'will live here.',
    ),
    FeatureDefinition(
      id: FeatureId.cycle,
      name: 'Cycle',
      shortName: 'Cycle',
      icon: Icons.brightness_3_outlined,
      selectedIcon: Icons.brightness_3,
      route: '/cycle',
      description: 'Track your period, in connection with the moon',
      placeholderMessage:
          'Your cycle will live here, kept on this device and set beside '
          'the moon rather than a chart.',
    ),
    FeatureDefinition(
      id: FeatureId.cookbook,
      name: 'Cookbook',
      shortName: 'Cook',
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant,
      route: '/cookbook',
      description: 'Suggested recipes for each season',
      placeholderMessage:
          'Things to cook will live here, led by what is actually in season '
          'where you are.',
    ),
    FeatureDefinition(
      id: FeatureId.garden,
      name: 'Garden',
      shortName: 'Garden',
      icon: Icons.local_florist_outlined,
      selectedIcon: Icons.local_florist,
      route: '/garden',
      description: 'What to sow, tend and harvest',
      placeholderMessage:
          'Sowing, tending and harvesting will live here, timed to your '
          'hemisphere rather than to a generic calendar.',
    ),
    FeatureDefinition(
      id: FeatureId.natureLog,
      name: 'Nature Log',
      shortName: 'Nature',
      icon: Icons.forest_outlined,
      selectedIcon: Icons.forest,
      route: '/nature-log',
      description: 'The flora and fauna around you',
      placeholderMessage:
          'What you see, hear and notice outdoors will be recorded here.',
    ),
    FeatureDefinition(
      id: FeatureId.wheel,
      name: 'Wheel of the Year',
      // The page, the drawer and onboarding all say "Wheel of the Year";
      // only the crowded bottom bar shortens it, first to "Holidays" and
      // then, if it still will not fit, to "Hols".
      navLabel: 'Holidays',
      shortName: 'Hols',
      icon: Icons.donut_large_outlined,
      selectedIcon: Icons.donut_large,
      route: '/wheel',
      description: 'Seasonal festivals, traditions and ways to celebrate',
      placeholderMessage:
          'The eight festivals of the Wheel of the Year will live here, '
          'turning with your own hemisphere.',
    ),
    FeatureDefinition(
      id: FeatureId.journal,
      name: 'Journal',
      shortName: 'Jour',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      route: '/journal',
      description: 'A private page for each day you choose to write',
      placeholderMessage:
          'A page for each day you choose to write will live here, kept '
          'on this device.',
    ),
  ];

  /// Every feature, core first.
  static const all = <FeatureDefinition>[environment, ...optional];

  /// The definition for an id. Total, because every [FeatureId] has one —
  /// a missing entry is a programming error, not a runtime condition.
  static FeatureDefinition byId(FeatureId id) =>
      all.firstWhere((feature) => feature.id == id);

  /// The feature that owns [route], or null if the route belongs to
  /// something else — onboarding, or the developer preview.
  static FeatureDefinition? forRoute(String route) {
    for (final feature in all) {
      if (route == feature.route) return feature;
    }
    return null;
  }
}
