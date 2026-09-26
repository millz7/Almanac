import 'package:almanac/app/app.dart';
import 'package:almanac/app/router.dart';
import 'package:almanac/core/context/almanac_context.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:almanac/features/journal/application/journal_providers.dart';
import 'package:almanac/features/journal/presentation/journal_screen.dart';
import 'package:almanac/features/journal/presentation/journal_text.dart';
import 'package:almanac/features/wheel/application/wheel_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// Saturday 26 September 2026, midday in London.
final saturday = DateTime.utc(2026, 9, 26, 11);
const today = CalendarDate(2026, 9, 26);

const _context = JournalContext(
  moonPhase: 'Waxing Gibbous',
  illuminatedFraction: 0.8,
  season: 'Autumn',
);

JournalEntry page(int day, String text, {JournalContext context = _context}) =>
    JournalEntry(
      date: CalendarDate(2026, 9, day),
      text: text,
      createdAt: DateTime.utc(2026, 9, day, 20),
      updatedAt: DateTime.utc(2026, 9, day, 20),
      context: context,
    );

void main() {
  setUpAll(useTimeZoneDatabase);

  final field = find.byType(TextField);
  final save = find.widgetWithText(ElevatedButton, JournalText.save);
  final previous = find.widgetWithIcon(IconButton, Icons.chevron_left);
  final next = find.widgetWithIcon(IconButton, Icons.chevron_right);
  final contents = find.widgetWithText(TextButton, JournalText.contents);
  final remove = find.widgetWithText(TextButton, JournalText.remove);

  Finder dialogButton(String label) => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(TextButton, label),
  );

  bool enabled(WidgetTester tester, Finder button) {
    final widget = tester.widget(button);
    return switch (widget) {
      IconButton(:final onPressed) => onPressed != null,
      ButtonStyleButton(:final onPressed) => onPressed != null,
      _ => throw StateError('not a button'),
    };
  }

  Future<ProviderContainer> openJournal(
    WidgetTester tester, {
    JournalStore? store,
    DateTime? now,
    DateTime Function()? clock,
    Set<FeatureId> features = const {FeatureId.journal},
    bool includeMaramataka = false,
    bool refreshEnabled = false,
    double textScale = 1,
    Size surface = const Size(420, 2400),
  }) async {
    tester.view.physicalSize = surface * 2;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final container = ProviderContainer(
      overrides: environmentOverrides(
        now: now ?? (clock == null ? saturday : null),
        clock: clock,
        features: features,
        journalStore: store ?? InMemoryJournalStore(),
        includeMaramataka: includeMaramataka,
        refreshEnabled: refreshEnabled,
      ),
    );
    if (!refreshEnabled) addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();
    container
        .read(routerProvider)
        .go(FeatureRegistry.byId(FeatureId.journal).route);
    await tester.pumpAndSettle();
    return container;
  }

  /// The page is a lazy list: something below the fold may not be
  /// built until it is scrolled to.
  Future<void> reveal(WidgetTester tester, Finder target) async {
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        200,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
    }
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, Finder control) async {
    await reveal(tester, control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  Future<void> write(WidgetTester tester, String text) async {
    await reveal(tester, field);
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  group('today\'s page', () {
    testWidgets('opens on today, with the full date and the Moon', (
      tester,
    ) async {
      final c = await openJournal(tester);
      expect(find.byType(JournalScreen), findsOneWidget);
      expect(find.text('Saturday 26 September 2026'), findsOneWidget);
      final moon = c.read(currentMoonProvider);
      expect(
        find.text(
          '${moon.phase.label} · ${moon.illuminatedPercent}% illuminated',
        ),
        findsOneWidget,
      );
      expect(field, findsOneWidget);
      // No date to choose: there is no picker anywhere on the page.
      expect(find.byType(CalendarDatePicker), findsNothing);
      expect(find.byIcon(Icons.calendar_today), findsNothing);
    });

    testWidgets('nothing written: Save is off and nothing is stored', (
      tester,
    ) async {
      final store = InMemoryJournalStore();
      await openJournal(tester, store: store);
      expect(enabled(tester, save), isFalse);
      await write(tester, '    ');
      expect(enabled(tester, save), isFalse);
      await press(tester, contents);
      await press(
        tester,
        find.widgetWithText(TextButton, JournalText.backToToday),
      );
      expect(store.writes, 0);
      expect((await store.read()).isEmpty, isTrue);
      await press(tester, contents);
      expect(find.text(JournalText.contentsEmpty), findsOneWidget);
    });

    testWidgets('write and save: one page, reopened for editing the same '
        'day, never duplicated', (tester) async {
      final store = InMemoryJournalStore();
      await openJournal(tester, store: store);
      await write(tester, 'Blackberries along the lane.');
      await press(tester, save);
      expect(find.text(JournalText.saved), findsOneWidget);
      expect(enabled(tester, save), isFalse);

      // Away and back: the same page, with its words, still editable.
      await press(tester, contents);
      expect(
        find.bySemanticsLabel(RegExp('^Saturday 26 September 2026')),
        findsOneWidget,
      );
      await press(tester, find.bySemanticsLabel(RegExp('^Saturday 26')));
      expect(find.text('Blackberries along the lane.'), findsOneWidget);
      await write(tester, 'Blackberries along the lane. And rain.');
      await press(tester, save);

      final book = await store.read();
      expect(book.entries, hasLength(1));
      expect(
        book.entries.single.text,
        'Blackberries along the lane. And rain.',
      );
    });

    testWidgets('a double tap on Save saves once', (tester) async {
      final store = InMemoryJournalStore();
      await openJournal(tester, store: store);
      await write(tester, 'Once');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.tap(save, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(store.writes, 1);
    });

    testWidgets('unsaved words: leaving asks first, and Keep editing keeps '
        'them', (tester) async {
      await openJournal(
        tester,
        store: InMemoryJournalStore(JournalBook([page(20, 'Earlier')])),
      );
      await write(tester, 'Not yet saved');
      await press(tester, previous);
      expect(find.text(UnsavedChanges.title), findsOneWidget);
      await press(tester, dialogButton(UnsavedChanges.keepEditing));
      expect(find.text('Not yet saved'), findsOneWidget);

      await press(tester, contents);
      await press(tester, dialogButton(UnsavedChanges.leave));
      expect(find.text(JournalText.contents), findsWidgets);
      expect(find.text('Not yet saved'), findsNothing);
    });

    testWidgets('system Back with unsaved words asks too', (tester) async {
      await openJournal(tester);
      await write(tester, 'Half a thought');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(UnsavedChanges.title), findsOneWidget);
      await press(tester, dialogButton(UnsavedChanges.keepEditing));
      expect(find.text('Half a thought'), findsOneWidget);
    });
  });

  group('the book: pages on 18, 20 and 26 September', () {
    JournalStore seeded() => InMemoryJournalStore(
      JournalBook([
        page(18, 'The eighteenth'),
        page(20, 'The twentieth'),
        page(26, 'Today\'s words'),
      ]),
    );

    testWidgets('back through saved pages only, and forward to today', (
      tester,
    ) async {
      await openJournal(tester, store: seeded());
      expect(find.text('Today\'s words'), findsOneWidget);
      expect(enabled(tester, next), isFalse);

      await press(tester, previous);
      expect(find.text('Sunday 20 September 2026'), findsOneWidget);
      expect(find.text('The twentieth'), findsOneWidget);
      expect(field, findsNothing, reason: 'a past page is read-only');
      expect(find.text(JournalText.readOnly), findsOneWidget);

      await press(tester, previous);
      expect(find.text('Friday 18 September 2026'), findsOneWidget);
      expect(enabled(tester, previous), isFalse);
      // Never a blank day in between.
      for (final day in ['19', '21', '22', '23', '24', '25']) {
        expect(find.textContaining('$day September'), findsNothing);
      }

      await press(tester, next);
      expect(find.text('Sunday 20 September 2026'), findsOneWidget);
      await press(tester, next);
      expect(find.text('Saturday 26 September 2026'), findsOneWidget);
      expect(field, findsOneWidget);
      expect(find.text('Today\'s words'), findsOneWidget);
    });

    testWidgets('the contents list those three pages and nothing else', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openJournal(tester, store: seeded());
      await press(tester, contents);

      expect(find.text('September 2026'), findsOneWidget);
      final rows = [
        'Saturday 26 September 2026',
        'Sunday 20 September 2026',
        'Friday 18 September 2026',
      ];
      for (final row in rows) {
        final finder = find.bySemanticsLabel(RegExp('^$row\\. Waxing Gibbous'));
        expect(finder, findsOneWidget, reason: row);
        expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
      }
      expect(find.textContaining('19 September'), findsNothing);
      // Newest first.
      final ys = [for (final row in rows) tester.getTopLeft(find.text(row)).dy];
      expect(ys, orderedEquals([...ys]..sort()));

      await press(tester, find.text('Friday 18 September 2026'));
      expect(find.text('The eighteenth'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a past page can be removed, after asking; a double tap '
        'is safe', (tester) async {
      final store = seeded();
      await openJournal(tester, store: store);
      await press(tester, previous);
      expect(find.text('The twentieth'), findsOneWidget);

      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.tap(remove, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await press(tester, dialogButton(JournalText.removeNo));
      expect((await store.read()).entries, hasLength(3));

      await press(tester, remove);
      final yes = dialogButton(JournalText.removeYes);
      await tester.tap(yes);
      await tester.tap(yes, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect((await store.read()).entries.map((e) => e.id), [
        '2026-09-18',
        '2026-09-26',
      ]);
      // Back on today, and still on the Journal.
      expect(find.byType(JournalScreen), findsOneWidget);
      expect(find.text('Saturday 26 September 2026'), findsOneWidget);
    });
  });

  group('the header', () {
    testWidgets('a festival only on its own day, and only with the Wheel', (
      tester,
    ) async {
      final probe = ProviderContainer(
        overrides: environmentOverrides(
          now: DateTime.utc(2026, 9, 10, 11),
          features: {FeatureId.wheel},
        ),
      );
      final festival = probe.read(nextFestivalProvider);
      probe.dispose();
      final day = festival.date;
      final name = festival.id.label;

      await openJournal(
        tester,
        now: DateTime.utc(day.year, day.month, day.day, 11),
        features: {FeatureId.journal, FeatureId.wheel},
      );
      expect(find.text(name), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('not while it is only approaching', (tester) async {
      final probe = ProviderContainer(
        overrides: environmentOverrides(
          now: DateTime.utc(2026, 9, 10, 11),
          features: {FeatureId.wheel},
        ),
      );
      final festival = probe.read(nextFestivalProvider);
      probe.dispose();
      final before = festival.date.addDays(-2);

      await openJournal(
        tester,
        now: DateTime.utc(before.year, before.month, before.day, 11),
        features: {FeatureId.journal, FeatureId.wheel},
      );
      expect(find.text(festival.id.label), findsNothing);
    });

    testWidgets('a past page shows its own snapshot, not today\'s', (
      tester,
    ) async {
      const then = JournalContext(
        moonPhase: 'New Moon',
        illuminatedFraction: 0.01,
        season: 'Summer',
        festivalId: 'lughnasadh',
        festivalName: 'Lughnasadh',
        maramatakaId: 'whiro',
        maramatakaName: 'Whiro',
        maramatakaReference: 'te-ara-ngati-kahungunu',
      );
      await openJournal(
        tester,
        store: InMemoryJournalStore(
          JournalBook([page(1, 'Old page', context: then)]),
        ),
      );
      await press(tester, previous);
      expect(find.text('New Moon · 1% illuminated'), findsOneWidget);
      expect(find.text('Summer'), findsOneWidget);
      expect(find.text('Lughnasadh'), findsOneWidget);
      expect(find.text('Maramataka: Whiro (estimated)'), findsOneWidget);
    });
  });

  group('midnight', () {
    testWidgets('words begun before midnight are saved on that day; after '
        'leaving, today is the new day, blank', (tester) async {
      var now = DateTime.utc(2026, 9, 26, 22, 50); // 23:50 in London
      final store = InMemoryJournalStore();
      final c = await openJournal(
        tester,
        clock: () => now,
        store: store,
        refreshEnabled: true,
      );
      expect(find.text('Saturday 26 September 2026'), findsOneWidget);
      await write(tester, 'Late thoughts');

      now = DateTime.utc(2026, 9, 26, 23, 5); // 00:05 on the 27th
      await tester.pump(const Duration(minutes: 11));
      await tester.pumpAndSettle();
      expect(c.read(todayProvider), const CalendarDate(2026, 9, 27));
      // Still the page it was opened as.
      expect(find.text('Saturday 26 September 2026'), findsOneWidget);
      expect(find.text(JournalText.midnight), findsOneWidget);

      await press(tester, save);
      expect((await store.read()).entries.single.date, today);

      await press(tester, contents);
      await press(
        tester,
        find.widgetWithText(TextButton, JournalText.backToToday),
      );
      expect(find.text('Sunday 27 September 2026'), findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect((await store.read()).entries, hasLength(1));

      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });

    testWidgets('with nothing unsaved, the page turns to the new day by '
        'itself', (tester) async {
      var now = DateTime.utc(2026, 9, 26, 22, 50);
      final store = InMemoryJournalStore();
      final c = await openJournal(
        tester,
        clock: () => now,
        store: store,
        refreshEnabled: true,
      );
      await write(tester, 'Saved before midnight');
      await press(tester, save);

      now = DateTime.utc(2026, 9, 26, 23, 5);
      await tester.pump(const Duration(minutes: 11));
      await tester.pumpAndSettle();
      expect(find.text('Sunday 27 September 2026'), findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      // Yesterday is now a past page, read-only.
      await press(tester, previous);
      expect(find.text('Saved before midnight'), findsOneWidget);
      expect(field, findsNothing);
      expect((await store.read()).entries, hasLength(1));

      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  });

  group('dormancy', () {
    testWidgets('switched off while open: back to the Environment, pages '
        'kept; switched on again: still there', (tester) async {
      final store = InMemoryJournalStore(
        JournalBook([page(20, 'Kept while away')]),
      );
      final c = await openJournal(tester, store: store);
      await c
          .read(userSettingsProvider.notifier)
          .setFeatureChosen(FeatureId.journal, false);
      await tester.pumpAndSettle();
      expect(find.byType(JournalScreen), findsNothing);
      expect(
        c.read(routerProvider).routerDelegate.currentConfiguration.uri.path,
        kEnvironmentRoute,
      );
      expect((await store.read()).entries, hasLength(1));

      await c
          .read(userSettingsProvider.notifier)
          .setFeatureChosen(FeatureId.journal, true);
      c.read(routerProvider).go('/journal');
      await tester.pumpAndSettle();
      await press(tester, previous);
      expect(find.text('Kept while away'), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('labelled field, named page turns, read-only announced, 48dp', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openJournal(
        tester,
        store: InMemoryJournalStore(JournalBook([page(20, 'Words')])),
      );
      expect(
        find.bySemanticsLabel(
          RegExp('Journal entry for Saturday 26 September 2026'),
        ),
        findsOneWidget,
      );
      expect(find.text(JournalText.fieldLabel), findsOneWidget);
      for (final label in [JournalText.previous, JournalText.next]) {
        expect(find.byTooltip(label), findsOneWidget);
      }
      for (final button in [previous, next]) {
        final size = tester.getSize(button);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      expect(tester.getSize(contents).height, greaterThanOrEqualTo(48));

      await press(tester, previous);
      expect(
        find.bySemanticsLabel(
          RegExp(r'^Journal page for Sunday 20 September 2026\. Read only\.'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    for (final size in [const Size(320, 700), const Size(800, 1280)]) {
      testWidgets('2x text at ${size.width.toInt()} wide: nothing overflows', (
        tester,
      ) async {
        await openJournal(
          tester,
          textScale: 2,
          surface: size,
          store: InMemoryJournalStore(
            JournalBook([page(18, 'One'), page(20, 'Two')]),
          ),
        );
        expect(tester.takeException(), isNull);
        await write(tester, 'Words at twice the size');
        await press(tester, save);
        expect(tester.takeException(), isNull);
        await press(tester, previous);
        expect(tester.takeException(), isNull);
        await press(tester, contents);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
