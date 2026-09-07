import 'package:almanac/app/almanac_button.dart';
import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/features/cycle/application/cycle_providers.dart';
import 'package:almanac/features/cycle/presentation/cycle_text.dart';
import 'package:almanac/features/cycle/presentation/widgets/cycle_calendar.dart';
import 'package:almanac/features/cycle/presentation/widgets/cycle_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// Monday 7 September 2026, midday.
final testNow = DateTime.utc(2026, 9, 7, 12);
const testToday = CalendarDate(2026, 9, 7);

void main() {
  setUpAll(useTimeZoneDatabase);

  final recordToday = find.widgetWithText(
    ElevatedButton,
    CycleText.recordToday,
  );
  final chooseAnother = find.widgetWithText(
    TextButton,
    CycleText.chooseAnotherDate,
  );
  final calendarButton = find.widgetWithText(TextButton, CycleText.calendar);
  final adjustButton = find.widgetWithText(TextButton, CycleText.adjust);
  final back = find.widgetWithText(TextButton, CycleText.back);
  final deleteAll = find.widgetWithText(TextButton, CycleText.deleteAll);
  final confirmDelete = find.widgetWithText(TextButton, CycleText.delete);
  final keep = find.widgetWithText(TextButton, CycleText.keep);
  final longer = find.widgetWithIcon(IconButton, Icons.add);
  final shorter = find.widgetWithIcon(IconButton, Icons.remove);

  Finder navTab(String name) => find.descendant(
    of: find.byType(AlmanacNavigationBar),
    matching: find.bySemanticsLabel(name),
  );

  /// Opens Cycle through the real navigation.
  Future<ProviderContainer> openCycle(
    WidgetTester tester, {
    CycleStore? store,
    DateTime? now,
    double textScale = 1,
    bool reducedMotion = false,
    Size surface = const Size(420, 2000),
    Set<FeatureId> features = const {FeatureId.cycle},
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
      overrides: environmentOverrides(
        now: now ?? testNow,
        features: features,
        cycleStore: store ?? InMemoryCycleStore(),
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

    await tester.tap(navTab('Cycle'));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> press(WidgetTester tester, Finder control) async {
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  /// Picks a day of the current month in the Material date picker.
  Future<void> pickDay(WidgetTester tester, String day) async {
    await tester.tap(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text(day),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  group('first use', () {
    testWidgets('invites one recording, and asks for nothing else', (
      tester,
    ) async {
      await openCycle(tester);

      expect(find.text(CycleText.introHeading), findsOneWidget);
      expect(find.text(CycleText.introBody), findsOneWidget);
      expect(recordToday, findsOneWidget);
      expect(chooseAnother, findsOneWidget);

      // Nothing about a cycle that does not exist yet.
      expect(find.byType(CycleWheel), findsNothing);
      expect(find.textContaining('Cycle day'), findsNothing);
    });

    testWidgets('asks nothing about a body, a history or an intention', (
      tester,
    ) async {
      await openCycle(tester);

      for (final never in [
        'age',
        'weight',
        'height',
        'medication',
        'diagnos',
        'pregnan',
        'contracept',
        'fertil',
        'sexual',
      ]) {
        expect(
          find.textContaining(never, findRichText: true),
          findsNothing,
          reason: never,
        );
      }
    });

    testWidgets('says where the dates will live before any are given', (
      tester,
    ) async {
      await openCycle(tester);

      expect(find.text(CycleText.privacyNote), findsOneWidget);
    });
  });

  group('recording', () {
    testWidgets('"Record today" begins a cycle on day one', (tester) async {
      await openCycle(tester);
      await press(tester, recordToday);

      expect(find.text('Cycle day 1'), findsOneWidget);
      expect(
        find.text('${CycleText.recordedStartLabel}: Monday 7 September'),
        findsOneWidget,
      );
      expect(find.text('Approximate menstrual phase'), findsOneWidget);
      expect(find.text('Using a 28-day estimate'), findsOneWidget);
      expect(find.byType(CycleWheel), findsOneWidget);
    });

    testWidgets('the day advances with the calendar, not with a timer', (
      tester,
    ) async {
      final store = InMemoryCycleStore();
      await openCycle(tester, store: store);
      await press(tester, recordToday);
      expect(find.text('Cycle day 1'), findsOneWidget);

      // Four days later, same device, same stored date.
      await openCycle(tester, store: store, now: DateTime.utc(2026, 9, 11, 12));

      expect(find.text('Cycle day 5'), findsOneWidget);
      expect(
        find.text('${CycleText.recordedStartLabel}: Monday 7 September'),
        findsOneWidget,
      );
    });

    testWidgets('"Choose another date" offers nothing later than today', (
      tester,
    ) async {
      await openCycle(tester);
      await press(tester, chooseAnother);

      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      // A future date cannot be chosen, rather than being chosen and
      // then refused.
      expect(picker.lastDate, testToday.toLocalDateTime());
      expect(picker.initialDate, testToday.toLocalDateTime());
    });

    testWidgets('a chosen date is counted from', (tester) async {
      final container = await openCycle(tester);
      await press(tester, chooseAnother);
      await pickDay(tester, '3');

      expect(find.text('Cycle day 5'), findsOneWidget);
      expect(container.read(cycleDataProvider).value!.periodStarts, [
        const CalendarDate(2026, 9, 3),
      ]);
    });
  });

  group('the current cycle', () {
    Future<ProviderContainer> withRecorded(
      WidgetTester tester, {
      List<CalendarDate> starts = const [],
      int length = kDefaultCycleLength,
      double textScale = 1,
      bool reducedMotion = false,
    }) => openCycle(
      tester,
      store: InMemoryCycleStore(
        CycleData(periodStarts: starts, assumedCycleLength: length),
      ),
      textScale: textScale,
      reducedMotion: reducedMotion,
    );

    testWidgets('the day is the biggest thing on it', (tester) async {
      await withRecorded(tester, starts: [testToday.addDays(-11)]);

      final day = tester.widget<Text>(find.text('Cycle day 12'));
      final phase = tester.widget<Text>(
        find.text('Approximate follicular phase'),
      );
      expect(day.style!.fontSize, greaterThan(phase.style!.fontSize!));
    });

    testWidgets('a reflective line, and a reminder that it may not fit', (
      tester,
    ) async {
      await withRecorded(tester, starts: [testToday.addDays(-11)]);

      expect(find.text('Something is beginning to build.'), findsOneWidget);
      expect(find.text(CycleText.experienceMayDiffer), findsOneWidget);
    });

    testWidgets('estimates are gathered together and labelled', (tester) async {
      await withRecorded(tester, starts: [const CalendarDate(2026, 9, 1)]);

      expect(find.text(CycleText.estimatesHeading), findsOneWidget);
      expect(
        find.text('Estimated ovulatory window: 14 September to 16 September'),
        findsOneWidget,
      );
      expect(
        find.text('Estimated next start: Tuesday 29 September'),
        findsOneWidget,
      );
      expect(find.text(CycleText.estimateCaution), findsOneWidget);

      // Never in the present tense about the person reading it.
      expect(find.textContaining('You are ovulating'), findsNothing);
      expect(find.textContaining('fertile'), findsNothing);
    });

    testWidgets('a cycle longer than the estimate is stated, not flagged', (
      tester,
    ) async {
      await withRecorded(tester, starts: [testToday.addDays(-30)]);

      expect(find.text('Cycle day 31'), findsOneWidget);
      expect(find.text(CycleText.pastEstimate), findsOneWidget);
      expect(find.text('Approximate luteal phase'), findsOneWidget);
    });

    testWidgets('recorded lengths are listed without judgement', (
      tester,
    ) async {
      await withRecorded(
        tester,
        starts: [
          const CalendarDate(2026, 6, 3),
          const CalendarDate(2026, 7, 1),
          const CalendarDate(2026, 8, 1),
          const CalendarDate(2026, 8, 28),
        ],
      );

      expect(find.text(CycleText.recentCyclesHeading), findsOneWidget);
      expect(
        find.text('${CycleText.recordedLengthLabel}: 27 days'),
        findsOneWidget,
      );
      expect(
        find.text('${CycleText.recordedLengthLabel}: 31 days'),
        findsOneWidget,
      );
      // No average, no verdict.
      expect(find.textContaining('average'), findsNothing);
      expect(find.textContaining('normal'), findsNothing);
    });

    testWidgets('there is nothing to show a cycle nobody has begun', (
      tester,
    ) async {
      await withRecorded(tester);
      expect(find.text(CycleText.introHeading), findsOneWidget);
    });
  });

  group('the assumed length', () {
    testWidgets('steps a day at a time, and moves the estimates with it', (
      tester,
    ) async {
      final container = await openCycle(
        tester,
        store: InMemoryCycleStore(
          CycleData(periodStarts: [const CalendarDate(2026, 9, 1)]),
        ),
      );
      await press(tester, adjustButton);

      expect(find.text('28 days'), findsOneWidget);
      await press(tester, longer);
      await press(tester, longer);
      expect(find.text('30 days'), findsOneWidget);

      await press(tester, back);
      expect(find.text('Using a 30-day estimate'), findsOneWidget);
      expect(
        find.text('Estimated next start: Thursday 1 October'),
        findsOneWidget,
      );
      // The recorded date is exactly where it was.
      expect(container.read(cycleDataProvider).value!.periodStarts, [
        const CalendarDate(2026, 9, 1),
      ]);
      expect(
        find.text('${CycleText.recordedStartLabel}: Tuesday 1 September'),
        findsOneWidget,
      );
    });

    testWidgets('stops at 21 days and at 40', (tester) async {
      await openCycle(tester);
      await press(tester, recordToday);
      await press(tester, adjustButton);

      for (var i = 0; i < 10; i++) {
        await press(tester, shorter);
      }
      expect(find.text('21 days'), findsOneWidget);
      expect(tester.widget<IconButton>(shorter).onPressed, isNull);

      for (var i = 0; i < 25; i++) {
        await press(tester, longer);
      }
      expect(find.text('40 days'), findsOneWidget);
      expect(tester.widget<IconButton>(longer).onPressed, isNull);
    });

    testWidgets('says plainly that it changes estimates only', (tester) async {
      await openCycle(tester);
      await press(tester, recordToday);
      await press(tester, adjustButton);

      expect(find.text(CycleText.lengthNote), findsOneWidget);
    });
  });

  group('the calendar', () {
    Future<ProviderContainer> openCalendar(
      WidgetTester tester, {
      List<CalendarDate> starts = const [],
      double textScale = 1,
    }) async {
      final container = await openCycle(
        tester,
        store: InMemoryCycleStore(CycleData(periodStarts: starts)),
        textScale: textScale,
      );
      await press(tester, calendarButton);
      return container;
    }

    /// How one day of the shown month is drawn.
    DayMark markOn(
      WidgetTester tester,
      CalendarDate date, {
      bool today = false,
    }) {
      final label = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((s) => s.properties.label)
          .whereType<String>()
          .firstWhere(
            (l) => l.startsWith(
              '${['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][date.weekday - 1]} ${date.day} ',
            ),
            orElse: () => '',
          );
      if (label.contains('Recorded period start')) return DayMark.recorded;
      if (label.contains('Estimated period start')) return DayMark.estimated;
      return DayMark.plain;
    }

    testWidgets('shows the month, with today in it', (tester) async {
      await openCalendar(tester, starts: [const CalendarDate(2026, 9, 3)]);

      expect(find.text('September 2026'), findsOneWidget);
      expect(find.byType(CycleCalendar), findsOneWidget);
      expect(
        find.bySemanticsLabel('Monday 7 September. Today.'),
        findsOneWidget,
      );
    });

    testWidgets('marks what was recorded, and says so in words', (
      tester,
    ) async {
      await openCalendar(tester, starts: [const CalendarDate(2026, 9, 3)]);

      expect(markOn(tester, const CalendarDate(2026, 9, 3)), DayMark.recorded);
      expect(
        find.bySemanticsLabel(
          RegExp('Thursday 3 September. Recorded period start'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('an estimate never looks or sounds like a recorded date', (
      tester,
    ) async {
      await openCalendar(tester, starts: [const CalendarDate(2026, 9, 3)]);

      // 1 October is an estimate; the marks differ, and so do the words.
      await press(tester, find.byTooltip(CycleText.nextMonth));
      expect(find.text('October 2026'), findsOneWidget);
      expect(
        markOn(tester, const CalendarDate(2026, 10, 1)),
        DayMark.estimated,
      );
      expect(
        find.bySemanticsLabel(
          RegExp('Thursday 1 October. Estimated period start'),
        ),
        findsOneWidget,
      );
      // And the legend names both, so the difference is never left to
      // the drawing.
      expect(find.text(CycleText.recordedLegend), findsOneWidget);
      expect(find.text(CycleText.estimatedLegend), findsOneWidget);
    });

    testWidgets('invents no history before the first recorded date', (
      tester,
    ) async {
      await openCalendar(tester, starts: [const CalendarDate(2026, 9, 3)]);

      await press(tester, find.byTooltip(CycleText.previousMonth));
      expect(find.text('August 2026'), findsOneWidget);

      for (var day = 1; day <= 31; day++) {
        expect(
          markOn(tester, CalendarDate(2026, 8, day)),
          DayMark.plain,
          reason: 'August $day',
        );
      }
    });

    testWidgets('a recorded date can be edited from it', (tester) async {
      final container = await openCalendar(
        tester,
        starts: [const CalendarDate(2026, 9, 3)],
      );

      await press(
        tester,
        find.bySemanticsLabel(
          RegExp('Thursday 3 September. Recorded period start'),
        ),
      );
      expect(find.text('Thursday 3 September'), findsOneWidget);

      await press(tester, find.widgetWithText(TextButton, CycleText.editDate));
      await pickDay(tester, '4');

      expect(container.read(cycleDataProvider).value!.periodStarts, [
        const CalendarDate(2026, 9, 4),
      ]);
    });

    testWidgets('a recorded date can be deleted from it, once confirmed', (
      tester,
    ) async {
      final container = await openCalendar(
        tester,
        starts: [const CalendarDate(2026, 9, 3)],
      );

      await press(
        tester,
        find.bySemanticsLabel(
          RegExp('Thursday 3 September. Recorded period start'),
        ),
      );
      await press(
        tester,
        find.widgetWithText(TextButton, CycleText.deleteDate),
      );

      expect(find.text(CycleText.deleteOneTitle), findsOneWidget);
      await press(tester, confirmDelete);

      expect(container.read(cycleDataProvider).value!.periodStarts, isEmpty);
    });
  });

  group('deleting', () {
    testWidgets('one date can be kept after all', (tester) async {
      final container = await openCycle(
        tester,
        store: InMemoryCycleStore(CycleData(periodStarts: [testToday])),
      );
      await press(tester, adjustButton);
      await press(
        tester,
        find.byTooltip('${CycleText.deleteDate}, Monday 7 September'),
      );

      expect(find.text(CycleText.deleteOneTitle), findsOneWidget);
      await press(tester, keep);

      expect(container.read(cycleDataProvider).value!.periodStarts, [
        testToday,
      ]);
    });

    testWidgets('everything can go, and it asks first in plain words', (
      tester,
    ) async {
      final store = InMemoryCycleStore(
        CycleData(
          periodStarts: [testToday.addDays(-28), testToday],
          assumedCycleLength: 31,
        ),
      );
      final container = await openCycle(tester, store: store);
      await press(tester, adjustButton);
      await press(tester, deleteAll);

      expect(find.text(CycleText.deleteAllTitle), findsOneWidget);
      expect(find.text(CycleText.deleteAllBody), findsOneWidget);
      expect(confirmDelete, findsOneWidget);
      expect(keep, findsOneWidget);

      await press(tester, confirmDelete);

      // Gone from the screen, from memory, and from the store.
      expect(container.read(cycleDataProvider).value!.isEmpty, isTrue);
      expect((await store.read()).periodStarts, isEmpty);
      expect((await store.read()).assumedCycleLength, kDefaultCycleLength);
    });

    testWidgets('after everything goes, it is a first use again', (
      tester,
    ) async {
      await openCycle(
        tester,
        store: InMemoryCycleStore(CycleData(periodStarts: [testToday])),
      );
      await press(tester, adjustButton);
      await press(tester, deleteAll);
      await press(tester, confirmDelete);

      expect(find.text(CycleText.introHeading), findsOneWidget);
      expect(recordToday, findsOneWidget);
      expect(find.textContaining('Cycle day'), findsNothing);
    });
  });

  group('living in the Almanac', () {
    testWidgets('the Almanac is reachable from every page of it', (
      tester,
    ) async {
      await openCycle(
        tester,
        store: InMemoryCycleStore(CycleData(periodStarts: [testToday])),
      );

      expect(find.byType(AlmanacButton), findsOneWidget);
      await press(tester, calendarButton);
      expect(find.byType(AlmanacButton), findsOneWidget);
      await press(tester, back);
      await press(tester, adjustButton);
      expect(find.byType(AlmanacButton), findsOneWidget);
    });

    testWidgets('there is no immersive mode and nothing left running', (
      tester,
    ) async {
      await openCycle(
        tester,
        store: InMemoryCycleStore(CycleData(periodStarts: [testToday])),
        features: {FeatureId.cycle, FeatureId.garden},
      );

      // The navigation never goes away here — Cycle is a page, not a
      // session.
      expect(find.byType(AlmanacNavigationBar), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);

      await tester.tap(navTab('Garden'));
      await tester.pumpAndSettle();

      expect(tester.binding.transientCallbackCount, 0);
      expect(find.byType(CycleWheel), findsNothing);
    });

    testWidgets('nothing about a cycle appears anywhere else', (tester) async {
      await openCycle(
        tester,
        store: InMemoryCycleStore(CycleData(periodStarts: [testToday])),
        features: {FeatureId.cycle, FeatureId.garden},
      );
      expect(find.text('Cycle day 1'), findsOneWidget);

      await tester.tap(navTab('Environment'));
      await tester.pumpAndSettle();

      // The Environment shows today's date, as it always has. What it
      // must never show is anything about a cycle.
      expect(find.textContaining('Cycle day'), findsNothing);
      expect(find.textContaining(CycleText.recordedStartLabel), findsNothing);
      expect(find.textContaining('Approximate'), findsNothing);
      expect(find.textContaining('estimate'), findsNothing);
    });
  });

  group('reduced motion', () {
    testWidgets('the wheel is simply already drawn', (tester) async {
      await openCycle(
        tester,
        store: InMemoryCycleStore(CycleData(periodStarts: [testToday])),
        reducedMotion: true,
      );

      expect(tester.widget<CycleWheel>(find.byType(CycleWheel)).entrance, 1);
      expect(tester.binding.transientCallbackCount, 0);
      expect(find.text('Cycle day 1'), findsOneWidget);
    });

    testWidgets('everything still works', (tester) async {
      final container = await openCycle(tester, reducedMotion: true);
      await press(tester, recordToday);
      await press(tester, adjustButton);
      await press(tester, longer);

      expect(container.read(cycleDataProvider).value!.assumedCycleLength, 29);
    });
  });

  group('accessibility', () {
    testWidgets('the cycle can be understood without seeing the drawing', (
      tester,
    ) async {
      await openCycle(
        tester,
        store: InMemoryCycleStore(
          CycleData(periodStarts: [testToday.addDays(-11)]),
        ),
      );

      expect(
        find.bySemanticsLabel(
          'Cycle day 12. Approximate follicular phase. '
          'Using a 28-day estimate.',
        ),
        findsOneWidget,
      );
      // And the drawing itself says nothing.
      expect(
        find.descendant(
          of: find.byType(CycleWheel),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });

    testWidgets('every control is a comfortable target', (tester) async {
      await openCycle(tester);
      for (final control in [recordToday, chooseAnother]) {
        expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
      }

      await press(tester, recordToday);
      for (final control in [calendarButton, adjustButton]) {
        expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
      }

      await press(tester, adjustButton);
      for (final control in [shorter, longer, deleteAll]) {
        expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
      }

      await press(tester, back);
      await press(tester, calendarButton);
      for (final icon in [Icons.chevron_left, Icons.chevron_right]) {
        expect(
          tester.getSize(find.widgetWithIcon(IconButton, icon)).height,
          greaterThanOrEqualTo(48),
        );
      }
      // And every day in the grid, since each one is a place a finger
      // has to land.
      expect(
        tester.getSize(
          find.bySemanticsLabel(
            RegExp('Monday 7 September. Today. Recorded period start'),
          ),
        ),
        const Size(48, 48),
      );
    });

    testWidgets('doubling the text size breaks nothing', (tester) async {
      await openCycle(
        tester,
        store: InMemoryCycleStore(
          CycleData(periodStarts: [testToday.addDays(-11)]),
        ),
        textScale: 2,
      );

      expect(find.text('Cycle day 12'), findsOneWidget);
      await press(tester, adjustButton);
      expect(find.text('28 days'), findsOneWidget);

      await press(tester, back);
      await press(tester, calendarButton);
      // The grid grows with the text and scrolls sideways rather than
      // squeezing the numbers — the same rule the navigation bar keeps.
      expect(find.text('September 2026'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CycleCalendar),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
    });
  });
}
