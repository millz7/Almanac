import 'package:almanac/app/app.dart';
import 'package:almanac/app/router.dart';
import 'package:almanac/core/context/almanac_context.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/moon_service.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/features/environment/presentation/maramataka_screen.dart';
import 'package:almanac/features/environment/presentation/maramataka_section.dart';
import 'package:almanac/features/environment/presentation/maramataka_text.dart';
import 'package:almanac/features/environment/presentation/moon_screen.dart';
import 'package:almanac/features/garden/presentation/garden_screen.dart';
import 'package:almanac/features/nature_log/presentation/nature_log_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

class _FixedMoonService implements MoonService {
  const _FixedMoonService(this.state);

  final MoonPhaseState state;

  @override
  MoonPhaseState phaseAt(DateTime instant) => state;
}

/// Just past full: 15.5 thirtieths of the month — Rākau-nui, night 16.
const _pastFull = MoonPhaseState(
  phase: MoonPhase.waningGibbous,
  elongationDegrees: 186,
  illuminatedFraction: 0.99,
);

void main() {
  setUpAll(useTimeZoneDatabase);

  final explore = find.widgetWithText(TextButton, MaramatakaText.explore);

  Future<ProviderContainer> openMoon(
    WidgetTester tester, {
    required bool include,
    double textScale = 1,
    Size surface = const Size(420, 3000),
    Set<FeatureId> features = const {},
  }) async {
    tester.view.physicalSize = surface * 2;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final container = ProviderContainer(
      overrides: [
        ...environmentOverrides(includeMaramataka: include, features: features),
        moonServiceProvider.overrideWithValue(
          const _FixedMoonService(_pastFull),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).push(kMoonRoute);
    await tester.pumpAndSettle();
    expect(find.byType(MoonScreen), findsOneWidget);
    return container;
  }

  Future<void> press(WidgetTester tester, Finder control) async {
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  group('off (the default)', () {
    testWidgets('the Moon page is unchanged: no section, no doorway', (
      tester,
    ) async {
      await openMoon(tester, include: false);
      expect(find.byType(MaramatakaSection), findsOneWidget);
      expect(find.textContaining('Maramataka'), findsNothing);
      expect(find.text(MaramatakaText.subheading), findsNothing);
      expect(explore, findsNothing);
      expect(find.text('Rākau-nui'), findsNothing);
    });

    testWidgets('the lunar-month page redirects to the Moon', (tester) async {
      final c = await openMoon(tester, include: false);
      c.read(routerProvider).go(kMaramatakaRoute);
      await tester.pumpAndSettle();
      expect(find.byType(MaramatakaScreen), findsNothing);
      expect(
        c.read(routerProvider).routerDelegate.currentConfiguration.uri.path,
        kMoonRoute,
      );
    });

    testWidgets('no Garden or Nature Log note either', (tester) async {
      final c = await openMoon(
        tester,
        include: true,
        features: {FeatureId.garden, FeatureId.natureLog},
      );
      for (final route in ['/garden', '/nature-log']) {
        c.read(routerProvider).go(route);
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate(
            (w) => w is GardenScreen || w is NatureLogScreen,
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Maramataka'), findsNothing);
        expect(find.textContaining('Rākau-nui'), findsNothing);
      }
    });
  });

  group('on', () {
    testWidgets('the section: heading, estimated night, relationship, about, '
        'associations, doorway and the disclaimer', (tester) async {
      await openMoon(tester, include: true);
      expect(find.text('Maramataka'), findsOneWidget);
      expect(find.text('Māori lunar calendar'), findsOneWidget);
      expect(find.text('Estimated Maramataka night'), findsOneWidget);
      expect(find.text('Rākau-nui'), findsOneWidget);
      expect(find.text('Night 16 of 30'), findsOneWidget);
      expect(find.text('Astronomical relationship'), findsOneWidget);
      expect(
        find.text('The astronomical Moon: Waning Gibbous, 99% illuminated.'),
        findsOneWidget,
      );
      expect(find.text('About this night'), findsOneWidget);
      expect(find.textContaining('The moon is filled out'), findsOneWidget);
      expect(find.text('Traditionally associated with'), findsOneWidget);
      expect(
        find.text(
          'Te Ara notes that kūmara were traditionally planted on this night.',
        ),
        findsOneWidget,
      );
      expect(explore, findsOneWidget);
      expect(find.text(Maramataka.variationNote), findsOneWidget);
      expect(find.textContaining('Ngāti Kahungunu'), findsOneWidget);
      // The astronomical phase keeps its own name alongside.
      expect(find.text('Waning Gibbous'), findsWidgets);
    });

    testWidgets('the lunar month: all thirty, tonight marked in words and '
        'as selected, 48dp rows', (tester) async {
      final handle = tester.ensureSemantics();
      await openMoon(tester, include: true);
      await press(tester, explore);
      expect(find.byType(MaramatakaScreen), findsOneWidget);
      expect(find.text(MaramatakaText.monthTitle), findsWidgets);
      expect(find.text(Maramataka.variationNote), findsWidgets);

      for (final night in Maramataka.nights) {
        final current = night.id == 'rakau-nui';
        final row = find.bySemanticsLabel(
          MaramatakaText.spokenNight(night, current: current),
        );
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        expect(row, findsOneWidget, reason: night.name);
        expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
        expect(
          tester.getSemantics(row),
          isSemantics(isSelected: current),
          reason: night.name,
        );
      }
      // Said in words, not only by colour or a mark.
      expect(find.text(MaramatakaText.estimatedTonight), findsOneWidget);
      expect(
        MaramatakaText.spokenNight(Maramataka.nights[15], current: true),
        contains('Estimated tonight'),
      );
      handle.dispose();
    });

    testWidgets('Back from the month returns to the Moon', (tester) async {
      await openMoon(tester, include: true);
      await press(tester, explore);
      await press(tester, find.widgetWithText(TextButton, MaramatakaText.back));
      expect(find.byType(MaramatakaScreen), findsNothing);
      expect(find.byType(MoonScreen), findsOneWidget);
    });

    testWidgets('switching it off while on the month page returns to the '
        'Moon, and the section goes', (tester) async {
      final c = await openMoon(tester, include: true);
      await press(tester, explore);
      await c.read(userSettingsProvider.notifier).setIncludeMaramataka(false);
      await tester.pumpAndSettle();
      expect(find.byType(MaramatakaScreen), findsNothing);
      expect(find.byType(MoonScreen), findsOneWidget);
      expect(find.textContaining('Maramataka'), findsNothing);
    });

    for (final size in [const Size(320, 700), const Size(800, 1280)]) {
      testWidgets('2x text at ${size.width.toInt()} wide: the section, the '
          'month and the disclaimer all read', (tester) async {
        await openMoon(tester, include: true, textScale: 2, surface: size);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text(Maramataka.variationNote));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await press(tester, explore);
        expect(tester.takeException(), isNull);
        final note = find.text(Maramataka.variationNote).first;
        await tester.ensureVisible(note);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final scrollable = find.byType(Scrollable).last;
        for (var i = 0; i < 40; i++) {
          await tester.drag(scrollable, const Offset(0, -600));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  });

  test('reads the one Moon: the section\'s night is the provider\'s', () {
    final c = ProviderContainer(
      overrides: [
        ...environmentOverrides(includeMaramataka: true),
        moonServiceProvider.overrideWithValue(
          const _FixedMoonService(_pastFull),
        ),
      ],
    );
    addTearDown(c.dispose);
    expect(c.read(currentMaramatakaProvider)!.id, 'rakau-nui');
  });
}
