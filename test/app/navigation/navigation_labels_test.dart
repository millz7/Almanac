import 'package:almanac/app/navigation/navigation_labels.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bar's promise is that it never truncates a label. These tests
/// exercise the decision that keeps it: measure the real labels, then
/// pick full names, deliberate short names, or a scrolling strip — in
/// that order, and never anything narrower than a comfortable tap.
void main() {
  // A concrete style, so the measurements are of something real rather
  // than of an inherited default that could be null.
  const style = TextStyle(fontSize: 12, height: 1.33);

  NavigationLayout layoutFor(
    List<FeatureDefinition> destinations, {
    required double available,
    double textScale = 1,
  }) => resolveNavigationLayout(
    destinations: destinations,
    available: available,
    style: style,
    textScaler: TextScaler.linear(textScale),
  );

  List<FeatureDefinition> almanacOf(int optionalCount) => [
    FeatureRegistry.environment,
    ...FeatureRegistry.optional.take(optionalCount),
  ];

  /// The width one item needs for a given label set, using the same
  /// measurement the layout does. Expressed this way rather than as fixed
  /// numbers because the test font is not the shipping font: what matters
  /// is the *rule*, not a pixel count that only holds for one typeface.
  double neededPerItem(
    List<FeatureDefinition> destinations, {
    required bool short,
    double textScale = 1,
  }) {
    var widest = 0.0;
    for (final feature in destinations) {
      final painter = TextPainter(
        text: TextSpan(
          text: short ? feature.shortName : feature.name,
          style: style,
        ),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.linear(textScale),
        maxLines: 1,
      )..layout();
      widest = widest > painter.width ? widest : painter.width;
    }
    final needed = widest + kNavigationLabelPadding * 2;
    return needed > 48 ? needed : 48;
  }

  group('choosing a label set', () {
    test('full names are used the moment they fit', () {
      final destinations = almanacOf(2);
      final needed =
          neededPerItem(destinations, short: false) * destinations.length;

      final roomy = layoutFor(destinations, available: needed + 1);
      expect(roomy.useShortLabels, isFalse);
      expect(roomy.scrollable, isFalse);
      expect(roomy.labelFor(FeatureRegistry.environment), 'Environment');
    });

    test('one pixel too tight for full names falls back to short ones', () {
      final destinations = almanacOf(2);
      final needed =
          neededPerItem(destinations, short: false) * destinations.length;

      final tight = layoutFor(destinations, available: needed - 1);
      expect(tight.useShortLabels, isTrue);
      expect(tight.scrollable, isFalse);
      expect(tight.labelFor(FeatureRegistry.environment), 'Env');
    });

    test('a full Almanac uses the agreed short names', () {
      final destinations = almanacOf(7);
      final layout = layoutFor(
        destinations,
        available: neededPerItem(destinations, short: true) * 8,
      );

      expect(layout.useShortLabels, isTrue);
      expect(layout.scrollable, isFalse);
      expect(FeatureRegistry.all.map(layout.labelFor).toList(), [
        'Env',
        'Med',
        'Yoga',
        'Chak',
        'Cycle',
        'Cook',
        'Garden',
        'Nature',
      ]);
    });

    test('too tight for even the short names scrolls, hiding nothing', () {
      final destinations = almanacOf(7);
      final layout = layoutFor(
        destinations,
        available: neededPerItem(destinations, short: true) * 8 - 1,
      );

      expect(layout.scrollable, isTrue);
      expect(layout.useShortLabels, isTrue);
      // Still a full-size item for every destination.
      expect(
        layout.itemWidth,
        greaterThanOrEqualTo(neededPerItem(destinations, short: true)),
      );
    });

    test('large text pushes a bar from full names to short ones', () {
      final destinations = almanacOf(3);
      // Wide enough for the full names at normal size, and not at double.
      final available =
          neededPerItem(destinations, short: false) * destinations.length + 1;

      expect(
        layoutFor(destinations, available: available).useShortLabels,
        isFalse,
      );
      expect(
        layoutFor(
          destinations,
          available: available,
          textScale: 2,
        ).useShortLabels,
        isTrue,
      );
    });
  });

  group('touch targets never shrink', () {
    test('every layout keeps items at least 48 wide', () {
      for (final count in [0, 1, 3, 5, 7]) {
        for (final width in [200.0, 320.0, 400.0, 600.0]) {
          for (final scale in [1.0, 1.5, 2.0]) {
            final layout = layoutFor(
              almanacOf(count),
              available: width,
              textScale: scale,
            );
            expect(
              layout.itemWidth,
              greaterThanOrEqualTo(48),
              reason:
                  '$count features at ${width}px, ${scale}x text gave '
                  '${layout.itemWidth}px items',
            );
          }
        }
      }
    });

    test('the bar grows taller for larger text instead of clipping', () {
      final normal = layoutFor(almanacOf(3), available: 400);
      final large = layoutFor(almanacOf(3), available: 400, textScale: 2);

      expect(large.height, greaterThan(normal.height));
      expect(normal.height, greaterThanOrEqualTo(48));
    });
  });

  group('the labels themselves fit', () {
    /// The whole point: the chosen label, at the chosen scale, is
    /// narrower than the item it will be drawn in.
    double widthOf(String label, double scale) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.linear(scale),
        maxLines: 1,
      )..layout();
      return painter.width;
    }

    test('no label ever needs more room than its item has', () {
      for (final count in [1, 3, 5, 7]) {
        for (final width in [200.0, 320.0, 360.0, 400.0, 720.0]) {
          for (final scale in [1.0, 1.3, 2.0]) {
            final destinations = almanacOf(count);
            final layout = layoutFor(
              destinations,
              available: width,
              textScale: scale,
            );

            for (final feature in destinations) {
              expect(
                widthOf(layout.labelFor(feature), scale),
                lessThanOrEqualTo(layout.itemWidth),
                reason:
                    '"${layout.labelFor(feature)}" would be cut off at '
                    '$count features, ${width}px, ${scale}x',
              );
            }
          }
        }
      }
    });
  });

  group('a single destination', () {
    test('an Almanac with nothing added still lays out', () {
      final layout = layoutFor(almanacOf(0), available: 400);

      expect(layout.useShortLabels, isFalse);
      expect(layout.scrollable, isFalse);
      expect(layout.itemWidth, 400);
    });
  });
}
