import 'package:almanac/app/almanac_button.dart';
import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/app/navigation/widgets/almanac_doorway.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/moon_service.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:almanac/features/cycle/application/cycle_providers.dart';
import 'package:almanac/features/cycle/domain/cycle_syncing.dart';
import 'package:almanac/features/cycle/presentation/cycle_text.dart';
import 'package:almanac/features/cycle/presentation/widgets/bleeding_marker.dart';
import 'package:almanac/features/cycle/presentation/widgets/cycle_moon_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// A moon pinned to one phase, so a test about the screen is not also a
/// test of the date it happens to be.
class _FixedMoonService implements MoonService {
  const _FixedMoonService(this.state);

  final MoonPhaseState state;

  @override
  MoonPhaseState phaseAt(DateTime instant) => state;
}

const _waxingCrescent = MoonPhaseState(
  phase: MoonPhase.waxingCrescent,
  elongationDegrees: 60,
  illuminatedFraction: 0.34,
);

/// 20 September 2026, midday in London.
final testNow = DateTime.utc(2026, 9, 20, 12);
const testToday = CalendarDate(2026, 9, 20);
const sep4 = CalendarDate(2026, 9, 4);

CycleData withDay1(CalendarDate date, {CyclePhase? manualPhase}) => CycleData(
  records: [
    CycleDayRecord(
      date: date,
      level: BleedingLevel.bleeding,
      isPeriodStart: true,
    ),
  ],
  manualPhase: manualPhase,
);

void main() {
  setUpAll(useTimeZoneDatabase);

  Finder navTab(String name) => find.descendant(
    of: find.byType(AlmanacNavigationBar),
    matching: find.bySemanticsLabel(name),
  );

  Finder route(String title) => find.bySemanticsLabel(RegExp('^$title\\.'));
  Finder back() => find.widgetWithText(TextButton, CycleText.back);

  Future<ProviderContainer> openCycle(
    WidgetTester tester, {
    CycleData? data,
    CycleStore? store,
    DateTime? now,
    MoonPhaseState moon = _waxingCrescent,
    Set<FeatureId> features = const {FeatureId.cycle},
    double textScale = 1,
    bool reducedMotion = false,
    Size surface = const Size(430, 3600),
  }) async {
    tester.view.physicalSize = surface * 2;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    if (reducedMotion) {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
    }

    final container = ProviderContainer(
      overrides: [
        ...environmentOverrides(
          now: now ?? testNow,
          features: features,
          cycleStore: store ?? InMemoryCycleStore(data ?? CycleData.empty),
        ),
        moonServiceProvider.overrideWithValue(_FixedMoonService(moon)),
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

    await tester.tap(navTab(CycleText.title));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> press(WidgetTester tester, Finder control) async {
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  /// A level choice in the day editor. Keyed rather than found by its
  /// label, because "Bleeding" is also the heading above the choices.
  Finder levelChoice(BleedingLevel? level) =>
      find.byKey(ValueKey('level-${level?.name ?? 'none'}'));

  /// Opens a date's editor, chooses a level, and saves.
  Future<void> recordDay(
    WidgetTester tester,
    int day, {
    required BleedingLevel? level,
    bool? firstDay,
  }) async {
    await press(tester, find.bySemanticsLabel(RegExp('^$day September')));
    await press(tester, levelChoice(level));
    if (firstDay != null) {
      final toggle = find.byType(Switch);
      if (tester.widget<Switch>(toggle).value != firstDay) {
        await press(tester, toggle);
      }
    }
    await press(tester, find.widgetWithText(ElevatedButton, CycleText.save));
  }

  group('Cycle home is simple', () {
    testWidgets('a wheel, two ways deeper, and little else', (tester) async {
      await openCycle(tester, data: withDay1(sep4));

      expect(find.byType(CycleMoonWheel), findsOneWidget);
      expect(route(CycleText.calendar), findsOneWidget);
      expect(route(CycleText.syncing), findsOneWidget);
      expect(find.text('September · Summer'), findsOneWidget);
    });

    testWidgets('the cycle day and phase are in the middle', (tester) async {
      await openCycle(tester, data: withDay1(sep4));

      expect(find.text(CycleText.dayLine(17)), findsOneWidget);
      expect(find.text(CyclePhase.luteal.label), findsWidgets);
    });

    testWidgets('with the current moon as a quieter line', (tester) async {
      await openCycle(tester, data: withDay1(sep4));

      expect(find.text(MoonPhase.waxingCrescent.label), findsOneWidget);
    });

    testWidgets('and the moon cycle type when it can be derived', (
      tester,
    ) async {
      await openCycle(tester, data: withDay1(sep4));

      // A waxing crescent day 1 is a Pink Moon cycle.
      expect(find.text(MoonCycleType.pink.label), findsOneWidget);
      expect(
        find.text(CycleText.moonCycleLine(MoonCycleType.pink)),
        findsOneWidget,
      );
    });

    testWidgets('but not when there is no day 1 to derive it from', (
      tester,
    ) async {
      await openCycle(tester);

      for (final type in MoonCycleType.values) {
        expect(find.text(type.label), findsNothing, reason: type.name);
      }
    });

    testWidgets('the next-period estimate appears only when possible', (
      tester,
    ) async {
      await openCycle(tester, data: withDay1(sep4));
      expect(
        find.text(CycleText.nextPeriodAround(sep4.addDays(28))),
        findsOneWidget,
      );
      expect(find.textContaining(CycleText.estimated), findsWidgets);

      await openCycle(tester);
      expect(find.textContaining('Next period'), findsNothing);
    });

    testWidgets('no food, movement, recipe or meditation copy is here', (
      tester,
    ) async {
      await openCycle(tester, data: withDay1(sep4));

      for (final heading in [
        CycleText.foodHeading,
        CycleText.movementHeading,
        CycleText.mindHeading,
        CycleText.durationHeading,
        CycleText.aboutHeading,
      ]) {
        expect(find.text(heading), findsNothing, reason: heading);
      }
      expect(find.text(CycleText.seeRecipes), findsNothing);
      expect(find.text(CycleText.tryYoga), findsNothing);
      // And no statistics dashboard.
      expect(find.textContaining('Recent cycles'), findsNothing);
    });

    testWidgets('it is useful before anything is recorded', (tester) async {
      await openCycle(tester);

      expect(find.byType(CycleMoonWheel), findsOneWidget);
      expect(find.text(CycleText.noCycleYet), findsOneWidget);
      expect(find.text(MoonPhase.waxingCrescent.label), findsOneWidget);
      expect(route(CycleText.calendar), findsOneWidget);
      expect(route(CycleText.syncing), findsOneWidget);
    });
  });

  group('Cycle is an inner page of the Almanac', () {
    testWidgets('it is written on paper', (tester) async {
      await openCycle(tester, data: withDay1(sep4));

      expect(find.byType(AlmanacPaperSurface), findsOneWidget);
    });

    Future<Color> groundAt(WidgetTester tester, DateTime instant) async {
      await openCycle(tester, now: instant, data: withDay1(sep4));
      return tester
          .widget<ColoredBox>(
            find
                .descendant(
                  of: find.byType(AlmanacPaperSurface),
                  matching: find.byType(ColoredBox),
                )
                .first,
          )
          .color;
    }

    testWidgets('the same paper by day and after dark', (tester) async {
      final night = await groundAt(tester, DateTime.utc(2026, 9, 20, 1));
      final day = await groundAt(tester, DateTime.utc(2026, 9, 20, 12));

      expect(night, AlmanacPaper.ground);
      expect(day, AlmanacPaper.ground);
      expect(night, day);
    });

    testWidgets('and the same paper in every season', (tester) async {
      for (final instant in [
        DateTime.utc(2026, 1, 15, 12),
        DateTime.utc(2026, 4, 15, 12),
        DateTime.utc(2026, 7, 15, 12),
        DateTime.utc(2026, 10, 15, 12),
      ]) {
        expect(
          await groundAt(tester, instant),
          AlmanacPaper.ground,
          reason: '$instant',
        );
      }
    });

    testWidgets('the Almanac is reachable and the tabs are unchanged', (
      tester,
    ) async {
      await openCycle(tester, features: {FeatureId.cycle, FeatureId.cookbook});

      expect(find.byType(AlmanacButton), findsOneWidget);
      expect(navTab('Environment'), findsOneWidget);
      expect(navTab(CycleText.title), findsOneWidget);
    });
  });

  group('the Calendar records bleeding', () {
    testWidgets('a month can be walked backwards and forwards', (tester) async {
      await openCycle(tester);
      await press(tester, route(CycleText.calendar));
      expect(find.text('September 2026'), findsWidgets);

      await press(tester, find.byTooltip(CycleText.previousMonth));
      expect(find.text('August 2026'), findsWidgets);

      await press(tester, find.byTooltip(CycleText.nextMonth));
      await press(tester, find.byTooltip(CycleText.nextMonth));
      expect(find.text('October 2026'), findsWidgets);
    });

    testWidgets('each of the three levels can be recorded', (tester) async {
      final container = await openCycle(tester);
      await press(tester, route(CycleText.calendar));

      await recordDay(tester, 2, level: BleedingLevel.spotting);
      await recordDay(tester, 4, level: BleedingLevel.bleeding);
      await recordDay(tester, 5, level: BleedingLevel.heavy);

      final data = container.read(cycleDataProvider).value!;
      expect(
        data.levelOn(const CalendarDate(2026, 9, 2)),
        BleedingLevel.spotting,
      );
      expect(data.levelOn(sep4), BleedingLevel.bleeding);
      expect(data.levelOn(const CalendarDate(2026, 9, 5)), BleedingLevel.heavy);
    });

    testWidgets('and a day can be set back to nothing', (tester) async {
      final container = await openCycle(tester);
      await press(tester, route(CycleText.calendar));
      await recordDay(tester, 4, level: BleedingLevel.bleeding);

      await recordDay(tester, 4, level: null);

      expect(container.read(cycleDataProvider).value!.recordOn(sep4), isNull);
    });

    testWidgets('or removed outright', (tester) async {
      final container = await openCycle(tester);
      await press(tester, route(CycleText.calendar));
      await recordDay(tester, 4, level: BleedingLevel.bleeding);

      await press(tester, find.bySemanticsLabel(RegExp('^4 September')));
      await press(tester, find.widgetWithText(TextButton, CycleText.remove));

      expect(container.read(cycleDataProvider).value!.recordOn(sep4), isNull);
    });

    testWidgets('the Day 1 control is offered for bleeding and heavy', (
      tester,
    ) async {
      await openCycle(tester);
      await press(tester, route(CycleText.calendar));

      await press(tester, find.bySemanticsLabel(RegExp('^4 September')));
      await press(tester, levelChoice(BleedingLevel.bleeding));
      expect(find.text(CycleText.firstDayOfPeriod), findsOneWidget);

      await press(tester, levelChoice(BleedingLevel.heavy));
      expect(find.text(CycleText.firstDayOfPeriod), findsOneWidget);
    });

    testWidgets('and never for spotting', (tester) async {
      await openCycle(tester);
      await press(tester, route(CycleText.calendar));

      await press(tester, find.bySemanticsLabel(RegExp('^4 September')));
      await press(tester, levelChoice(BleedingLevel.bleeding));
      expect(find.text(CycleText.firstDayOfPeriod), findsOneWidget);

      // Choosing spotting takes the control away with it.
      await press(tester, levelChoice(BleedingLevel.spotting));
      expect(find.text(CycleText.firstDayOfPeriod), findsNothing);
    });

    testWidgets('saving returns to the Calendar, not to home', (tester) async {
      await openCycle(tester);
      await press(tester, route(CycleText.calendar));

      await recordDay(tester, 4, level: BleedingLevel.bleeding);

      // Still on the Calendar, ready for the next day.
      expect(find.text('September 2026'), findsWidgets);
      expect(find.byType(BleedingLegend), findsOneWidget);
      expect(route(CycleText.calendar), findsNothing);
    });

    testWidgets('so several days in a row are easy to enter', (tester) async {
      final container = await openCycle(tester);
      await press(tester, route(CycleText.calendar));

      await recordDay(tester, 4, level: BleedingLevel.bleeding, firstDay: true);
      await recordDay(tester, 5, level: BleedingLevel.heavy);
      await recordDay(tester, 6, level: BleedingLevel.heavy);
      await recordDay(tester, 7, level: BleedingLevel.bleeding);
      await recordDay(tester, 8, level: BleedingLevel.spotting);

      final data = container.read(cycleDataProvider).value!;
      expect(data.records, hasLength(5));
      expect(data.periodStarts, [sep4]);
      expect(
        data.levelOn(const CalendarDate(2026, 9, 8)),
        BleedingLevel.spotting,
      );
    });

    testWidgets('a future date cannot be opened', (tester) async {
      await openCycle(tester);
      await press(tester, route(CycleText.calendar));

      // The 25th has not happened; the 20th has.
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(RegExp('^25 September')))
            .flagsCollection
            .isButton,
        isFalse,
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(RegExp('^20 September')))
            .flagsCollection
            .isButton,
        isTrue,
      );
    });

    testWidgets('the legend uses the same marks as the calendar', (
      tester,
    ) async {
      await openCycle(tester, data: withDay1(sep4));
      await press(tester, route(CycleText.calendar));

      expect(find.byType(BleedingLegend), findsOneWidget);
      for (final level in BleedingLevel.values) {
        expect(
          find.bySemanticsLabel(level.label),
          findsWidgets,
          reason: level.name,
        );
      }
      // One marker widget per level in the legend, plus the recorded
      // day on the grid — all of them built from the same specs.
      expect(find.byType(BleedingMarker), findsWidgets);
    });
  });

  group('Cycle Syncing', () {
    testWidgets('every phase has all six passages', (tester) async {
      for (final phase in CyclePhase.values) {
        await openCycle(tester, data: withDay1(sep4, manualPhase: phase));
        await press(tester, route(CycleText.syncing));

        final guide = PhaseGuides.forPhase(phase);
        expect(
          find.text('${phase.label} phase'),
          findsWidgets,
          reason: phase.name,
        );
        expect(find.text(CycleText.focusHeading), findsOneWidget);
        expect(find.text(guide.focus), findsOneWidget, reason: phase.name);
        expect(find.text(CycleText.aboutHeading), findsOneWidget);
        expect(find.text(guide.about), findsOneWidget, reason: phase.name);
        expect(find.text(CycleText.foodHeading), findsOneWidget);
        expect(find.text(guide.food.first), findsOneWidget, reason: phase.name);
        expect(find.text(CycleText.movementHeading), findsOneWidget);
        expect(
          find.text(guide.movement.first),
          findsOneWidget,
          reason: phase.name,
        );
        expect(find.text(CycleText.mindHeading), findsOneWidget);
        expect(find.text(guide.reflection), findsOneWidget, reason: phase.name);
        expect(find.text(CycleText.durationHeading), findsOneWidget);
        expect(find.text(guide.duration), findsOneWidget, reason: phase.name);
      }
    });

    testWidgets('it shows the calculated phase by default', (tester) async {
      await openCycle(tester, data: withDay1(sep4));
      await press(tester, route(CycleText.syncing));

      // Day 17 of a 28-day estimate is luteal.
      expect(find.text('Luteal phase'), findsWidgets);
      expect(find.text(CycleText.dayLineEstimated(17)), findsOneWidget);
    });

    testWidgets('and the phase can be adjusted', (tester) async {
      final container = await openCycle(tester, data: withDay1(sep4));
      await press(tester, route(CycleText.syncing));

      await press(tester, find.bySemanticsLabel(CyclePhase.menstrual.label));

      expect(find.text('Menstrual phase'), findsWidgets);
      expect(find.text(CycleText.phaseIsYours), findsOneWidget);
      expect(container.read(displayedCyclePhaseProvider), CyclePhase.menstrual);
    });

    testWidgets('without rewriting anything factual', (tester) async {
      final container = await openCycle(tester, data: withDay1(sep4));
      await press(tester, route(CycleText.syncing));

      await press(tester, find.bySemanticsLabel(CyclePhase.ovulatory.label));

      final moment = container.read(cycleMomentProvider);
      expect(moment.recordedStart, sep4);
      expect(moment.currentDay, 17);
      expect(moment.phase, CyclePhase.luteal);
      expect(
        container.read(cycleDataProvider).value!.levelOn(sep4),
        BleedingLevel.bleeding,
      );
    });

    testWidgets('and can be handed back to the estimate', (tester) async {
      final container = await openCycle(
        tester,
        data: withDay1(sep4, manualPhase: CyclePhase.menstrual),
      );
      await press(tester, route(CycleText.syncing));
      expect(find.text(CycleText.phaseIsYours), findsOneWidget);

      await press(tester, find.bySemanticsLabel(CycleText.automaticEstimate));

      expect(find.text('Luteal phase'), findsWidgets);
      expect(find.text(CycleText.phaseIsYours), findsNothing);
      expect(container.read(cycleMomentProvider).phaseIsManual, isFalse);
    });

    testWidgets('it is still useful with no cycle recorded', (tester) async {
      final container = await openCycle(tester);
      await press(tester, route(CycleText.syncing));

      // Four phases offered to read about, and none of them pretended
      // to be the user's.
      expect(find.text(CycleText.chooseAPhase), findsOneWidget);
      for (final phase in CyclePhase.values) {
        expect(
          find.bySemanticsLabel(phase.label),
          findsOneWidget,
          reason: phase.name,
        );
      }

      await press(tester, find.bySemanticsLabel(CyclePhase.follicular.label));

      expect(find.text('Follicular phase'), findsWidgets);
      expect(
        find.text(PhaseGuides.forPhase(CyclePhase.follicular).focus),
        findsOneWidget,
      );
      expect(container.read(cycleDataProvider).value!.isEmpty, isTrue);
    });
  });

  group('the optional doorways', () {
    testWidgets('all three are there when the features are', (tester) async {
      await openCycle(
        tester,
        data: withDay1(sep4),
        features: {
          FeatureId.cycle,
          FeatureId.cookbook,
          FeatureId.yoga,
          FeatureId.meditation,
        },
      );
      await press(tester, route(CycleText.syncing));

      expect(find.bySemanticsLabel(CycleText.seeRecipes), findsOneWidget);
      expect(find.bySemanticsLabel(CycleText.tryYoga), findsOneWidget);
      expect(find.bySemanticsLabel(CycleText.tryMeditation), findsOneWidget);
    });

    testWidgets('with Cookbook off the food guidance stays', (tester) async {
      await openCycle(
        tester,
        data: withDay1(sep4),
        features: {FeatureId.cycle, FeatureId.yoga, FeatureId.meditation},
      );
      await press(tester, route(CycleText.syncing));

      final guide = PhaseGuides.forPhase(CyclePhase.luteal);
      expect(find.text(CycleText.foodHeading), findsOneWidget);
      for (final line in guide.food) {
        expect(find.text(line), findsOneWidget, reason: line);
      }
      // Only the door goes.
      expect(find.bySemanticsLabel(CycleText.seeRecipes), findsNothing);
      expect(find.bySemanticsLabel(CycleText.tryYoga), findsOneWidget);
    });

    testWidgets('with Yoga off the movement guidance stays', (tester) async {
      await openCycle(
        tester,
        data: withDay1(sep4),
        features: {FeatureId.cycle, FeatureId.cookbook, FeatureId.meditation},
      );
      await press(tester, route(CycleText.syncing));

      final guide = PhaseGuides.forPhase(CyclePhase.luteal);
      expect(find.text(CycleText.movementHeading), findsOneWidget);
      for (final line in guide.movement) {
        expect(find.text(line), findsOneWidget, reason: line);
      }
      expect(find.bySemanticsLabel(CycleText.tryYoga), findsNothing);
      expect(find.bySemanticsLabel(CycleText.seeRecipes), findsOneWidget);
    });

    testWidgets('with Meditation off the reflective line stays', (
      tester,
    ) async {
      await openCycle(
        tester,
        data: withDay1(sep4),
        features: {FeatureId.cycle, FeatureId.cookbook, FeatureId.yoga},
      );
      await press(tester, route(CycleText.syncing));

      expect(find.text(CycleText.mindHeading), findsOneWidget);
      expect(
        find.text(PhaseGuides.forPhase(CyclePhase.luteal).reflection),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(CycleText.tryMeditation), findsNothing);
    });

    testWidgets('with all three off, every word of guidance remains', (
      tester,
    ) async {
      await openCycle(
        tester,
        data: withDay1(sep4),
        features: {FeatureId.cycle},
      );
      await press(tester, route(CycleText.syncing));

      final guide = PhaseGuides.forPhase(CyclePhase.luteal);
      for (final line in [
        ...guide.food,
        ...guide.movement,
        guide.reflection,
        guide.about,
        guide.duration,
        guide.focus,
      ]) {
        expect(find.text(line), findsOneWidget, reason: line);
      }
      expect(find.byType(AlmanacDoorway), findsWidgets);
      expect(find.bySemanticsLabel(CycleText.seeRecipes), findsNothing);
      expect(find.bySemanticsLabel(CycleText.tryYoga), findsNothing);
      expect(find.bySemanticsLabel(CycleText.tryMeditation), findsNothing);
    });

    testWidgets('and a doorway appears the moment its feature does', (
      tester,
    ) async {
      final container = await openCycle(
        tester,
        data: withDay1(sep4),
        features: {FeatureId.cycle},
      );
      await press(tester, route(CycleText.syncing));
      expect(find.bySemanticsLabel(CycleText.seeRecipes), findsNothing);

      await container
          .read(userSettingsProvider.notifier)
          .setFeatureChosen(FeatureId.cookbook, true);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(CycleText.seeRecipes), findsOneWidget);
      // And the guidance never moved.
      expect(find.text(CycleText.foodHeading), findsOneWidget);

      await container
          .read(userSettingsProvider.notifier)
          .setFeatureChosen(FeatureId.cookbook, false);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(CycleText.seeRecipes), findsNothing);
      expect(find.text(CycleText.foodHeading), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('the wheel is one summary, not thirty moons', (tester) async {
      await openCycle(tester, data: withDay1(sep4));

      expect(
        find.bySemanticsLabel(RegExp('^September lunar calendar')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('Cycle day 17')), findsWidgets);
    });

    testWidgets('and it names the days that carry a record', (tester) async {
      await openCycle(
        tester,
        data: CycleData(
          records: [
            CycleDayRecord(
              date: const CalendarDate(2026, 9, 2),
              level: BleedingLevel.spotting,
            ),
            CycleDayRecord(
              date: sep4,
              level: BleedingLevel.bleeding,
              isPeriodStart: true,
            ),
            CycleDayRecord(
              date: const CalendarDate(2026, 9, 5),
              level: BleedingLevel.heavy,
            ),
          ],
        ),
      );

      expect(
        find.bySemanticsLabel(RegExp('Spotting recorded on 2')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Heavy bleeding recorded on 5')),
        findsOneWidget,
      );
    });

    testWidgets('a calendar day says its record in words', (tester) async {
      await openCycle(
        tester,
        data: CycleData(
          records: [
            CycleDayRecord(
              date: sep4,
              level: BleedingLevel.heavy,
              isPeriodStart: true,
            ),
            CycleDayRecord(
              date: const CalendarDate(2026, 9, 18),
              level: BleedingLevel.spotting,
            ),
          ],
        ),
      );
      await press(tester, route(CycleText.calendar));

      expect(
        find.bySemanticsLabel(
          '4 September. Heavy bleeding. First day of '
          'period.',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('18 September. Spotting.'), findsOneWidget);
    });

    testWidgets('the drawn marks and the wheel say nothing themselves', (
      tester,
    ) async {
      await openCycle(tester, data: withDay1(sep4));

      expect(
        find.descendant(
          of: find.byType(CycleMoonWheel),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });

    testWidgets('every control is a comfortable target', (tester) async {
      await openCycle(tester, data: withDay1(sep4));

      for (final title in [CycleText.calendar, CycleText.syncing]) {
        expect(
          tester.getSize(route(title)).height,
          greaterThanOrEqualTo(48),
          reason: title,
        );
      }

      await press(tester, route(CycleText.syncing));
      expect(
        tester
            .getSize(find.bySemanticsLabel(CyclePhase.menstrual.label))
            .height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.getSize(back()).height, greaterThanOrEqualTo(48));
    });

    testWidgets('doubling the text size breaks nothing', (tester) async {
      await openCycle(
        tester,
        data: withDay1(sep4),
        textScale: 2,
        surface: const Size(430, 6000),
      );

      expect(find.text(CycleText.dayLine(17)), findsOneWidget);
      expect(find.text(CycleText.calendar), findsOneWidget);
      expect(find.text(CycleText.syncing), findsOneWidget);
      expect(find.textContaining('…'), findsNothing);

      await press(tester, route(CycleText.syncing));
      final guide = PhaseGuides.forPhase(CyclePhase.luteal);
      expect(find.text(guide.focus), findsOneWidget);
      expect(find.text(guide.food.first), findsOneWidget);
      expect(find.bySemanticsLabel(CyclePhase.menstrual.label), findsOneWidget);
    });
  });

  group('motion', () {
    testWidgets('nothing is ticking once the page has settled', (tester) async {
      await openCycle(tester, data: withDay1(sep4));

      expect(tester.binding.transientCallbackCount, 0);

      await press(tester, route(CycleText.calendar));
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('and reduced motion changes nothing about it', (tester) async {
      await openCycle(tester, data: withDay1(sep4), reducedMotion: true);

      expect(find.byType(CycleMoonWheel), findsOneWidget);
      expect(find.text(CycleText.dayLine(17)), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);

      await press(tester, route(CycleText.syncing));
      expect(find.text(CycleText.focusHeading), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
    });
  });
}
