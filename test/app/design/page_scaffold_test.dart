import 'package:almanac/app/navigation/feature_screens.dart';
import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:almanac/features/environment/presentation/environment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared page composition, and the line between the app's two
/// visual worlds.
void main() {
  group('ENVIRONMENT IS OUTSIDE. DETAIL PAGES ARE THE BOOK.', () {
    test('every chapter of the book is on paper', () {
      // Centrally, in the composition root — so a feature cannot forget
      // to be paper, and a new one gets it by being added to the switch.
      for (final feature in FeatureRegistry.all) {
        if (feature.id == FeatureId.environment) continue;
        expect(
          screenForFeature(feature),
          isA<AlmanacPaperSurface>(),
          reason: feature.name,
        );
      }
    });

    test('and the Environment is not', () {
      // The living painting is handed through untouched.
      final outside = screenForFeature(
        FeatureRegistry.byId(FeatureId.environment),
      );
      expect(outside, isA<EnvironmentScreen>());
      expect(outside, isNot(isA<AlmanacPaperSurface>()));
    });
  });

  group('AlmanacPage', () {
    Widget page({VoidCallback? onBack, Widget? trailing}) => MaterialApp(
      theme: AppTheme.fromPalette(SeasonalPalettes.fallback),
      home: AlmanacPage(
        title: 'The Moon',
        eyebrow: 'Thursday 12 September',
        onBack: onBack,
        trailing: trailing,
        children: const [
          AlmanacSectionLabel(label: 'Key themes'),
          Text('Growing light, new beginnings.'),
        ],
      ),
    );

    testWidgets('is paper, whatever is happening outside', (tester) async {
      await tester.pumpWidget(page());

      expect(find.byType(AlmanacPaperSurface), findsOneWidget);
      expect(
        tester
            .widget<ColoredBox>(
              find
                  .descendant(
                    of: find.byType(AlmanacPaperSurface),
                    matching: find.byType(ColoredBox),
                  )
                  .first,
            )
            .color,
        AlmanacPaper.ground,
      );
    });

    testWidgets('the title is a header, and the eyebrow is above it', (
      tester,
    ) async {
      await tester.pumpWidget(page());

      expect(find.text('The Moon'), findsOneWidget);
      expect(find.text('Thursday 12 September'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Thursday 12 September')).dy,
        lessThan(tester.getTopLeft(find.text('The Moon')).dy),
      );
    });

    testWidgets('the way back is words, not a bare glyph', (tester) async {
      var went = 0;
      await tester.pumpWidget(page(onBack: () => went++));

      final back = find.widgetWithText(TextButton, 'Back');
      expect(back, findsOneWidget);
      // A way back nobody can hit is not a way back.
      expect(
        tester.getSize(back).height,
        greaterThanOrEqualTo(AppDimens.minTouchTarget),
      );

      await tester.tap(back);
      expect(went, 1);
    });

    testWidgets('and there is none when a page is a destination itself', (
      tester,
    ) async {
      await tester.pumpWidget(page());
      expect(find.widgetWithText(TextButton, 'Back'), findsNothing);
    });

    testWidgets('the trailing control keeps its place beside it', (
      tester,
    ) async {
      await tester.pumpWidget(
        page(onBack: () {}, trailing: const Icon(Icons.eco_outlined)),
      );

      expect(find.byIcon(Icons.eco_outlined), findsOneWidget);
      expect(
        tester.getCenter(find.byIcon(Icons.eco_outlined)).dx,
        greaterThan(
          tester.getCenter(find.widgetWithText(TextButton, 'Back')).dx,
        ),
      );
    });

    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('survives text at ${scale}x', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.view.physicalSize = const Size(390, 844) * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(page(onBack: () {}));
        await tester.pumpAndSettle();

        // Nothing clipped, nothing overflowed, and the content is still
        // there: the page grows rather than shrinking to fit.
        expect(tester.takeException(), isNull);
        expect(find.text('The Moon'), findsOneWidget);
        expect(find.text('Growing light, new beginnings.'), findsOneWidget);
        expect(
          tester.getSize(find.widgetWithText(TextButton, 'Back')).height,
          greaterThanOrEqualTo(AppDimens.minTouchTarget),
        );
      });
    }
  });

  group('AlmanacInset', () {
    testWidgets('is tinted into the page, with no shadow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.fromPalette(
            AlmanacPaper.reprint(SeasonalPalettes.fallback),
          ),
          home: const Scaffold(
            body: AlmanacInset(child: Text('A practice for today')),
          ),
        ),
      );

      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(AlmanacInset),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as ShapeDecoration;

      expect(decoration.color, AlmanacPaper.groundInset);
      expect(decoration.shadows, anyOf(isNull, isEmpty));
    });

    testWidgets('and a tappable one clears the touch target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.fromPalette(SeasonalPalettes.fallback),
          home: Scaffold(
            body: AlmanacInset(
              onTap: () {},
              padding: EdgeInsets.zero,
              child: const Text('Open'),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(AlmanacInset)).height,
        greaterThanOrEqualTo(AppDimens.minTouchTarget),
      );
    });
  });
}
