import 'dart:io';

import 'package:almanac/app/app.dart';
import 'package:almanac/app/context/cycle_phase_context.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/core/context/almanac_context.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/moon_service.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/features/cookbook/domain/cycle_recipes.dart';
import 'package:almanac/features/cookbook/presentation/cookbook_text.dart';
import 'package:almanac/features/cycle/application/cycle_providers.dart';
import 'package:almanac/features/meditation/domain/cycle_meditation.dart';
import 'package:almanac/features/meditation/domain/moon_meditation.dart';
import 'package:almanac/features/meditation/presentation/meditation_text.dart';
import 'package:almanac/features/yoga/domain/cycle_yoga.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// A store that keeps a count of every time it is touched.
///
/// The point of the tests below is not "the phase came back null" — that
/// could be true while the store was opened and its answer thrown away.
/// It is that the store is **never asked**, which only a counting store
/// can show.
class _CountingCycleStore implements CycleStore {
  _CountingCycleStore([CycleData? data]) : _data = data ?? CycleData.empty;

  CycleData _data;

  int reads = 0;
  int writes = 0;
  int deletions = 0;

  /// Whether anything at all has been asked of the store.
  int get touches => reads + writes + deletions;

  @override
  Future<CycleData> read() async {
    reads++;
    return _data;
  }

  @override
  Future<void> write(CycleData data) async {
    writes++;
    _data = data;
  }

  @override
  Future<void> deleteAll() async {
    deletions++;
    _data = CycleData.empty;
  }
}

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

final testNow = DateTime.utc(2026, 9, 20, 12);
const sep4 = CalendarDate(2026, 9, 4);

/// Day 1 on 4 September, so 20 September is cycle day 17 — luteal.
const luteal = CyclePhase.luteal;

CycleData recorded() => CycleData(
  records: [
    const CycleDayRecord(
      date: sep4,
      level: BleedingLevel.bleeding,
      isPeriodStart: true,
    ),
  ],
);

void main() {
  setUpAll(useTimeZoneDatabase);

  Finder navTab(String name) => find.descendant(
    of: find.byType(AlmanacNavigationBar),
    matching: find.bySemanticsLabel(name),
  );

  /// Opens the app with [features] chosen and a counting Cycle store
  /// holding a recorded day 1.
  Future<(ProviderContainer, _CountingCycleStore)> open(
    WidgetTester tester, {
    required Set<FeatureId> features,
  }) async {
    tester.view.physicalSize = const Size(430, 3600) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final store = _CountingCycleStore(recorded());
    final container = ProviderContainer(
      overrides: [
        ...environmentOverrides(
          now: testNow,
          features: features,
          cycleStore: store,
        ),
        moonServiceProvider.overrideWithValue(
          const _FixedMoonService(_waxingCrescent),
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
    return (container, store);
  }

  Future<void> press(WidgetTester tester, Finder control) async {
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  Future<void> setFeatures(
    WidgetTester tester,
    ProviderContainer container,
    Set<FeatureId> features,
  ) async {
    await container.read(userSettingsProvider.notifier).setFeatures(features);
    await tester.pumpAndSettle();
  }

  Finder cycleCollection() => find.text(CookbookText.forYourCycle);
  Finder cycleNote() => find.text(CycleRecipes.collectionNote(luteal));
  Finder yogaSuggestion() => find.text(CycleYoga.forPhase(luteal).invitation);
  Finder meditationSuggestion() =>
      find.text(CycleMeditations.forPhase(luteal).invitation);

  group('with Cycle switched off, its store is never opened', () {
    testWidgets('the Cookbook does not read it', (tester) async {
      final (_, store) = await open(tester, features: {FeatureId.cookbook});
      await press(tester, navTab('Cookbook'));

      expect(store.reads, 0);
      expect(store.touches, 0);
      expect(cycleCollection(), findsNothing);
      expect(cycleNote(), findsNothing);
      // The Cookbook itself is entirely unaffected.
      expect(find.text(CookbookText.introduction), findsOneWidget);
    });

    testWidgets('Yoga does not read it', (tester) async {
      final (_, store) = await open(tester, features: {FeatureId.yoga});
      await press(tester, navTab('Yoga'));

      expect(store.reads, 0);
      expect(store.touches, 0);
      expect(yogaSuggestion(), findsNothing);
      expect(find.text('For today'), findsNothing);
    });

    testWidgets('and Meditation does not, though the Moon still speaks', (
      tester,
    ) async {
      final (_, store) = await open(tester, features: {FeatureId.meditation});
      await press(tester, navTab('Meditation'));

      expect(store.reads, 0);
      expect(store.touches, 0);
      expect(meditationSuggestion(), findsNothing);
      expect(find.text(luteal.phrase), findsNothing);

      // The Moon is not an optional feature and is not affected by any
      // of this: Meditation still has something to say about tonight.
      expect(find.text(MeditationText.forToday), findsOneWidget);
      expect(
        find.text(
          MoonMeditations.forPhase(MoonPhase.waxingCrescent).invitation,
        ),
        findsOneWidget,
      );
    });

    testWidgets('and no phase is derived anywhere', (tester) async {
      final (container, store) = await open(
        tester,
        features: {FeatureId.cookbook, FeatureId.yoga, FeatureId.meditation},
      );

      for (final tab in ['Cookbook', 'Yoga', 'Meditation']) {
        await press(tester, navTab(tab));
      }

      expect(container.read(almanacCyclePhaseProvider(null)), isNull);
      // Even a phase carried in from a doorway is gone with the feature.
      expect(container.read(almanacCyclePhaseProvider(luteal)), isNull);
      expect(store.touches, 0);
    });
  });

  group('switching Cycle back on wakes the same data', () {
    testWidgets('the Cookbook collection appears, and only then is the '
        'store read', (tester) async {
      final (container, store) = await open(
        tester,
        features: {FeatureId.cookbook},
      );
      await press(tester, navTab('Cookbook'));
      expect(store.reads, 0);

      await setFeatures(tester, container, {
        FeatureId.cookbook,
        FeatureId.cycle,
      });

      expect(store.reads, greaterThan(0));
      expect(cycleCollection(), findsOneWidget);
      expect(cycleNote(), findsOneWidget);
      // Nothing was written or deleted to make that happen.
      expect(store.writes, 0);
      expect(store.deletions, 0);
    });

    testWidgets('Yoga offers its practice again', (tester) async {
      final (container, store) = await open(tester, features: {FeatureId.yoga});
      await press(tester, navTab('Yoga'));
      expect(store.reads, 0);

      await setFeatures(tester, container, {FeatureId.yoga, FeatureId.cycle});

      expect(store.reads, greaterThan(0));
      expect(yogaSuggestion(), findsOneWidget);
    });

    testWidgets('and Meditation holds the Moon and the cycle side by side', (
      tester,
    ) async {
      final (container, store) = await open(
        tester,
        features: {FeatureId.meditation},
      );
      await press(tester, navTab('Meditation'));
      expect(store.reads, 0);

      await setFeatures(tester, container, {
        FeatureId.meditation,
        FeatureId.cycle,
      });

      expect(store.reads, greaterThan(0));
      expect(meditationSuggestion(), findsOneWidget);
      expect(
        find.text(
          MoonMeditations.forPhase(MoonPhase.waxingCrescent).invitation,
        ),
        findsOneWidget,
      );
    });
  });

  group('switching Cycle off again makes it dormant, not deleted', () {
    testWidgets('the collection goes, the store stops being read, and the '
        'data survives', (tester) async {
      final (container, store) = await open(
        tester,
        features: {FeatureId.cookbook, FeatureId.cycle},
      );
      await press(tester, navTab('Cookbook'));
      expect(cycleCollection(), findsOneWidget);
      expect(store.reads, greaterThan(0));

      await setFeatures(tester, container, {FeatureId.cookbook});
      expect(cycleCollection(), findsNothing);

      // Rebuilding the Cookbook — leaving it and coming back, and
      // browsing a season while there — does not reopen the store.
      final readsWhenDisabled = store.reads;
      await press(tester, navTab('Environment'));
      await press(tester, navTab('Cookbook'));
      expect(cycleCollection(), findsNothing);
      expect(store.reads, readsWhenDisabled);
      expect(store.writes, 0);
      expect(store.deletions, 0);

      // The record is still on disk, untouched. Hiding a feature is not
      // deleting its data; only the user can do that.
      expect(store.reads, readsWhenDisabled);
      final onDisk = await store.read();
      expect(onDisk.periodStarts, contains(sep4));

      // And turning it back on makes it usable again.
      await setFeatures(tester, container, {
        FeatureId.cookbook,
        FeatureId.cycle,
      });
      expect(cycleCollection(), findsOneWidget);
      expect(cycleNote(), findsOneWidget);
      expect(container.read(almanacCyclePhaseProvider(null)), luteal);
      expect(store.deletions, 0);
    });

    testWidgets('Yoga and Meditation fall quiet the same way', (tester) async {
      final (container, store) = await open(
        tester,
        features: {FeatureId.yoga, FeatureId.meditation, FeatureId.cycle},
      );

      await press(tester, navTab('Yoga'));
      expect(yogaSuggestion(), findsOneWidget);
      await press(tester, navTab('Meditation'));
      expect(meditationSuggestion(), findsOneWidget);

      await setFeatures(tester, container, {
        FeatureId.yoga,
        FeatureId.meditation,
      });

      expect(meditationSuggestion(), findsNothing);
      // The Moon is untouched by Cycle's absence.
      expect(
        find.text(
          MoonMeditations.forPhase(MoonPhase.waxingCrescent).invitation,
        ),
        findsOneWidget,
      );

      final readsWhenDisabled = store.reads;
      await press(tester, navTab('Yoga'));
      expect(yogaSuggestion(), findsNothing);
      await press(tester, navTab('Meditation'));
      expect(meditationSuggestion(), findsNothing);
      expect(store.reads, readsWhenDisabled);
      expect(store.deletions, 0);
    });
  });
  group('the gate is in one place, and the features know nothing of it', () {
    Iterable<File> sourcesOf(String feature) =>
        Directory('lib/features/$feature')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'));

    test('no consuming feature touches Cycle or asks about it', () {
      // The features consume a `CyclePhase?` and nothing else. If one of
      // them ever asked `featureAvailableProvider(FeatureId.cycle)` for
      // itself, the rule would live in four places and could differ in
      // any one of them.
      const forbidden = [
        'CycleStore',
        'cycleStoreProvider',
        'cycleDataProvider',
        'cycleMomentProvider',
        'displayedCyclePhaseProvider',
        'FeatureId.cycle',
        'features/cycle',
      ];

      for (final feature in ['cookbook', 'yoga', 'meditation']) {
        for (final file in sourcesOf(feature)) {
          final code = file.readAsStringSync();
          for (final name in forbidden) {
            expect(
              code.contains(name),
              isFalse,
              reason: '${file.path} names $name',
            );
          }
        }
      }
    });

    test('and only the app seam derives a phase from the store', () {
      final elsewhere = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !file.path.startsWith('lib/features/cycle/'))
          .where(
            (file) =>
                file.readAsStringSync().contains('displayedCyclePhaseProvider'),
          )
          .map((file) => file.path);

      expect(elsewhere, ['lib/app/context/cycle_phase_context.dart']);
    });

    test('and it checks availability before it reads anything', () {
      // Comments stripped: the doc comment explains the gate before the
      // code performs it, and it is the code that is under test.
      final code = File('lib/app/context/cycle_phase_context.dart')
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');

      final gate = code.indexOf('featureAvailableProvider(FeatureId.cycle)');
      final read = code.indexOf('displayedCyclePhaseProvider');
      expect(gate, isNot(-1));
      expect(read, isNot(-1));
      // Not "read it and discard the answer": the guard comes first, and
      // the store is never opened at all.
      expect(gate, lessThan(read));
    });
  });
}
