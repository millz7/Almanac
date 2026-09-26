import 'dart:io';

import 'package:almanac/app/context/festival_context.dart';
import 'package:almanac/core/context/almanac_context.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/features/journal/application/journal_providers.dart';
import 'package:almanac/features/journal/data/shared_preferences_journal_store.dart';
import 'package:almanac/features/wheel/application/wheel_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// Midday in London on a date, as the instant the clock reads.
DateTime londonNoon(int month, int day) => DateTime.utc(2026, month, day, 11);

const _moon = JournalContext(
  moonPhase: 'Full Moon',
  illuminatedFraction: 0.99,
  season: 'Autumn',
);

JournalEntry page(int day, {String text = 'Words', int month = 9}) =>
    JournalEntry(
      date: CalendarDate(2026, month, day),
      text: text,
      createdAt: DateTime.utc(2026, month, day, 20),
      updatedAt: DateTime.utc(2026, month, day, 20),
      context: _moon,
    );

void main() {
  setUpAll(useTimeZoneDatabase);

  /// One run of the app: a container over [store], at [now] (or a moving
  /// [clock]).
  Future<ProviderContainer> launch({
    required JournalStore store,
    DateTime? now,
    DateTime Function()? clock,
    Set<FeatureId> features = const {FeatureId.journal},
    bool includeMaramataka = false,
  }) async {
    final container = ProviderContainer(
      overrides: environmentOverrides(
        now: now,
        clock: clock,
        journalStore: store,
        features: features,
        includeMaramataka: includeMaramataka,
      ),
    );
    addTearDown(container.dispose);
    await container.read(naturalEnvironmentProvider.future);
    await container.read(journalProvider.future);
    return container;
  }

  JournalController journalOf(ProviderContainer c) =>
      c.read(journalProvider.notifier);
  JournalBook bookOf(ProviderContainer c) => c.read(journalProvider).value!;

  group('a page exists only once something is written', () {
    test('opening today writes nothing and makes no record', () async {
      final store = InMemoryJournalStore();
      final c = await launch(store: store, now: londonNoon(9, 26));
      final draft = journalOf(c).openToday();
      expect(draft.date, const CalendarDate(2026, 9, 26));
      expect(store.writes, 0);
      expect(bookOf(c).isEmpty, isTrue);
    });

    test('blank or whitespace text is refused, not stored', () async {
      final store = InMemoryJournalStore();
      final c = await launch(store: store, now: londonNoon(9, 26));
      final draft = journalOf(c).openToday();
      for (final blank in ['', '   ', '\n\n\t']) {
        await expectLater(
          journalOf(c).save(draft, blank),
          throwsA(isA<ArgumentError>()),
        );
      }
      expect(store.writes, 0);
      expect(bookOf(c).isEmpty, isTrue);
    });

    test('saving keeps the words exactly as written', () async {
      final store = InMemoryJournalStore();
      final c = await launch(store: store, now: londonNoon(9, 26));
      const words = '  Rain on the roof.\n\nThe | fig — ripe. "Quoted" ';
      await journalOf(c).save(journalOf(c).openToday(), words);
      expect(bookOf(c).find(const CalendarDate(2026, 9, 26))!.text, words);
    });
  });

  group('persistence across restarts', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('save, restart: the page is there, with its snapshot', () async {
      final first = await launch(
        store: SharedPreferencesJournalStore(),
        now: londonNoon(9, 26),
      );
      await journalOf(first).save(journalOf(first).openToday(), 'First page');
      final saved = bookOf(first).entries.single;

      final second = await launch(
        store: SharedPreferencesJournalStore(),
        now: londonNoon(9, 26),
      );
      final reread = bookOf(second).entries.single;
      expect(reread, saved);
      expect(reread.id, '2026-09-26');
      expect(reread.text, 'First page');
    });

    test('the same day reopens the same page; editing never duplicates '
        'it', () async {
      var now = londonNoon(9, 26);
      final c = await launch(
        store: SharedPreferencesJournalStore(),
        clock: () => now,
      );
      await journalOf(c).save(journalOf(c).openToday(), 'Morning');
      final created = bookOf(c).entries.single.createdAt;

      now = now.add(const Duration(hours: 5));
      final again = journalOf(c).openToday();
      expect(again.date, const CalendarDate(2026, 9, 26));
      await journalOf(c).save(again, 'Morning, and evening');

      final restarted = await launch(
        store: SharedPreferencesJournalStore(),
        now: now,
      );
      final entry = bookOf(restarted).entries.single;
      expect(entry.text, 'Morning, and evening');
      expect(entry.createdAt, created);
      expect(entry.updatedAt, now);
      expect(bookOf(restarted).entries, hasLength(1));
    });

    test('the next day: yesterday is closed, today is a new blank page, and '
        'no record is made for it', () async {
      final day1 = await launch(
        store: SharedPreferencesJournalStore(),
        now: londonNoon(9, 26),
      );
      await journalOf(day1).save(journalOf(day1).openToday(), 'Saturday');

      final day2 = await launch(
        store: SharedPreferencesJournalStore(),
        now: londonNoon(9, 27),
      );
      final draft = journalOf(day2).openToday();
      expect(draft.date, const CalendarDate(2026, 9, 27));
      expect(bookOf(day2).find(draft.date), isNull);
      expect(bookOf(day2).entries.map((e) => e.id), ['2026-09-26']);

      // Restart again without writing: still only one page.
      final day2Again = await launch(
        store: SharedPreferencesJournalStore(),
        now: londonNoon(9, 27),
      );
      expect(bookOf(day2Again).entries.map((e) => e.id), ['2026-09-26']);
    });

    test('deleting a past page, then restarting: it is gone', () async {
      final c = await launch(
        store: SharedPreferencesJournalStore(),
        now: londonNoon(9, 26),
      );
      await c
          .read(journalStoreProvider)
          .write(JournalBook([page(18), page(20)]));
      c.invalidate(journalProvider);
      await c.read(journalProvider.future);

      await journalOf(c).remove(const CalendarDate(2026, 9, 18));
      final restarted = await launch(
        store: SharedPreferencesJournalStore(),
        now: londonNoon(9, 26),
      );
      expect(bookOf(restarted).entries.map((e) => e.id), ['2026-09-20']);
    });

    test('damaged, blank and duplicated lines: good pages survive, one per '
        'date, and unreadable lines are kept through a save', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            'journal.entries': <String>[
              encodeJournalEntry(page(18, text: 'kept')),
              encodeJournalEntry(page(18, text: 'duplicate')),
              encodeJournalEntry(page(19, text: '   ')),
              '{not json',
              '{"date":"2026-09-21","text":"from a newer version"}',
            ],
          });
      final store = SharedPreferencesJournalStore();
      final book = await store.read();
      expect(book.entries.map((e) => e.text), ['kept']);

      await store.write(book.putting(page(26, text: 'new')));
      final lines = await SharedPreferencesAsyncPlatform.instance!
          .getStringList('journal.entries', const SharedPreferencesOptions());
      expect(lines, contains('{not json'));
      expect(
        lines,
        contains('{"date":"2026-09-21","text":"from a newer version"}'),
      );
      expect(
        (await SharedPreferencesJournalStore().read()).entries,
        hasLength(2),
      );
    });

    test('its own key only', () {
      expect(SharedPreferencesJournalStore.keys, {'journal.entries'});
    });
  });

  group('the date is locked to today', () {
    test(
      'the draft is always the app\'s today, in the app\'s own zone',
      () async {
        // 23:30 UTC on the 25th is already the 26th in Wellington.
        final c = ProviderContainer(
          overrides: environmentOverrides(
            now: DateTime.utc(2026, 9, 25, 23, 30),
            timeZone: TestTimeZones.wellington,
            features: {FeatureId.journal},
          ),
        );
        addTearDown(c.dispose);
        await c.read(naturalEnvironmentProvider.future);
        await c.read(journalProvider.future);
        expect(c.read(todayProvider), const CalendarDate(2026, 9, 26));
        expect(journalOf(c).openToday().date, const CalendarDate(2026, 9, 26));
      },
    );

    test('there is no way to write a past or future page: only openToday '
        'makes a draft', () {
      final source = File(
        'lib/features/journal/application/journal_providers.dart',
      ).readAsStringSync();
      // The one constructor is private to the library…
      expect(source, contains('const JournalDraft._('));
      expect(RegExp(r'JournalDraft\._\(').allMatches(source), hasLength(2));
      // …and the controller has no method taking a date to write on.
      expect(source, isNot(contains('saveOn(')));
      expect(source, isNot(contains('saveFor(')));
    });

    test('no DateTime.now anywhere in the Journal', () {
      for (final file in Directory(
        'lib/features/journal',
      ).listSync(recursive: true).whereType<File>()) {
        expect(
          file.readAsStringSync(),
          isNot(contains('DateTime.now')),
          reason: file.path,
        );
      }
    });

    test('midnight: a draft opened before midnight saves on its own day, '
        'with the snapshot taken when it was opened', () async {
      var now = DateTime.utc(2026, 9, 26, 22, 50); // 23:50 in London
      final store = InMemoryJournalStore();
      final c = await launch(store: store, clock: () => now);
      final draft = journalOf(c).openToday();
      expect(draft.date, const CalendarDate(2026, 9, 26));

      now = DateTime.utc(2026, 9, 26, 23, 10); // 00:10 on the 27th
      c.invalidate(naturalEnvironmentProvider);
      await c.read(naturalEnvironmentProvider.future);
      expect(c.read(todayProvider), const CalendarDate(2026, 9, 27));

      await journalOf(c).save(draft, 'Written across midnight');
      final entry = bookOf(c).entries.single;
      expect(entry.date, const CalendarDate(2026, 9, 26));
      expect(entry.context, draft.context);
      // And the new day is a fresh, blank page.
      final next = journalOf(c).openToday();
      expect(next.date, const CalendarDate(2026, 9, 27));
      expect(bookOf(c).find(next.date), isNull);
    });
  });

  group('the snapshot is what the day was, and never changes', () {
    Future<CalendarDate> festivalDay() async {
      final probe = ProviderContainer(
        overrides: environmentOverrides(
          now: londonNoon(9, 10),
          features: {FeatureId.wheel},
        ),
      );
      addTearDown(probe.dispose);
      await probe.read(naturalEnvironmentProvider.future);
      return probe.read(nextFestivalProvider).date;
    }

    test('records moon, season, a festival on the day and the Maramataka '
        'when on', () async {
      final day = await festivalDay();
      final c = await launch(
        store: InMemoryJournalStore(),
        now: DateTime.utc(day.year, day.month, day.day, 11),
        features: {FeatureId.journal, FeatureId.wheel},
        includeMaramataka: true,
      );
      final moon = c.read(currentMoonProvider);
      final festival = c.read(almanacFestivalProvider(null))!;
      expect(festival.state, FestivalTimingState.today);

      await journalOf(c).save(journalOf(c).openToday(), 'A festival day');
      final snapshot = bookOf(c).entries.single.context;
      expect(snapshot.moonPhase, moon.phase.label);
      expect(snapshot.illuminatedFraction, moon.illuminatedFraction);
      expect(snapshot.season, c.read(currentSeasonProvider).label);
      expect(snapshot.festivalId, festival.id.name);
      expect(snapshot.festivalName, festival.id.label);
      final night = Maramataka.nightForAge(moon.ageInDays);
      expect(snapshot.maramatakaId, night.id);
      expect(snapshot.maramatakaName, night.name);
      expect(snapshot.maramatakaReference, Maramataka.referenceId);
    });

    test('an approaching festival is not recorded', () async {
      final day = await festivalDay();
      final before = day.addDays(-2);
      final c = await launch(
        store: InMemoryJournalStore(),
        now: DateTime.utc(before.year, before.month, before.day, 11),
        features: {FeatureId.journal, FeatureId.wheel},
      );
      expect(
        c.read(almanacFestivalProvider(null))!.state,
        FestivalTimingState.approaching,
      );
      expect(c.read(journalContextProvider).festivalId, isNull);
      expect(c.read(journalContextProvider).festivalName, isNull);
    });

    test('with the Wheel off, not even the day itself is recorded', () async {
      final day = await festivalDay();
      final c = await launch(
        store: InMemoryJournalStore(),
        now: DateTime.utc(day.year, day.month, day.day, 11),
      );
      expect(c.read(journalContextProvider).festivalId, isNull);
    });

    test('with the Maramataka off, no night is recorded', () async {
      final c = await launch(
        store: InMemoryJournalStore(),
        now: londonNoon(9, 26),
      );
      await journalOf(c).save(journalOf(c).openToday(), 'Words');
      final snapshot = bookOf(c).entries.single.context;
      expect(snapshot.maramatakaId, isNull);
      expect(snapshot.maramatakaName, isNull);
      expect(snapshot.maramatakaReference, isNull);
    });

    test('an old page is unchanged by a new moon, the Wheel or the '
        'Maramataka changing — and editing it the same day keeps it', () async {
      final day = await festivalDay();
      var now = DateTime.utc(day.year, day.month, day.day, 8);
      final store = InMemoryJournalStore();
      final c = await launch(
        store: store,
        clock: () => now,
        features: {FeatureId.journal, FeatureId.wheel},
        includeMaramataka: true,
      );
      await journalOf(c).save(journalOf(c).openToday(), 'Morning');
      final original = bookOf(c).entries.single;

      // Later the same day: the Moon has moved on, the Maramataka and the
      // Wheel are switched off — and the page is edited.
      now = now.add(const Duration(hours: 12));
      c.invalidate(naturalEnvironmentProvider);
      await c.read(naturalEnvironmentProvider.future);
      await c.read(userSettingsProvider.notifier).setIncludeMaramataka(false);
      await c
          .read(userSettingsProvider.notifier)
          .setFeatureChosen(FeatureId.wheel, false);
      expect(
        c.read(currentMoonProvider).illuminatedFraction,
        isNot(original.context.illuminatedFraction),
      );
      await journalOf(c).save(journalOf(c).openToday(), 'Morning and night');
      expect(bookOf(c).entries.single.context, original.context);

      // Weeks later, with everything different: still the same page.
      final later = await launch(
        store: store,
        now: now.add(const Duration(days: 17)),
        features: {FeatureId.journal},
      );
      final reread = bookOf(later).entries.single;
      expect(reread.context, original.context);
      expect(reread.context.festivalName, isNotNull);
      expect(reread.context.maramatakaName, isNotNull);
      expect(reread.text, 'Morning and night');
    });
  });

  group('the book', () {
    final book = JournalBook([page(26), page(18), page(20)]);

    test('pages are in date order, one per date', () {
      expect(book.entries.map((e) => e.date.day), [18, 20, 26]);
      expect(book.putting(page(20, text: 'again')).entries, hasLength(3));
      expect(
        book
            .putting(page(20, text: 'again'))
            .find(const CalendarDate(2026, 9, 20))!
            .text,
        'again',
      );
    });

    test('previous and next step only between saved pages', () {
      const d = CalendarDate.new;
      expect(book.previousBefore(d(2026, 9, 26))!.date.day, 20);
      expect(book.previousBefore(d(2026, 9, 20))!.date.day, 18);
      expect(book.previousBefore(d(2026, 9, 18)), isNull);
      expect(book.previousBefore(d(2026, 9, 19))!.date.day, 18);
      expect(book.nextAfter(d(2026, 9, 18))!.date.day, 20);
      expect(book.nextAfter(d(2026, 9, 20))!.date.day, 26);
      expect(book.nextAfter(d(2026, 9, 26)), isNull);
    });

    test('contents group by month, newest first', () {
      final spread = JournalBook([
        page(18),
        page(20),
        page(26),
        page(3, month: 8),
      ]);
      final groups = spread.byMonth;
      expect(groups.map((g) => g.month), [
        const CalendarDate(2026, 9, 1),
        const CalendarDate(2026, 8, 1),
      ]);
      expect(groups.first.entries.map((e) => e.date.day), [26, 20, 18]);
    });

    test('an entry never prints its words', () {
      final entry = page(18, text: 'secret words');
      expect(entry.toString(), isNot(contains('secret')));
      expect(entry.context.toString(), isNot(contains('secret')));
    });
  });

  group('private', () {
    test(
      'a failed read logs the kind of failure, never the contents',
      () async {
        final logged = <String>[];
        final original = debugPrint;
        debugPrint = (message, {wrapWidth}) => logged.add(message ?? '');
        addTearDown(() => debugPrint = original);

        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              // The wrong type entirely: the read fails.
              'journal.entries': 'secret words',
            });
        final book = await SharedPreferencesJournalStore().read();
        expect(book.isEmpty, isTrue);
        expect(logged.join(), isNot(contains('secret')));
        expect(logged.single, startsWith('Journal could not be read'));
      },
    );

    test('no network, no logging of text, and no other feature reads the '
        'Journal', () {
      for (final file in Directory(
        'lib/features/journal',
      ).listSync(recursive: true).whereType<File>()) {
        final source = file.readAsStringSync();
        expect(source, isNot(contains('package:http')), reason: file.path);
        expect(source, isNot(contains('dart:io')), reason: file.path);
        expect(source, isNot(contains('print(')), reason: file.path);
      }
      // Only the composition root (which screen a tab opens) may import
      // the Journal.
      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => !f.path.startsWith('lib/features/journal'))) {
        final source = file.readAsStringSync();
        if (source.contains('features/journal/')) {
          expect(
            file.path,
            'lib/app/navigation/feature_screens.dart',
            reason: 'only the tab should know the Journal exists',
          );
        }
      }
    });
  });
}
