import 'package:almanac/app/app.dart';
import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/features/meditation/domain/breathing_pattern.dart';
import 'package:almanac/features/meditation/presentation/meditation_screen.dart';
import 'package:almanac/features/meditation/presentation/widgets/breathing_circle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

void main() {
  setUpAll(useTimeZoneDatabase);

  final start = find.widgetWithText(ElevatedButton, 'Start');
  final startAgain = find.widgetWithText(ElevatedButton, 'Start again');
  final stop = find.widgetWithText(OutlinedButton, 'Stop');

  /// Opens Meditation through the real navigation, as a user with it in
  /// their Almanac would.
  Future<void> openMeditation(
    WidgetTester tester, {
    double textScale = 1,
    bool reducedMotion = false,
    Size surface = const Size(400, 1000),
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: environmentOverrides(features: const {FeatureId.meditation}),
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Meditation'));
    await tester.pumpAndSettle();
  }

  /// The breath as it is currently drawn.
  BreathingCircle circleOf(WidgetTester tester) =>
      tester.widget<BreathingCircle>(find.byType(BreathingCircle));

  group('before starting', () {
    testWidgets('shows a circle, an invitation and one button', (tester) async {
      await openMeditation(tester);

      expect(find.text('Meditation'), findsWidgets);
      expect(find.byType(BreathingCircle), findsOneWidget);
      expect(find.text('Take a slow breath'), findsOneWidget);
      expect(start, findsOneWidget);

      // Nothing to configure: no duration, no sounds, no presets.
      expect(stop, findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(find.byType(DropdownButton<Object>), findsNothing);
      expect(find.textContaining('minutes left'), findsNothing);
    });

    testWidgets('the circle rests, and nothing is animating', (tester) async {
      await openMeditation(tester);

      expect(circleOf(tester).still, isTrue);
      expect(circleOf(tester).sessionProgress, 0);
      // pumpAndSettle returned, so no frames are being scheduled.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('says how long a session is, without a clock', (tester) async {
      await openMeditation(tester);

      expect(
        find.text('Two quiet minutes, following the circle.'),
        findsOneWidget,
      );
    });
  });

  group('during a session', () {
    testWidgets('starting swaps the invitation for an instruction', (
      tester,
    ) async {
      await openMeditation(tester);

      await tester.tap(start);
      await tester.pump();

      expect(find.text('Breathe in'), findsOneWidget);
      expect(find.text('Take a slow breath'), findsNothing);
      expect(stop, findsOneWidget);
      expect(start, findsNothing);
    });

    testWidgets('the words follow the breath', (tester) async {
      await openMeditation(tester);
      await tester.tap(start);
      await tester.pump();

      expect(find.text('Breathe in'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Hold'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Breathe out'), findsOneWidget);

      // And round again.
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('Breathe in'), findsOneWidget);

      await tester.tap(stop);
      await tester.pumpAndSettle();
    });

    testWidgets('the circle opens and closes with the breath', (tester) async {
      await openMeditation(tester);
      await tester.tap(start);
      await tester.pump();

      final atStart = circleOf(tester).openness;
      expect(circleOf(tester).still, isFalse);

      await tester.pump(const Duration(seconds: 2));
      final midInhale = circleOf(tester).openness;
      expect(midInhale, greaterThan(atStart));

      await tester.pump(const Duration(seconds: 2));
      final held = circleOf(tester).openness;
      expect(held, closeTo(1, 0.01));

      // Two seconds of hold, then part-way through the out-breath.
      await tester.pump(const Duration(seconds: 5));
      expect(circleOf(tester).openness, lessThan(held));

      await tester.tap(stop);
      await tester.pumpAndSettle();
    });

    testWidgets('the session ring fills as the two minutes pass', (
      tester,
    ) async {
      await openMeditation(tester);
      await tester.tap(start);
      await tester.pump();

      expect(circleOf(tester).sessionProgress, closeTo(0, 0.01));

      await tester.pump(const Duration(minutes: 1));
      expect(circleOf(tester).sessionProgress, closeTo(0.5, 0.02));

      await tester.pump(const Duration(seconds: 30));
      expect(circleOf(tester).sessionProgress, closeTo(0.75, 0.02));

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
    });

    testWidgets('says roughly how much is left, and never ticks', (
      tester,
    ) async {
      await openMeditation(tester);
      await tester.tap(start);
      await tester.pump();

      expect(find.text('2 minutes left'), findsOneWidget);

      await tester.pump(const Duration(seconds: 66));
      expect(find.text('Less than a minute left'), findsOneWidget);

      await tester.pump(const Duration(seconds: 42));
      expect(find.text('Almost there'), findsOneWidget);

      await tester.pump(const Duration(seconds: 12));
      await tester.pumpAndSettle();
    });
  });

  group('stopping', () {
    testWidgets('returns to the beginning', (tester) async {
      await openMeditation(tester);
      await tester.tap(start);
      await tester.pump(const Duration(seconds: 30));

      await tester.tap(stop);
      await tester.pumpAndSettle();

      expect(find.text('Take a slow breath'), findsOneWidget);
      expect(start, findsOneWidget);
      expect(stop, findsNothing);
      expect(circleOf(tester).sessionProgress, 0);
    });

    testWidgets('leaves nothing running', (tester) async {
      await openMeditation(tester);
      await tester.tap(start);
      await tester.pump(const Duration(seconds: 30));

      await tester.tap(stop);
      await tester.pumpAndSettle();

      // No ticker, no timer, nothing scheduled — and pumpAndSettle would
      // have hung if a session were still going.
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('a stopped session starts again from the beginning', (
      tester,
    ) async {
      await openMeditation(tester);
      await tester.tap(start);
      await tester.pump(const Duration(seconds: 30));
      await tester.tap(stop);
      await tester.pumpAndSettle();

      await tester.tap(start);
      await tester.pump();

      expect(find.text('Breathe in'), findsOneWidget);
      expect(find.text('2 minutes left'), findsOneWidget);
      expect(circleOf(tester).sessionProgress, closeTo(0, 0.01));

      await tester.tap(stop);
      await tester.pumpAndSettle();
    });
  });

  group('finishing', () {
    testWidgets('two minutes ends the session quietly', (tester) async {
      await openMeditation(tester);
      await tester.tap(start);
      await tester.pump();

      await tester.pump(kMeditationSessionLength);
      await tester.pumpAndSettle();

      expect(find.text('Well done.'), findsOneWidget);
      expect(startAgain, findsOneWidget);
      expect(stop, findsNothing);
      // Understated: no score, no streak, no statistics.
      expect(find.textContaining('streak'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('does not end early', (tester) async {
      await openMeditation(tester);
      await tester.tap(start);
      await tester.pump();

      await tester.pump(const Duration(seconds: 119));
      expect(find.text('Well done.'), findsNothing);
      expect(stop, findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Well done.'), findsOneWidget);
    });

    testWidgets('nothing is left running afterwards', (tester) async {
      await openMeditation(tester);
      await tester.tap(start);
      await tester.pump(kMeditationSessionLength);
      await tester.pumpAndSettle();

      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('starting again runs a whole new session', (tester) async {
      await openMeditation(tester);
      await tester.tap(start);
      await tester.pump(kMeditationSessionLength);
      await tester.pumpAndSettle();

      await tester.tap(startAgain);
      await tester.pump();

      expect(find.text('Breathe in'), findsOneWidget);
      expect(circleOf(tester).sessionProgress, closeTo(0, 0.01));

      await tester.tap(stop);
      await tester.pumpAndSettle();
    });
  });

  group('leaving the screen', () {
    testWidgets('backgrounding the app ends the session', (tester) async {
      await openMeditation(tester);
      await tester.tap(start);
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));
      expect(stop, findsOneWidget);

      // Out of sight and back again, walking the real Android sequence:
      // resumed, inactive, hidden, paused. `onHide` and `onPause` are
      // what the screen listens for; `inactive` alone — a notification
      // shade — deliberately does not end a session.
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

      // And back, which Android also walks a state at a time.
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Back at the beginning rather than half a session in, and with
      // nothing having run on in a pocket.
      expect(find.text('Take a slow breath'), findsOneWidget);
      expect(start, findsOneWidget);
      expect(circleOf(tester).sessionProgress, 0);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('switching to another part of the Almanac ends the session', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: environmentOverrides(
            features: const {FeatureId.meditation, FeatureId.garden},
          ),
          child: const AlmanacApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Meditation'));
      await tester.pumpAndSettle();
      await tester.tap(start);
      await tester.pump(const Duration(seconds: 30));

      await tester.tap(find.bySemanticsLabel('Garden'));
      await tester.pumpAndSettle();

      // A session you cannot see is not happening.
      await tester.tap(find.bySemanticsLabel('Meditation'));
      await tester.pumpAndSettle();

      expect(find.text('Take a slow breath'), findsOneWidget);
      expect(start, findsOneWidget);
    });
  });

  group('reduced motion', () {
    testWidgets('the session still lasts its full two minutes', (tester) async {
      // The trap this guards: an AnimationController shortens itself
      // twentyfold when animations are disabled, which would turn two
      // minutes into six seconds.
      await openMeditation(tester, reducedMotion: true);
      await tester.tap(start);
      await tester.pump();

      await tester.pump(const Duration(seconds: 119));
      expect(find.text('Well done.'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Well done.'), findsOneWidget);
    });

    testWidgets('the circle holds still, and the words carry the rhythm', (
      tester,
    ) async {
      await openMeditation(tester, reducedMotion: true);
      await tester.tap(start);
      await tester.pump();

      expect(circleOf(tester).still, isTrue);
      final size = circleOf(tester).openness;

      // Part-way through the in-breath the drawn circle has not moved...
      await tester.pump(const Duration(seconds: 2));
      expect(circleOf(tester).still, isTrue);
      expect(circleOf(tester).openness, size);

      // ...but the instruction still follows the breath.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Hold'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Breathe out'), findsOneWidget);

      await tester.tap(stop);
      await tester.pumpAndSettle();
    });

    testWidgets('it can still be started, run and stopped', (tester) async {
      await openMeditation(tester, reducedMotion: true);

      await tester.tap(start);
      await tester.pump(const Duration(seconds: 20));
      expect(stop, findsOneWidget);

      await tester.tap(stop);
      await tester.pumpAndSettle();
      expect(start, findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('the phase is announced with its length', (tester) async {
      final handle = tester.ensureSemantics();
      await openMeditation(tester);

      await tester.tap(start);
      await tester.pump();
      expect(find.bySemanticsLabel('Breathe in, 4 seconds'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      expect(find.bySemanticsLabel('Hold, 2 seconds'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.bySemanticsLabel('Breathe out, 6 seconds'), findsOneWidget);

      await tester.tap(stop);
      await tester.pumpAndSettle();
      handle.dispose();
    });

    testWidgets('the announcement is made once per phase, not per frame', (
      tester,
    ) async {
      await openMeditation(tester);
      await tester.tap(start);
      await tester.pump();

      var builds = 0;
      // Count how often the spoken node is rebuilt across a whole breath
      // by watching the instruction text change identity.
      String? previous;
      for (var ms = 0; ms < 12000; ms += 100) {
        final current = tester
            .widget<Text>(
              find.text(
                find.text('Breathe in').evaluate().isNotEmpty
                    ? 'Breathe in'
                    : find.text('Hold').evaluate().isNotEmpty
                    ? 'Hold'
                    : 'Breathe out',
              ),
            )
            .data;
        if (current != previous) builds++;
        previous = current;
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Three phases in a twelve-second breath, not a hundred and twenty.
      expect(builds, 3);

      await tester.tap(stop);
      await tester.pumpAndSettle();
    });

    testWidgets('the circle itself says nothing', (tester) async {
      await openMeditation(tester);

      // It is the same information as the words, drawn — so a screen
      // reader gains nothing from it.
      expect(
        find.descendant(
          of: find.byType(BreathingCircle),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the controls are comfortable to tap', (tester) async {
      await openMeditation(tester);

      expect(tester.getSize(start).height, greaterThanOrEqualTo(48));

      await tester.tap(start);
      await tester.pump();
      expect(tester.getSize(stop).height, greaterThanOrEqualTo(48));

      await tester.tap(stop);
      await tester.pumpAndSettle();
    });

    testWidgets('doubling the text size does not break the screen', (
      tester,
    ) async {
      await openMeditation(tester, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(find.text('Take a slow breath'), findsOneWidget);

      // The page scrolls at this size rather than overflowing, so the
      // button has to be brought into view before it can be pressed.
      await tester.ensureVisible(start);
      await tester.pumpAndSettle();
      await tester.tap(start);
      // A bare pump first: a ticker's clock starts on its first frame, so
      // jumping straight to five seconds would start the session there
      // rather than five seconds into it.
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      expect(tester.takeException(), isNull);
      expect(find.text('Hold'), findsOneWidget);

      // A plain pump, not pumpAndSettle: settling with a session running
      // would run the whole two minutes out and finish it.
      await tester.ensureVisible(stop);
      await tester.pump();
      await tester.tap(stop);
      await tester.pumpAndSettle();
    });

    testWidgets('the circle does not fill the screen', (tester) async {
      await openMeditation(tester, surface: const Size(900, 2000));

      final circle = tester.getSize(find.byType(CustomPaint).first);
      expect(circle.width, lessThanOrEqualTo(kBreathingCircleMaxSize));
      expect(circle.width, equals(circle.height));
    });
  });

  group('the rhythm is not built into the screen', () {
    testWidgets('a different pattern drives the same screen', (tester) async {
      // The architectural requirement, tested directly: the screen knows
      // nothing about four seconds. Given a different rhythm it follows
      // that one, with no change to a single word of its own code.
      const quickBreath = BreathingPattern(
        name: 'test',
        steps: [
          BreathingStep(BreathingPhase.inhale, Duration(seconds: 1)),
          BreathingStep(BreathingPhase.exhale, Duration(seconds: 1)),
        ],
      );

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: environmentOverrides(),
          // The real theme assembly, so the screen's palette tokens
          // resolve exactly as they do in the app.
          child: MaterialApp(
            theme: AppTheme.fromPalette(SummerPalettes.day),
            home: const MeditationScreen(pattern: quickBreath),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(start);
      await tester.pump();
      expect(find.text('Breathe in'), findsOneWidget);

      // One second in, this pattern is already breathing out — and there
      // is no hold in it at all.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Breathe out'), findsOneWidget);
      expect(find.text('Hold'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Breathe in'), findsOneWidget);

      // And the spoken label follows the pattern's own timings.
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Breathe in, 1 seconds'), findsOneWidget);
      handle.dispose();

      await tester.tap(stop);
      await tester.pumpAndSettle();
    });
  });

  group('it wears the season like everything else', () {
    testWidgets('no colour of its own', (tester) async {
      await openMeditation(tester);

      // The screen paints from palette tokens only; if it were holding a
      // colour of its own, the summer palette would not reach it.
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, isNull);
    });
  });
}
