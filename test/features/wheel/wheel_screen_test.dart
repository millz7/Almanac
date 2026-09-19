import 'dart:io';

import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:almanac/features/wheel/domain/festival.dart';
import 'package:almanac/features/wheel/presentation/widgets/wheel_diagram.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

void main() {
  setUpAll(useTimeZoneDatabase);

  Finder navTab(String name) => find.descendant(
    of: find.byType(AlmanacNavigationBar),
    matching: find.bySemanticsLabel(name),
  );

  Future<void> openWheel(
    WidgetTester tester, {
    DateTime? now,
    Hemisphere hemisphere = Hemisphere.northern,
    Size surface = const Size(430, 3600),
    double textScale = 1,
    Set<FeatureId> features = const {FeatureId.wheel},
  }) async {
    tester.view.physicalSize = surface * 2;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: environmentOverrides(
          now: now,
          hemisphere: hemisphere,
          features: features,
        ),
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();

    final strip = find.descendant(
      of: find.byType(AlmanacNavigationBar),
      matching: find.byType(Scrollable),
    );
    if (strip.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        navTab('Wheel of the Year'),
        80,
        scrollable: strip,
      );
    } else {
      await tester.ensureVisible(navTab('Wheel of the Year'));
    }
    await tester.pumpAndSettle();
    await tester.tap(navTab('Wheel of the Year'));
    await tester.pumpAndSettle();
  }

  group('the wheel page', () {
    testWidgets('is written on Almanac paper, not a Material dashboard', (
      tester,
    ) async {
      await openWheel(tester);
      expect(find.byType(AlmanacPaperSurface), findsWidgets);
      expect(find.byType(AppScaffold), findsOneWidget);
    });

    testWidgets('shows all eight festivals', (tester) async {
      await openWheel(tester);
      for (final festival in WheelOfYear.festivals) {
        expect(
          find.text(festival.name),
          findsWidgets,
          reason: '${festival.name} should be listed',
        );
      }
    });

    testWidgets('draws the current-position wheel diagram', (tester) async {
      await openWheel(tester);
      expect(find.byType(WheelDiagram), findsOneWidget);
    });

    testWidgets('states the next festival in real, readable text', (
      tester,
    ) async {
      await openWheel(tester, now: DateTime.utc(2026, 4, 27, 12));
      expect(find.textContaining('Beltane'), findsWidgets);
      expect(find.textContaining(RegExp(r'Next: |Today:')), findsOneWidget);
    });

    testWidgets('quietly states which hemisphere year it is following', (
      tester,
    ) async {
      await openWheel(tester, hemisphere: Hemisphere.southern);
      expect(find.textContaining('Southern Hemisphere'), findsOneWidget);
    });
  });

  group('hemisphere changes which festival is next, not just its label', () {
    testWidgets('27 April: Northern Hemisphere is approaching Beltane', (
      tester,
    ) async {
      await openWheel(
        tester,
        now: DateTime.utc(2026, 4, 27, 12),
        hemisphere: Hemisphere.northern,
      );
      expect(find.textContaining('Next: Beltane'), findsOneWidget);
    });

    testWidgets(
      '27 April: Southern Hemisphere is approaching Samhain instead',
      (tester) async {
        await openWheel(
          tester,
          now: DateTime.utc(2026, 4, 27, 12),
          hemisphere: Hemisphere.southern,
        );
        expect(find.textContaining('Next: Samhain'), findsOneWidget);
        // A Southern Hemisphere user must not see the Northern wheel with
        // its dates merely relabelled.
        expect(find.textContaining('Next: Beltane'), findsNothing);
      },
    );
  });

  group('opening a festival', () {
    testWidgets('uses the AlmanacPage book scaffold, with a way back', (
      tester,
    ) async {
      await openWheel(tester);

      await tester.ensureVisible(find.text('Yule').first);
      await tester.tap(find.text('Yule').first);
      await tester.pumpAndSettle();

      expect(find.byType(AlmanacPage), findsOneWidget);
      expect(find.text('Prepare'), findsOneWidget);
      expect(find.text('Celebrate'), findsOneWidget);
      expect(find.text('Food & drink'), findsOneWidget);
      expect(find.text('Reflect'), findsOneWidget);
      expect(find.text('In nature'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(AlmanacPage), findsNothing);
      expect(find.byType(WheelDiagram), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('every festival row clears the minimum touch target', (
      tester,
    ) async {
      await openWheel(tester);

      for (final festival in WheelOfYear.festivals) {
        final row = find.bySemanticsLabel(RegExp('^${festival.name}'));
        expect(row, findsOneWidget, reason: festival.name);
        final size = tester.getSize(row);
        expect(size.height, greaterThanOrEqualTo(48), reason: festival.name);
      }
    });

    testWidgets('at 1x, 1.5x and 2x text nothing overflows', (tester) async {
      for (final scale in [1.0, 1.5, 2.0]) {
        await openWheel(tester, textScale: scale);
        expect(tester.takeException(), isNull, reason: '${scale}x');
        expect(find.textContaining('…'), findsNothing, reason: '${scale}x');
      }
    });

    testWidgets('the wheel diagram is decorative; real text carries the '
        'summary', (tester) async {
      final handle = tester.ensureSemantics();
      await openWheel(tester, now: DateTime.utc(2026, 4, 27, 12));

      expect(
        find.bySemanticsLabel(RegExp('Wheel of the Year. Current season')),
        findsOneWidget,
      );

      handle.dispose();
    });
  });

  group('navigation labels', () {
    testWidgets('a roomy bar shows the full "Holidays" label, not the page '
        'title', (tester) async {
      await openWheel(tester, surface: const Size(1200, 900));
      expect(find.text('Holidays'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlmanacNavigationBar),
          matching: find.text('Wheel of the Year'),
        ),
        findsNothing,
      );
    });

    testWidgets('a crowded bar shortens it to "Hols"', (tester) async {
      await openWheel(
        tester,
        surface: const Size(320, 900),
        features: FeatureRegistry.optional.map((f) => f.id).toSet(),
      );
      expect(
        find.descendant(
          of: find.byType(AlmanacNavigationBar),
          matching: find.text('Hols'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the accessibility label always says the full name', (
      tester,
    ) async {
      await openWheel(tester, surface: const Size(320, 900));
      // find.bySemanticsLabel matched on this exact string to open the
      // page in the first place, so its being reachable here is already
      // proof — this just makes the intent explicit.
      expect(navTab('Wheel of the Year'), findsOneWidget);
    });
  });

  group('static, not animated', () {
    test('the wheel diagram uses no ticker or animation controller', () {
      final code = File(
        'lib/features/wheel/presentation/widgets/wheel_diagram.dart',
      ).readAsStringSync();
      for (final forbidden in [
        'AnimationController',
        'TickerProviderStateMixin',
        'vsync',
      ]) {
        expect(code.contains(forbidden), isFalse, reason: forbidden);
      }
    });
  });
}
