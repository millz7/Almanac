import 'package:almanac/app/app.dart';
import 'package:almanac/app/router.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/features/chakras/domain/chakras.dart';
import 'package:almanac/features/nature_log/presentation/nature_log_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_environment_services.dart';
import '../support/test_overrides.dart';

/// Responsive QA for the screens this step deepened: all seven chakra
/// pages, with their new ways to pause, and the Nature Log's own-words
/// form with its new Animal category. (The Cookbook's own recipes carry
/// their own matrix in `own_recipes_test.dart`.)
void main() {
  setUpAll(useTimeZoneDatabase);

  final page = find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .first;

  Future<ProviderContainer> open(
    WidgetTester tester, {
    required Size surface,
    required double textScale,
  }) async {
    tester.view.physicalSize = surface * 2;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final container = ProviderContainer(
      overrides: environmentOverrides(
        features: {FeatureId.chakras, FeatureId.natureLog},
      ),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> go(
    WidgetTester tester,
    ProviderContainer container,
    String route,
  ) async {
    container.read(routerProvider).go(route);
    await tester.pumpAndSettle();
  }

  Future<void> readToTheEnd(WidgetTester tester, String where) async {
    if (page.evaluate().isEmpty) return;
    for (var i = 0; i < 10; i++) {
      await tester.drag(page, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: where);
    }
  }

  /// Brings [target] on screen, whether it is already built or further
  /// down a lazily built list.
  Future<void> reveal(WidgetTester tester, Finder target) async {
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(target, 300, scrollable: page);
    }
    await tester.ensureVisible(target.first);
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, Finder target) async {
    await reveal(tester, target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  for (final size in [const Size(390, 844), const Size(834, 1194)]) {
    for (final scale in [1.0, 2.0]) {
      final name = '${size.width.toInt()}×${size.height.toInt()} at ${scale}x';

      testWidgets('$name: all seven chakra pages, ways to pause and all', (
        tester,
      ) async {
        final container = await open(tester, surface: size, textScale: scale);
        final chakras = FeatureRegistry.byId(FeatureId.chakras).route;

        for (final chakra in ChakraCatalogue.all) {
          await go(tester, container, chakras);
          // Back to the seven, wherever the last pass left us.
          final backToSeven = find.text('Back to the seven');
          if (backToSeven.evaluate().isNotEmpty) {
            await press(tester, backToSeven);
          }
          await press(tester, find.bySemanticsLabel(chakra.semanticLabel));

          await reveal(tester, find.text(chakra.ways.last));
          expect(find.text(ChakraCatalogue.waysHeading), findsOneWidget);
          for (final way in chakra.ways) {
            expect(find.text(way), findsOneWidget, reason: way);
          }
          expect(tester.takeException(), isNull, reason: chakra.name);
          await readToTheEnd(tester, chakra.name);
        }
      });

      testWidgets('$name: the Nature Log\'s own-words form', (tester) async {
        final container = await open(tester, surface: size, textScale: scale);
        await go(
          tester,
          container,
          FeatureRegistry.byId(FeatureId.natureLog).route,
        );
        await press(
          tester,
          find.widgetWithText(ElevatedButton, NatureLogText.recordSomething),
        );
        await press(
          tester,
          find.widgetWithText(ElevatedButton, NatureLogText.writeYourOwn),
        );
        expect(find.bySemanticsLabel('Animal'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await readToTheEnd(tester, 'Nature form');
        expect(find.textContaining('…'), findsNothing);
      });
    }
  }
}
