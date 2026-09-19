import 'dart:io';

import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/core/context/almanac_context.dart';
import 'package:almanac/features/meditation/domain/festival_meditation.dart';
import 'package:almanac/features/meditation/domain/meditation_technique.dart';
import 'package:almanac/features/meditation/presentation/meditation_text.dart';
import 'package:almanac/features/wheel/domain/festival.dart';
import 'package:almanac/features/yoga/domain/festival_yoga.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// Beltane is a fixed 1 May in the Northern Hemisphere, whatever year —
/// see `FestivalCalendar`'s documented v1 convention — so these dates
/// need no astronomical lookup of their own to reason about.
final _fourDaysBefore = DateTime.utc(2026, 4, 27, 12);
final _theDayItself = DateTime.utc(2026, 5, 1, 12);
final _wellBefore = DateTime.utc(2026, 3, 1, 12);
final _beltane = WheelOfYear.byId(FestivalId.beltane);

void main() {
  setUpAll(useTimeZoneDatabase);

  Finder navTab(String name) => find.descendant(
    of: find.byType(AlmanacNavigationBar),
    matching: find.bySemanticsLabel(name),
  );

  Future<ProviderContainer> open(
    WidgetTester tester, {
    required Set<FeatureId> features,
    required DateTime now,
  }) async {
    tester.view.physicalSize = const Size(430, 3600) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: environmentOverrides(now: now, features: features),
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

  Future<void> press(WidgetTester tester, Finder control) async {
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  group('Wheel switched off: no festival context anywhere, however close '
      'Beltane is', () {
    testWidgets('Environment has no festival line', (tester) async {
      await open(tester, features: const {}, now: _fourDaysBefore);
      expect(find.textContaining('Beltane'), findsNothing);
    });

    testWidgets('Cookbook has no festival collection', (tester) async {
      await open(tester, features: {FeatureId.cookbook}, now: _fourDaysBefore);
      await press(tester, navTab('Cookbook'));
      expect(find.textContaining('Beltane'), findsNothing);
      expect(find.text(_beltane.food.meal), findsNothing);
    });

    testWidgets('Meditation has no festival suggestion', (tester) async {
      await open(
        tester,
        features: {FeatureId.meditation},
        now: _fourDaysBefore,
      );
      await press(tester, navTab('Meditation'));
      expect(
        find.text(
          FestivalMeditations.forFestival(FestivalId.beltane).invitation,
        ),
        findsNothing,
      );
    });

    testWidgets('Yoga has no festival suggestion', (tester) async {
      await open(tester, features: {FeatureId.yoga}, now: _fourDaysBefore);
      await press(tester, navTab('Yoga'));
      expect(
        find.text(FestivalYoga.forFestival(FestivalId.beltane).invitation),
        findsNothing,
      );
    });
  });

  group('Wheel on, but nothing is close: still nothing extra anywhere', () {
    testWidgets('a month and a half out is not "approaching"', (tester) async {
      await open(
        tester,
        features: {
          FeatureId.wheel,
          FeatureId.cookbook,
          FeatureId.meditation,
          FeatureId.yoga,
        },
        now: _wellBefore,
      );

      expect(find.textContaining('Beltane'), findsNothing);
      await press(tester, navTab('Cookbook'));
      expect(find.textContaining('Beltane'), findsNothing);
      await press(tester, navTab('Meditation'));
      expect(
        find.text(
          FestivalMeditations.forFestival(FestivalId.beltane).invitation,
        ),
        findsNothing,
      );
      await press(tester, navTab('Yoga'));
      expect(
        find.text(FestivalYoga.forFestival(FestivalId.beltane).invitation),
        findsNothing,
      );
    });
  });

  group('Wheel on and Beltane is approaching (4 days out)', () {
    testWidgets("Environment's TODAY adds a quiet line and a doorway", (
      tester,
    ) async {
      await open(tester, features: {FeatureId.wheel}, now: _fourDaysBefore);

      expect(
        find.textContaining('Beltane is approaching · 4 days'),
        findsOneWidget,
      );
      expect(find.text('See Beltane'), findsOneWidget);
      // Never a replacement for the existing light description or the
      // season countdown; both remain.
      expect(find.textContaining('arrives in'), findsWidgets);
    });

    testWidgets('Cookbook offers suggestion ideas, honestly labelled', (
      tester,
    ) async {
      await open(
        tester,
        features: {FeatureId.wheel, FeatureId.cookbook},
        now: _fourDaysBefore,
      );
      await press(tester, navTab('Cookbook'));

      expect(find.textContaining('Beltane is approaching'), findsOneWidget);
      expect(find.text(_beltane.food.meal), findsOneWidget);
      expect(find.text(_beltane.food.treat), findsOneWidget);
      expect(find.text(_beltane.food.drink), findsOneWidget);
      expect(
        find.textContaining('not full recipes'),
        findsOneWidget,
        reason: 'the suggestions must not be presented as complete recipes',
      );
    });

    testWidgets('Meditation offers one of the four existing practices', (
      tester,
    ) async {
      await open(
        tester,
        features: {FeatureId.wheel, FeatureId.meditation},
        now: _fourDaysBefore,
      );
      await press(tester, navTab('Meditation'));

      final suggestion = FestivalMeditations.forFestival(FestivalId.beltane);
      expect(find.text(suggestion.invitation), findsOneWidget);
      // The technique's name also appears in the chooser below, so this
      // only proves it is a real, existing practice — not that it is
      // unique to the card.
      expect(
        find.text(MeditationTechniques.byId(suggestion.technique).name),
        findsWidgets,
      );
    });

    testWidgets('Yoga offers one of the three existing practices', (
      tester,
    ) async {
      await open(
        tester,
        features: {FeatureId.wheel, FeatureId.yoga},
        now: _fourDaysBefore,
      );
      await press(tester, navTab('Yoga'));

      final suggestion = FestivalYoga.forFestival(FestivalId.beltane);
      expect(find.text(suggestion.invitation), findsOneWidget);
    });
  });

  group('Wheel on and today is Beltane', () {
    testWidgets('Environment says so plainly', (tester) async {
      await open(tester, features: {FeatureId.wheel}, now: _theDayItself);

      expect(find.text('Today is Beltane'), findsOneWidget);
    });

    testWidgets('Cookbook heads its suggestions the same way', (tester) async {
      await open(
        tester,
        features: {FeatureId.wheel, FeatureId.cookbook},
        now: _theDayItself,
      );
      await press(tester, navTab('Cookbook'));

      expect(find.text('Today is Beltane'), findsOneWidget);
    });
  });

  group('context independence in Meditation', () {
    testWidgets('Moon, Cycle and Festival each render as their own suggestion, '
        'never merged into one claim', (tester) async {
      await open(
        tester,
        features: {FeatureId.meditation, FeatureId.cycle, FeatureId.wheel},
        now: _fourDaysBefore,
      );
      await press(tester, navTab('Meditation'));

      // "For today" is said once, not once per context.
      expect(find.text(MeditationText.forToday), findsOneWidget);

      // The festival's own suggestion is present as its own block.
      final festivalSuggestion = FestivalMeditations.forFestival(
        FestivalId.beltane,
      );
      expect(find.text(festivalSuggestion.invitation), findsOneWidget);

      // Every practice named on the card is one of the four that
      // already exist — nothing invented, nothing combined.
      for (final label in ['Focus', 'Sleep', 'Balance', 'Release Tension']) {
        expect(
          find.text(label),
          findsWidgets,
          reason: '$label should still be a real, chooseable practice',
        );
      }

      // No sentence stitches a moon phase and a festival together.
      expect(find.textContaining('Beltane waning'), findsNothing);
      expect(find.textContaining('Beltane new moon'), findsNothing);
    });
  });

  group('the gate is checked before anything is calculated', () {
    test('almanacFestivalProvider checks availability first', () {
      final code = File('lib/app/context/festival_context.dart')
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');

      final gate = code.indexOf('featureAvailableProvider(FeatureId.wheel)');
      final read = code.indexOf('festivalTimingStateProvider');
      expect(gate, isNot(-1));
      expect(read, isNot(-1));
      expect(gate, lessThan(read));
    });
  });
}
