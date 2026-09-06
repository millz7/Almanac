import 'package:almanac/app/almanac_button.dart';
import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/app/navigation/immersion.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:almanac/features/yoga/domain/yoga_practices.dart';
import 'package:almanac/features/yoga/presentation/widgets/pose_figure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

void main() {
  setUpAll(useTimeZoneDatabase);

  final figure = find.byType(PoseFigure);
  final start = find.widgetWithText(ElevatedButton, 'Start');
  final beginAgain = find.widgetWithText(ElevatedButton, 'Begin again');
  final endPractice = find.widgetWithText(TextButton, 'End practice');

  Finder practice(String name) => find.widgetWithText(ChoiceCard, name);

  /// A tab in the navigation bar, by its accessibility label.
  ///
  /// Scoped to the bar deliberately: the Environment screen also links
  /// onward to the same features, so a bare label finder can match twice
  /// depending on how much of that screen the test surface shows.
  Finder navTab(String name) => find.descendant(
    of: find.byType(AlmanacNavigationBar),
    matching: find.bySemanticsLabel(name),
  );

  /// Opens Yoga through the real navigation, as a user with it in their
  /// Almanac would.
  Future<ProviderContainer> openYoga(
    WidgetTester tester, {
    double textScale = 1,
    bool reducedMotion = false,
    Size surface = const Size(420, 1600),
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
      overrides: environmentOverrides(features: const {FeatureId.yoga}),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(navTab('Yoga'));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> choose(WidgetTester tester, String name) async {
    await tester.ensureVisible(practice(name));
    await tester.pumpAndSettle();
    await tester.tap(practice(name));
    await tester.pumpAndSettle();
  }

  /// Presses Start and lets the ticker's first frame land, so the next
  /// pump advances the practice rather than starting it.
  Future<void> begin(WidgetTester tester) async {
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pump();
  }

  Future<void> stop(WidgetTester tester) async {
    await tester.ensureVisible(endPractice);
    await tester.pump();
    await tester.tap(endPractice);
    await tester.pumpAndSettle();
  }

  group('choosing a practice', () {
    testWidgets('all three are offered, with a line and a length', (
      tester,
    ) async {
      await openYoga(tester);

      expect(find.text('Choose a practice'), findsOneWidget);
      for (final option in YogaPractices.all) {
        expect(practice(option.name), findsOneWidget);
        expect(
          find.textContaining('${option.approximateMinutes} minutes'),
          findsWidgets,
        );
      }
      // No library, no search, no filters.
      expect(find.byType(TextField), findsNothing);
      expect(start, findsNothing);
    });

    testWidgets('choosing one shows what it is and how to begin', (
      tester,
    ) async {
      await openYoga(tester);
      await choose(tester, 'Ground');

      expect(find.text('Ground'), findsOneWidget);
      expect(find.text(YogaPractices.ground.description), findsOneWidget);
      expect(find.text('6 minutes, 8 movements'), findsOneWidget);
      expect(start, findsOneWidget);
      expect(figure, findsOneWidget);
      // The other doors have closed.
      for (final option in YogaPractices.all) {
        expect(practice(option.name), findsNothing);
      }
    });

    testWidgets('you can change your mind without leaving Yoga', (
      tester,
    ) async {
      await openYoga(tester);
      await choose(tester, 'Morning');
      expect(find.text('Morning'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(TextButton, 'Choose a different practice'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose a practice'), findsOneWidget);
      await choose(tester, 'Unwind');
      expect(find.text('Unwind'), findsOneWidget);
      // Still inside Yoga, with its navigation intact.
      expect(find.byType(AlmanacNavigationBar), findsOneWidget);
    });
  });

  group('starting', () {
    testWidgets('the practice takes the screen', (tester) async {
      final container = await openYoga(tester);
      await choose(tester, 'Morning');
      await begin(tester);

      // The first movement, straight away — no settling pause here.
      expect(find.text('Seated breathing'), findsOneWidget);
      expect(find.text('1 of 8'), findsOneWidget);
      expect(figure, findsOneWidget);

      // And everything else is gone.
      expect(find.text('Yoga'), findsNothing);
      expect(start, findsNothing);
      expect(find.byType(AlmanacButton), findsNothing);
      expect(find.byType(AlmanacNavigationBar), findsNothing);
      expect(container.read(immersiveModeProvider), isTrue);
    });

    testWidgets('shows the movement, what to do, the breath and the time', (
      tester,
    ) async {
      await openYoga(tester);
      await choose(tester, 'Morning');
      await begin(tester);

      final first = YogaPractices.morning.sequence.first;
      expect(find.text(first.pose), findsOneWidget);
      expect(find.text(first.instruction), findsOneWidget);
      expect(find.text('Breathe in'), findsOneWidget);
      expect(find.text('45s'), findsOneWidget);

      await stop(tester);
    });
  });

  group('moving through the sequence', () {
    testWidgets('each movement follows the last', (tester) async {
      await openYoga(tester);
      await choose(tester, 'Morning');
      await begin(tester);

      expect(find.text('Seated breathing'), findsOneWidget);
      expect(find.text('1 of 8'), findsOneWidget);

      await tester.pump(const Duration(seconds: 45));
      expect(find.text('Seated side stretch, left'), findsOneWidget);
      expect(find.text('2 of 8'), findsOneWidget);

      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Seated side stretch, right'), findsOneWidget);
      expect(find.text('3 of 8'), findsOneWidget);

      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Cat cow'), findsOneWidget);
      expect(find.text('4 of 8'), findsOneWidget);

      await stop(tester);
    });

    testWidgets('the time left counts down within a movement', (tester) async {
      await openYoga(tester);
      await choose(tester, 'Morning');
      await begin(tester);

      expect(find.text('45s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('35s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 20));
      expect(find.text('15s'), findsOneWidget);

      // And starts again with the next movement.
      await tester.pump(const Duration(seconds: 15));
      expect(find.text('30s'), findsOneWidget);

      await stop(tester);
    });

    testWidgets('the breath cue follows the rhythm on a flowing movement', (
      tester,
    ) async {
      await openYoga(tester);
      await choose(tester, 'Morning');
      await begin(tester);

      // Cat cow begins 105 seconds in and flows four and four.
      await tester.pump(const Duration(seconds: 105));
      expect(find.text('Cat cow'), findsOneWidget);
      expect(find.text('Breathe in and lengthen'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Breathe out and round'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Breathe in and lengthen'), findsOneWidget);

      await stop(tester);
    });

    testWidgets('a held movement shows its note instead of a count', (
      tester,
    ) async {
      await openYoga(tester);
      await choose(tester, 'Morning');
      await begin(tester);

      await tester.pump(const Duration(seconds: 46));
      expect(find.text('Slow and even.'), findsOneWidget);
      expect(find.text('Breathe in'), findsNothing);

      await stop(tester);
    });

    testWidgets('the figure follows the breath only where it flows', (
      tester,
    ) async {
      await openYoga(tester);
      await choose(tester, 'Morning');
      await begin(tester);

      // Cat cow: the figure is given the breath to follow.
      await tester.pump(const Duration(seconds: 106));
      final flowing = tester.widget<PoseFigure>(figure);
      expect(flowing.shape, PoseShape.allFours);
      expect(flowing.openness, isNotNull);

      await tester.pump(const Duration(seconds: 2));
      expect(
        tester.widget<PoseFigure>(figure).openness,
        greaterThan(flowing.openness!),
      );

      // A held pose has nothing to follow.
      await tester.pump(const Duration(seconds: 60));
      final held = tester.widget<PoseFigure>(figure);
      expect(held.shape, PoseShape.standing);
      expect(held.openness, isNull);

      await stop(tester);
    });

    testWidgets('the practice screen stays free of everything else', (
      tester,
    ) async {
      await openYoga(tester);
      await choose(tester, 'Morning');
      await begin(tester);
      await tester.pump(const Duration(seconds: 20));

      expect(find.byType(AlmanacNavigationBar), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // One way out, and it is the quietest thing on the screen.
      expect(find.byType(TextButton), findsOneWidget);

      await stop(tester);
    });
  });

  group('completing', () {
    Future<void> runToEnd(WidgetTester tester, String name) async {
      await choose(tester, name);
      await begin(tester);
      await tester.pump(
        YogaPractices.byId(
          YogaPractices.all.firstWhere((p) => p.name == name).id,
        ).length,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('says so calmly, and nothing else', (tester) async {
      final container = await openYoga(tester);
      await runToEnd(tester, 'Unwind');

      expect(find.text('Practice complete.'), findsOneWidget);
      expect(find.text('Unwind'), findsWidgets);
      // Nothing counted, nothing awarded.
      expect(find.textContaining('streak'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('calorie'), findsNothing);

      // The frame is back.
      expect(container.read(immersiveModeProvider), isFalse);
      expect(find.byType(AlmanacNavigationBar), findsOneWidget);
    });

    testWidgets('offers another go and another practice', (tester) async {
      await openYoga(tester);
      await runToEnd(tester, 'Unwind');

      expect(beginAgain, findsOneWidget);
      expect(
        find.widgetWithText(TextButton, 'Choose another practice'),
        findsOneWidget,
      );
    });

    testWidgets('does not end early', (tester) async {
      await openYoga(tester);
      await choose(tester, 'Unwind');
      await begin(tester);

      await tester.pump(
        YogaPractices.unwind.length - const Duration(seconds: 1),
      );
      expect(find.text('Practice complete.'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Practice complete.'), findsOneWidget);
    });

    testWidgets('beginning again runs the whole practice from the start', (
      tester,
    ) async {
      await openYoga(tester);
      await runToEnd(tester, 'Unwind');

      await tester.tap(beginAgain);
      await tester.pump();

      expect(find.text('1 of 8'), findsOneWidget);
      expect(find.text('Seated breathing'), findsOneWidget);
      expect(find.byType(AlmanacNavigationBar), findsNothing);

      await stop(tester);
    });

    testWidgets('another practice goes back to the three doors', (
      tester,
    ) async {
      await openYoga(tester);
      await runToEnd(tester, 'Unwind');

      await tester.tap(
        find.widgetWithText(TextButton, 'Choose another practice'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose a practice'), findsOneWidget);
      expect(practice('Morning'), findsOneWidget);
    });

    testWidgets('nothing is left running', (tester) async {
      await openYoga(tester);
      await runToEnd(tester, 'Unwind');

      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('stopping', () {
    testWidgets('returns to the setup with the practice still chosen', (
      tester,
    ) async {
      final container = await openYoga(tester);
      await choose(tester, 'Ground');
      await begin(tester);
      await tester.pump(const Duration(seconds: 40));

      await stop(tester);

      expect(find.text('Ground'), findsOneWidget);
      expect(start, findsOneWidget);
      expect(container.read(immersiveModeProvider), isFalse);
      expect(find.byType(AlmanacNavigationBar), findsOneWidget);
    });

    testWidgets('leaves nothing running', (tester) async {
      await openYoga(tester);
      await choose(tester, 'Ground');
      await begin(tester);
      await tester.pump(const Duration(seconds: 40));

      await stop(tester);

      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('starting again begins from the first movement', (
      tester,
    ) async {
      await openYoga(tester);
      await choose(tester, 'Morning');
      await begin(tester);
      await tester.pump(const Duration(seconds: 100));
      await stop(tester);

      await begin(tester);
      expect(find.text('1 of 8'), findsOneWidget);
      expect(find.text('45s'), findsOneWidget);

      await stop(tester);
    });
  });

  group('leaving the screen', () {
    testWidgets('backgrounding the app ends the practice', (tester) async {
      final container = await openYoga(tester);
      await choose(tester, 'Morning');
      await begin(tester);
      await tester.pump(const Duration(seconds: 30));

      // Out of sight and back again, walking the real Android sequence.
      // `inactive` alone — a notification shade — deliberately does not
      // end a practice.
      for (final state in [
        AppLifecycleState.resumed,
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(start, findsOneWidget);
      expect(container.read(immersiveModeProvider), isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('switching to another part of the Almanac ends it too', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 2800);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(
        overrides: environmentOverrides(
          features: const {FeatureId.yoga, FeatureId.garden},
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

      await tester.tap(navTab('Yoga'));
      await tester.pumpAndSettle();
      await choose(tester, 'Morning');
      await begin(tester);
      await tester.pump(const Duration(seconds: 30));

      // The navigation is hidden while practising, so leaving means
      // ending first — which is what the End practice control does.
      await stop(tester);
      await tester.tap(navTab('Garden'));
      await tester.pumpAndSettle();

      expect(container.read(immersiveModeProvider), isFalse);
      expect(tester.binding.transientCallbackCount, 0);

      await tester.tap(navTab('Yoga'));
      await tester.pumpAndSettle();
      expect(start, findsOneWidget);
    });
  });

  group('reduced motion', () {
    testWidgets('the practice still lasts its full length', (tester) async {
      // The trap this guards: an AnimationController shortens itself
      // twentyfold when animations are disabled, which would turn five
      // minutes into fifteen seconds.
      await openYoga(tester, reducedMotion: true);
      await choose(tester, 'Unwind');
      await begin(tester);

      await tester.pump(
        YogaPractices.unwind.length - const Duration(seconds: 1),
      );
      expect(find.text('Practice complete.'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Practice complete.'), findsOneWidget);
    });

    testWidgets('the figure holds still, and everything else still works', (
      tester,
    ) async {
      await openYoga(tester, reducedMotion: true);
      await choose(tester, 'Morning');
      await begin(tester);

      // Even on the flowing movement, the figure is given nothing to
      // follow.
      await tester.pump(const Duration(seconds: 106));
      expect(find.text('Cat cow'), findsOneWidget);
      expect(tester.widget<PoseFigure>(figure).openness, isNull);

      // But you can still tell where you are, what to do and how long
      // is left.
      expect(find.text('4 of 8'), findsOneWidget);
      expect(find.textContaining('hands and knees'), findsOneWidget);
      expect(find.textContaining('s'), findsWidgets);

      // And the movement still changes when its time is up.
      await tester.pump(const Duration(seconds: 60));
      expect(find.text('Mountain'), findsOneWidget);
      expect(find.text('5 of 8'), findsOneWidget);

      await stop(tester);
    });

    testWidgets('the breath cue still changes on a flowing movement', (
      tester,
    ) async {
      await openYoga(tester, reducedMotion: true);
      await choose(tester, 'Morning');
      await begin(tester);

      await tester.pump(const Duration(seconds: 105));
      expect(find.text('Breathe in and lengthen'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Breathe out and round'), findsOneWidget);

      await stop(tester);
    });
  });

  group('accessibility', () {
    testWidgets('the movement and instruction are announced together', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openYoga(tester);
      await choose(tester, 'Morning');
      await begin(tester);

      expect(
        find.bySemanticsLabel(
          YogaPractices.morning.momentAt(Duration.zero).spokenInstruction,
        ),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 45));
      expect(
        find.bySemanticsLabel(RegExp('Seated side stretch, left')),
        findsWidgets,
      );
      expect(
        find.bySemanticsLabel(RegExp('Reach your left arm overhead')),
        findsWidgets,
      );

      await stop(tester);
      handle.dispose();
    });

    testWidgets('the announcement changes once a movement, not once a frame', (
      tester,
    ) async {
      await openYoga(tester);
      await choose(tester, 'Morning');
      await begin(tester);

      var changes = 0;
      String? previous;
      // The first three movements: 45, 30, 30 seconds.
      for (var second = 0; second < 105; second++) {
        final names = [
          'Seated breathing',
          'Seated side stretch, left',
          'Seated side stretch, right',
        ];
        final current = names.firstWhere(
          (name) => find.text(name).evaluate().isNotEmpty,
          orElse: () => '',
        );
        if (current.isNotEmpty && current != previous) changes++;
        previous = current.isEmpty ? previous : current;
        await tester.pump(const Duration(seconds: 1));
      }

      expect(changes, 3);

      await stop(tester);
    });

    testWidgets('the drawn figure says nothing', (tester) async {
      await openYoga(tester);
      await choose(tester, 'Morning');

      // It is the same information as the words, drawn.
      expect(
        find.descendant(of: figure, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
    });

    testWidgets('every control is a comfortable target', (tester) async {
      await openYoga(tester);

      for (final option in YogaPractices.all) {
        expect(
          tester.getSize(practice(option.name)).height,
          greaterThanOrEqualTo(48),
        );
      }

      await choose(tester, 'Morning');
      expect(tester.getSize(start).height, greaterThanOrEqualTo(48));

      await begin(tester);
      expect(tester.getSize(endPractice).height, greaterThanOrEqualTo(48));

      await stop(tester);
    });

    testWidgets('doubling the text size breaks nothing', (tester) async {
      await openYoga(tester, textScale: 2);

      expect(tester.takeException(), isNull);
      for (final option in YogaPractices.all) {
        expect(practice(option.name), findsOneWidget);
      }

      await choose(tester, 'Morning');
      expect(tester.takeException(), isNull);

      await begin(tester);
      await tester.pump(const Duration(seconds: 46));

      expect(tester.takeException(), isNull);
      expect(find.text('Seated side stretch, left'), findsOneWidget);
      expect(find.text('2 of 8'), findsOneWidget);

      await stop(tester);
    });
  });
}
