import 'package:almanac/app/almanac_button.dart';
import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/app/navigation/immersion.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:almanac/features/meditation/domain/meditation_technique.dart';
import 'package:almanac/features/meditation/presentation/widgets/glowing_orb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

void main() {
  setUpAll(useTimeZoneDatabase);

  final orb = find.byType(GlowingOrb);
  // By icon rather than by tooltip: a tooltip finder matches the tooltip
  // itself, not the button wrapped around it.
  final longer = find.widgetWithIcon(IconButton, Icons.add);
  final shorter = find.widgetWithIcon(IconButton, Icons.remove);
  final startAgain = find.widgetWithText(ElevatedButton, 'Start again');
  // `late`, because a semantics finder reaches for the binding as soon as
  // it is built and the binding does not exist until a test runs.
  late final begin = find.bySemanticsLabel('Begin');
  late final endSession = find.bySemanticsLabel('End the session');

  Finder practice(String name) => find.widgetWithText(ChoiceCard, name);

  /// Opens Meditation through the real navigation, as a user with it in
  /// their Almanac would.
  Future<ProviderContainer> openMeditation(
    WidgetTester tester, {
    double textScale = 1,
    bool reducedMotion = false,
    Size surface = const Size(420, 1400),
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
      overrides: environmentOverrides(features: const {FeatureId.meditation}),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Meditation'));
    await tester.pumpAndSettle();
    return container;
  }

  /// Chooses a practice and lands in the ready state.
  Future<void> choose(WidgetTester tester, String name) async {
    await tester.ensureVisible(practice(name));
    await tester.pumpAndSettle();
    await tester.tap(practice(name));
    await tester.pumpAndSettle();
  }

  /// Taps the orb and lets the settling second pass, so the next pump is
  /// the first breath.
  Future<void> beginAndSettle(WidgetTester tester) async {
    await tester.tap(begin);
    // A bare pump first: a ticker's clock starts on its first frame.
    await tester.pump();
    await tester.pump(kSettlingPause);
  }

  GlowingOrb orbOf(WidgetTester tester) => tester.widget<GlowingOrb>(orb.first);

  group('choosing a practice', () {
    testWidgets('all four are offered, with a line each', (tester) async {
      await openMeditation(tester);

      expect(find.text('Choose a practice'), findsOneWidget);
      for (final technique in MeditationTechniques.all) {
        expect(practice(technique.name), findsOneWidget);
        expect(find.text(technique.description), findsOneWidget);
      }
      // Nothing to start yet.
      expect(begin, findsNothing);
      expect(orb, findsNothing);
    });

    testWidgets('choosing one puts the orb in front of you', (tester) async {
      await openMeditation(tester);
      await choose(tester, 'Sleep');

      expect(orb, findsOneWidget);
      expect(begin, findsOneWidget);
      expect(find.text('Tap to begin'), findsOneWidget);
      // The other doors have closed behind you.
      for (final technique in MeditationTechniques.all) {
        expect(practice(technique.name), findsNothing);
      }
      // But which room you are in is still clear.
      expect(find.text('Sleep'), findsOneWidget);
    });

    testWidgets('you can change your mind without leaving Meditation', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');
      expect(find.text('Focus'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(TextButton, 'Choose a different practice'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose a practice'), findsOneWidget);
      expect(practice('Balance'), findsOneWidget);

      await choose(tester, 'Balance');
      expect(find.text('Balance'), findsOneWidget);
      // Still inside Meditation, with its navigation intact.
      expect(find.byType(AlmanacNavigationBar), findsOneWidget);
    });
  });

  group('how long', () {
    testWidgets('four minutes to begin with, marked as a good place', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');

      expect(find.text('4 minutes'), findsOneWidget);
      expect(find.text('A good place to start'), findsOneWidget);
    });

    testWidgets('can be lengthened and shortened a minute at a time', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');

      await tester.tap(longer);
      await tester.pumpAndSettle();
      expect(find.text('5 minutes'), findsOneWidget);

      await tester.tap(longer);
      await tester.pumpAndSettle();
      expect(find.text('6 minutes'), findsOneWidget);

      await tester.tap(shorter);
      await tester.pumpAndSettle();
      expect(find.text('5 minutes'), findsOneWidget);
    });

    testWidgets('the recommendation only marks the recommended length', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');

      await tester.tap(longer);
      await tester.pumpAndSettle();

      final hint = tester.widget<Opacity>(
        find.ancestor(
          of: find.text('A good place to start'),
          matching: find.byType(Opacity),
        ),
      );
      expect(hint.opacity, 0);
    });

    testWidgets('stops at the ends of its range rather than running on', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');

      for (var tap = 0; tap < kMaxSessionMinutes; tap++) {
        if (tester.widget<IconButton>(longer).onPressed == null) break;
        await tester.tap(longer);
        await tester.pumpAndSettle();
      }
      expect(find.text('$kMaxSessionMinutes minutes'), findsOneWidget);

      for (var tap = 0; tap < kMaxSessionMinutes; tap++) {
        if (tester.widget<IconButton>(shorter).onPressed == null) break;
        await tester.tap(shorter);
        await tester.pumpAndSettle();
      }
      expect(find.text('$kMinSessionMinutes minutes'), findsOneWidget);
    });

    testWidgets('the chosen length survives a change of practice', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');

      await tester.tap(longer);
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(TextButton, 'Choose a different practice'),
      );
      await tester.pumpAndSettle();
      await choose(tester, 'Sleep');

      expect(find.text('5 minutes'), findsOneWidget);
    });
  });

  group('the start transition', () {
    testWidgets('tapping the orb takes everything else away', (tester) async {
      final container = await openMeditation(tester);
      await choose(tester, 'Focus');

      await tester.tap(begin);
      await tester.pump();

      // Only the orb is left.
      expect(orb, findsOneWidget);
      expect(find.text('Meditation'), findsNothing);
      expect(find.text('Tap to begin'), findsNothing);
      expect(find.text('4 minutes'), findsNothing);
      expect(longer, findsNothing);
      expect(shorter, findsNothing);
      expect(find.byType(AlmanacButton), findsNothing);
      // Including the app's own navigation.
      expect(find.byType(AlmanacNavigationBar), findsNothing);
      expect(container.read(immersiveModeProvider), isTrue);
    });

    testWidgets('nothing is asked of you for exactly one second', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');

      await tester.tap(begin);
      await tester.pump();

      // The quiet second: an orb, and no instruction.
      expect(orb, findsOneWidget);
      expect(find.text('Breathe in'), findsNothing);
      expect(orbOf(tester).still, isTrue);

      await tester.pump(const Duration(milliseconds: 999));
      expect(
        find.text('Breathe in'),
        findsNothing,
        reason: 'the first breath must not begin before the second is up',
      );

      // And then it begins.
      await tester.pump(const Duration(milliseconds: 2));
      expect(find.text('Breathe in'), findsOneWidget);
      expect(orbOf(tester).still, isFalse);

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });

    testWidgets('the orb does not start growing during the quiet second', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');

      await tester.tap(begin);
      await tester.pump();
      final resting = orbOf(tester).openness;

      await tester.pump(const Duration(milliseconds: 500));
      expect(orbOf(tester).openness, resting);
      expect(orbOf(tester).still, isTrue);

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });

    testWidgets('a hint says how to get out, and does not persist', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');

      await tester.tap(begin);
      await tester.pump();
      expect(find.text('Tap the orb to end'), findsOneWidget);

      await tester.pump(kSettlingPause);
      expect(find.text('Tap the orb to end'), findsNothing);

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });
  });

  group('breathing', () {
    testWidgets('Focus runs its square', (tester) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');
      await beginAndSettle(tester);

      expect(find.text('Breathe in'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Hold'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Breathe out'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Breathe in'), findsOneWidget);

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });

    testWidgets('Sleep holds for seven and breathes out for eight', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Sleep');
      await beginAndSettle(tester);

      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Hold'), findsOneWidget);
      // Still holding at six seconds, which Focus would not be.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Hold'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Breathe out'), findsOneWidget);

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });

    testWidgets('the orb grows, holds and shrinks with the breath', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');
      await beginAndSettle(tester);

      final atStart = orbOf(tester).openness;
      await tester.pump(const Duration(seconds: 2));
      final midInhale = orbOf(tester).openness;
      expect(midInhale, greaterThan(atStart));

      await tester.pump(const Duration(seconds: 2));
      expect(orbOf(tester).openness, closeTo(1, 0.01));

      // Held.
      await tester.pump(const Duration(seconds: 2));
      expect(orbOf(tester).openness, closeTo(1, 0.01));

      // And on the way out.
      await tester.pump(const Duration(seconds: 4));
      expect(orbOf(tester).openness, lessThan(0.9));

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });

    testWidgets('Release Tension guides the mouth, tongue and sound', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Release Tension');
      await beginAndSettle(tester);

      expect(find.text('Deep inhale through the nose'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      expect(
        find.text('Exhale through the mouth with a haa sound, tongue out'),
        findsOneWidget,
      );

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });

    testWidgets('the immersive screen stays free of everything else', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');
      await beginAndSettle(tester);
      await tester.pump(const Duration(seconds: 6));

      expect(find.byType(AlmanacNavigationBar), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(find.textContaining('minutes'), findsNothing);
      expect(find.textContaining('left'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('Balance while it runs', () {
    testWidgets('leans the orb to the side the breath is using', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Balance');
      await beginAndSettle(tester);

      // In on the left...
      expect(orbOf(tester).nostril, Nostril.left);

      // ...held with both...
      await tester.pump(const Duration(seconds: 4));
      expect(orbOf(tester).nostril, Nostril.both);

      // ...out on the right...
      await tester.pump(const Duration(seconds: 4));
      expect(orbOf(tester).nostril, Nostril.right);

      // ...then in on the right, and out on the left.
      await tester.pump(const Duration(seconds: 6));
      expect(orbOf(tester).nostril, Nostril.right);
      await tester.pump(const Duration(seconds: 4));
      expect(orbOf(tester).nostril, Nostril.both);
      await tester.pump(const Duration(seconds: 4));
      expect(orbOf(tester).nostril, Nostril.left);

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });

    testWidgets('counts the hold down inside the orb', (tester) async {
      await openMeditation(tester);
      await choose(tester, 'Balance');
      await beginAndSettle(tester);

      // Nothing to count on the way in.
      expect(orbOf(tester).countdown, isNull);
      expect(find.text('4'), findsNothing);

      await tester.pump(const Duration(seconds: 4));
      expect(orbOf(tester).countdown, 4);
      expect(find.text('4'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('3'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('2'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('1'), findsOneWidget);

      // Gone again on the out-breath.
      await tester.pump(const Duration(seconds: 1));
      expect(orbOf(tester).countdown, isNull);

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });

    testWidgets('says the side out loud, which a lean cannot', (tester) async {
      final handle = tester.ensureSemantics();
      await openMeditation(tester);
      await choose(tester, 'Balance');
      await beginAndSettle(tester);

      expect(
        find.bySemanticsLabel('Inhale through the left nostril'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 4));
      expect(
        find.bySemanticsLabel('Hold with both nostrils closed, 4 seconds'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 4));
      expect(
        find.bySemanticsLabel('Exhale through the right nostril'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 6));
      expect(
        find.bySemanticsLabel('Inhale through the right nostril'),
        findsOneWidget,
      );

      await tester.tap(endSession);
      await tester.pumpAndSettle();
      handle.dispose();
    });
  });

  group('the session lasts the length that was chosen', () {
    testWidgets('four minutes of breathing, after the settling second', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');
      await beginAndSettle(tester);

      await tester.pump(const Duration(seconds: 239));
      expect(find.text('Well done.'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Well done.'), findsOneWidget);
    });

    testWidgets('a longer session really is longer', (tester) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');

      await tester.tap(longer);
      await tester.pumpAndSettle();
      await beginAndSettle(tester);

      // Four minutes in, a five-minute session is still going.
      await tester.pump(const Duration(minutes: 4));
      expect(find.text('Well done.'), findsNothing);

      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(find.text('Well done.'), findsOneWidget);
      expect(find.text('Five quiet minutes.'), findsOneWidget);
    });

    testWidgets('ends cleanly part-way through a cycle', (tester) async {
      // Four minutes is not a whole number of Sleep's 19-second cycles,
      // so this ends mid-breath — which is the session's business, not
      // the cycle's.
      await openMeditation(tester);
      await choose(tester, 'Sleep');
      await beginAndSettle(tester);

      await tester.pump(const Duration(minutes: 4));
      await tester.pumpAndSettle();

      expect(find.text('Well done.'), findsOneWidget);
      expect(find.text('Four quiet minutes.'), findsOneWidget);
    });
  });

  group('finishing', () {
    Future<void> runToEnd(WidgetTester tester) async {
      await choose(tester, 'Focus');
      await beginAndSettle(tester);
      await tester.pump(const Duration(minutes: 4));
      await tester.pumpAndSettle();
    }

    testWidgets('says two words and nothing more', (tester) async {
      final container = await openMeditation(tester);
      await runToEnd(tester);

      expect(find.text('Well done.'), findsOneWidget);
      expect(find.text('Four quiet minutes.'), findsOneWidget);
      // Understated: nothing counted, nothing awarded.
      expect(find.textContaining('streak'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('total'), findsNothing);

      // The frame is back.
      expect(container.read(immersiveModeProvider), isFalse);
      expect(find.byType(AlmanacNavigationBar), findsOneWidget);
    });

    testWidgets('offers another go and another practice', (tester) async {
      await openMeditation(tester);
      await runToEnd(tester);

      expect(startAgain, findsOneWidget);
      expect(
        find.widgetWithText(TextButton, 'Choose another practice'),
        findsOneWidget,
      );
    });

    testWidgets('starting again runs a whole new session', (tester) async {
      await openMeditation(tester);
      await runToEnd(tester);

      await tester.tap(startAgain);
      await tester.pump();
      await tester.pump(kSettlingPause);

      expect(find.text('Breathe in'), findsOneWidget);
      expect(find.byType(AlmanacNavigationBar), findsNothing);

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });

    testWidgets('another practice goes back to the four doors', (tester) async {
      await openMeditation(tester);
      await runToEnd(tester);

      await tester.tap(
        find.widgetWithText(TextButton, 'Choose another practice'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose a practice'), findsOneWidget);
      expect(practice('Balance'), findsOneWidget);
    });

    testWidgets('nothing is left running', (tester) async {
      await openMeditation(tester);
      await runToEnd(tester);

      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('stopping', () {
    testWidgets('tapping the orb returns to the setup', (tester) async {
      final container = await openMeditation(tester);
      await choose(tester, 'Focus');
      await beginAndSettle(tester);
      await tester.pump(const Duration(seconds: 30));

      await tester.tap(endSession);
      await tester.pumpAndSettle();

      // Back where you were, with the practice and length still chosen.
      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('4 minutes'), findsOneWidget);
      expect(begin, findsOneWidget);
      expect(container.read(immersiveModeProvider), isFalse);
      expect(find.byType(AlmanacNavigationBar), findsOneWidget);
    });

    testWidgets('leaves nothing running', (tester) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');
      await beginAndSettle(tester);
      await tester.pump(const Duration(seconds: 30));

      await tester.tap(endSession);
      await tester.pumpAndSettle();

      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('a stopped session starts again from the beginning', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');
      await beginAndSettle(tester);
      await tester.pump(const Duration(seconds: 30));
      await tester.tap(endSession);
      await tester.pumpAndSettle();

      await beginAndSettle(tester);
      expect(find.text('Breathe in'), findsOneWidget);
      expect(orbOf(tester).openness, closeTo(0, 0.05));

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });

    testWidgets('can be stopped during the settling second', (tester) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');

      await tester.tap(begin);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(endSession);
      await tester.pumpAndSettle();

      expect(begin, findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('leaving the screen', () {
    testWidgets('backgrounding the app ends the session', (tester) async {
      final container = await openMeditation(tester);
      await choose(tester, 'Focus');
      await beginAndSettle(tester);
      await tester.pump(const Duration(seconds: 30));

      // Out of sight and back again, walking the real Android sequence.
      // `inactive` alone — a notification shade — deliberately does not
      // end a session.
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

      expect(begin, findsOneWidget);
      expect(container.read(immersiveModeProvider), isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('switching to another part of the Almanac ends it too', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(
        overrides: environmentOverrides(
          features: const {FeatureId.meditation, FeatureId.garden},
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

      await tester.tap(find.bySemanticsLabel('Meditation'));
      await tester.pumpAndSettle();
      await choose(tester, 'Focus');
      await beginAndSettle(tester);
      await tester.pump(const Duration(seconds: 30));

      // The navigation is gone, so leaving means coming out of immersion
      // first — which is exactly what tapping the orb does.
      await tester.tap(endSession);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Garden'));
      await tester.pumpAndSettle();

      expect(container.read(immersiveModeProvider), isFalse);
      expect(tester.binding.transientCallbackCount, 0);

      await tester.tap(find.bySemanticsLabel('Meditation'));
      await tester.pumpAndSettle();
      expect(begin, findsOneWidget);
    });
  });

  group('reduced motion', () {
    testWidgets('the session still lasts its full four minutes', (
      tester,
    ) async {
      // The trap this guards: an AnimationController shortens itself
      // twentyfold when animations are disabled, which would turn four
      // minutes into twelve seconds.
      await openMeditation(tester, reducedMotion: true);
      await choose(tester, 'Focus');
      await beginAndSettle(tester);

      await tester.pump(const Duration(seconds: 239));
      expect(find.text('Well done.'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Well done.'), findsOneWidget);
    });

    testWidgets('the settling second is still a second', (tester) async {
      await openMeditation(tester, reducedMotion: true);
      await choose(tester, 'Focus');

      await tester.tap(begin);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 999));
      expect(find.text('Breathe in'), findsNothing);

      await tester.pump(const Duration(milliseconds: 2));
      expect(find.text('Breathe in'), findsOneWidget);

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });

    testWidgets('the orb holds still and the words carry the rhythm', (
      tester,
    ) async {
      await openMeditation(tester, reducedMotion: true);
      await choose(tester, 'Focus');
      await beginAndSettle(tester);

      expect(orbOf(tester).still, isTrue);
      final size = orbOf(tester).openness;

      await tester.pump(const Duration(seconds: 2));
      expect(orbOf(tester).openness, size);
      expect(orbOf(tester).still, isTrue);

      // The instruction still follows the breath.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Hold'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Breathe out'), findsOneWidget);

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });

    testWidgets('the guidance stays put instead of fading', (tester) async {
      await openMeditation(tester, reducedMotion: true);
      await choose(tester, 'Focus');
      await beginAndSettle(tester);

      // Text appearing and disappearing is itself motion, and with a
      // still orb the words are the only cue there is.
      await tester.pump(const Duration(milliseconds: 3500));
      expect(find.text('Breathe in'), findsOneWidget);
      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.text('Breathe in'),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 1);

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });

    testWidgets('Balance still counts and still leans', (tester) async {
      await openMeditation(tester, reducedMotion: true);
      await choose(tester, 'Balance');
      await beginAndSettle(tester);

      expect(orbOf(tester).nostril, Nostril.left);

      await tester.pump(const Duration(seconds: 4));
      expect(orbOf(tester).nostril, Nostril.both);
      expect(orbOf(tester).countdown, 4);

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });
  });

  group('accessibility', () {
    testWidgets('the phase is announced, once, with its length', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openMeditation(tester);
      await choose(tester, 'Focus');
      await beginAndSettle(tester);

      expect(find.bySemanticsLabel('Breathe in, 4 seconds'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.bySemanticsLabel('Hold, 4 seconds'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.bySemanticsLabel('Breathe out, 4 seconds'), findsOneWidget);

      await tester.tap(endSession);
      await tester.pumpAndSettle();
      handle.dispose();
    });

    testWidgets('the instruction changes once a phase, not once a frame', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');
      await beginAndSettle(tester);

      var changes = 0;
      String? previous;
      for (var ms = 0; ms < 12000; ms += 100) {
        final current = ['Breathe in', 'Hold', 'Breathe out'].firstWhere(
          (text) => find.text(text).evaluate().isNotEmpty,
          orElse: () => '',
        );
        if (current.isNotEmpty && current != previous) changes++;
        previous = current.isEmpty ? previous : current;
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Three phases in a twelve-second square, not a hundred and twenty.
      expect(changes, 3);

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });

    testWidgets('the orb is a labelled control, not a described picture', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openMeditation(tester);
      await choose(tester, 'Focus');

      // The painting says nothing; the node around it is the one thing
      // the orb actually is — the way in and the way out.
      expect(
        find.descendant(of: orb, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
      expect(begin, findsOneWidget);

      await tester.tap(begin);
      await tester.pump();
      expect(endSession, findsOneWidget);
      expect(begin, findsNothing);

      await tester.tap(endSession);
      await tester.pumpAndSettle();
      handle.dispose();
    });

    testWidgets('the orb is a generous target, and so are the controls', (
      tester,
    ) async {
      await openMeditation(tester);
      await choose(tester, 'Focus');

      expect(tester.getSize(begin).shortestSide, greaterThanOrEqualTo(48));
      for (final control in [longer, shorter]) {
        expect(tester.getSize(control).shortestSide, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('doubling the text size breaks nothing', (tester) async {
      await openMeditation(tester, textScale: 2);

      expect(tester.takeException(), isNull);
      for (final technique in MeditationTechniques.all) {
        expect(practice(technique.name), findsOneWidget);
      }

      await choose(tester, 'Balance');
      expect(tester.takeException(), isNull);
      expect(find.text('4 minutes'), findsOneWidget);

      await tester.ensureVisible(begin);
      await tester.pump();
      await tester.tap(begin);
      await tester.pump();
      await tester.pump(kSettlingPause);
      await tester.pump(const Duration(seconds: 4));

      expect(tester.takeException(), isNull);
      expect(find.text('Hold with both nostrils closed'), findsOneWidget);

      await tester.tap(endSession);
      await tester.pumpAndSettle();
    });
  });
}
