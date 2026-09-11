import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// How the bottom bar *looks*. What it does — full labels, then the
/// short words, then scrolling, never an ellipsis — is tested in
/// `personalised_navigation_test.dart` and is unchanged.
void main() {
  final destinations = FeatureRegistry.all.take(4).toList();

  Widget bar({required int selected}) => MaterialApp(
    theme: AppTheme.fromPalette(SeasonalPalettes.fallback),
    home: Scaffold(
      bottomNavigationBar: AlmanacNavigationBar(
        destinations: destinations,
        selectedIndex: selected,
        onDestinationSelected: (_) {},
      ),
    ),
  );

  group('the selected destination never rests on colour alone', () {
    testWidgets('it is marked, filled and inked — three signals', (
      tester,
    ) async {
      await tester.pumpWidget(bar(selected: 0));

      final palette = SeasonalPalettes.fallback;

      // 1. The bookmark rule above it, which only the selected item has.
      final marks = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(AlmanacNavigationBar),
              matching: find.byType(ColoredBox),
            ),
          )
          .where((box) => box.color == palette.primary);
      expect(marks, hasLength(1));

      // 2. The filled icon, where the others are outlined.
      expect(find.byIcon(destinations.first.selectedIcon), findsOneWidget);
      for (final other in destinations.skip(1)) {
        expect(find.byIcon(other.icon), findsOneWidget, reason: other.name);
        expect(find.byIcon(other.selectedIcon), findsNothing);
      }
    });

    testWidgets('and the mark moves with the selection', (tester) async {
      await tester.pumpWidget(bar(selected: 2));

      expect(find.byIcon(destinations[2].selectedIcon), findsOneWidget);
      expect(find.byIcon(destinations[0].selectedIcon), findsNothing);
    });

    testWidgets('there is no filled Material pill behind it', (tester) async {
      // On an illustrated bar a filled capsule reads as a control panel
      // dropped over the page. The indicator is a rule instead.
      await tester.pumpWidget(bar(selected: 0));

      final stadiums = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(AlmanacNavigationBar),
              matching: find.byType(Container),
            ),
          )
          .where(
            (container) =>
                container.decoration is ShapeDecoration &&
                (container.decoration! as ShapeDecoration).shape
                    is StadiumBorder,
          );
      expect(stadiums, isEmpty);
    });
  });

  group('the bar belongs to the page', () {
    testWidgets('a hairline above it, and no shadow', (tester) async {
      await tester.pumpWidget(bar(selected: 0));

      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(AlmanacNavigationBar),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;

      expect(decoration.border, isNotNull);
      expect(decoration.boxShadow, anyOf(isNull, isEmpty));
      expect(decoration.border!.top.width, lessThanOrEqualTo(1));
    });

    testWidgets('and every destination is comfortable to hit', (tester) async {
      await tester.pumpWidget(bar(selected: 0));

      for (final feature in destinations) {
        expect(
          tester.getSize(find.bySemanticsLabel(feature.name)).height,
          greaterThanOrEqualTo(AppDimens.minTouchTarget),
          reason: feature.name,
        );
      }
    });
  });
}
