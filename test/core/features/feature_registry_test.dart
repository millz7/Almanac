import 'package:almanac/core/features/feature_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the catalogue', () {
    test('holds the Environment and the seven choosable features', () {
      expect(FeatureRegistry.all.length, 8);
      expect(FeatureRegistry.optional.length, 7);
      expect(FeatureRegistry.all.first, same(FeatureRegistry.environment));
    });

    test('names every feature the product asked for', () {
      expect(FeatureRegistry.optional.map((feature) => feature.name).toList(), [
        'Meditation',
        'Yoga',
        'Chakras',
        'Cycle',
        'Cookbook',
        'Garden',
        'Nature Log',
      ]);
    });

    test('uses the agreed short names for a crowded bar', () {
      expect(
        {
          for (final feature in FeatureRegistry.all)
            feature.name: feature.shortName,
        },
        {
          'Environment': 'Env',
          'Meditation': 'Med',
          'Yoga': 'Yoga',
          'Chakras': 'Chak',
          'Cycle': 'Cycle',
          'Cookbook': 'Cook',
          'Garden': 'Garden',
          'Nature Log': 'Nature',
        },
      );
    });

    test('every short name is a word, never a truncation', () {
      for (final feature in FeatureRegistry.all) {
        expect(
          feature.shortName,
          isNot(contains('.')),
          reason: '${feature.name} must not be shortened with an ellipsis',
        );
        expect(
          feature.shortName.length,
          lessThanOrEqualTo(feature.name.length),
        );
        expect(feature.shortName, isNotEmpty);
      }
    });

    test('the Environment is the only one that is part of the app', () {
      expect(FeatureRegistry.environment.isCore, isTrue);
      for (final feature in FeatureRegistry.optional) {
        expect(
          feature.isCore,
          isFalse,
          reason: '${feature.name} must be removable',
        );
      }
    });
  });

  group('identity', () {
    test('every id has exactly one definition', () {
      for (final id in FeatureId.values) {
        expect(FeatureRegistry.byId(id).id, id);
      }
      expect(
        FeatureRegistry.all.map((feature) => feature.id).toSet().length,
        FeatureId.values.length,
      );
    });

    test('routes are unique and reversible', () {
      final routes = FeatureRegistry.all.map((feature) => feature.route);
      expect(routes.toSet().length, routes.length);

      for (final feature in FeatureRegistry.all) {
        expect(FeatureRegistry.forRoute(feature.route), same(feature));
      }
    });

    test('a route that belongs to nothing is not claimed by a feature', () {
      expect(FeatureRegistry.forRoute('/onboarding/name'), isNull);
      expect(FeatureRegistry.forRoute('/dev/theme'), isNull);
      expect(FeatureRegistry.forRoute('/nowhere'), isNull);
    });

    test('ids round-trip through storage by name', () {
      for (final id in FeatureId.values) {
        expect(FeatureId.tryParse(id.name), id);
      }
    });

    test('an unrecognised stored id is dropped rather than throwing', () {
      // What a downgrade, or a removed feature, would leave behind.
      expect(FeatureId.tryParse('astrology'), isNull);
      expect(FeatureId.tryParse(''), isNull);
    });
  });

  group('presentation', () {
    test('every choosable feature can describe itself in the drawer', () {
      for (final feature in FeatureRegistry.optional) {
        expect(feature.description, isNotEmpty);
        expect(feature.placeholderMessage, isNotEmpty);
      }
    });

    test('every feature has a distinct selected icon', () {
      for (final feature in FeatureRegistry.all) {
        expect(
          feature.selectedIcon,
          isNot(feature.icon),
          reason: '${feature.name} needs a second signal for selection',
        );
      }
    });
  });
}
