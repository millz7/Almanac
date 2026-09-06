import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/almanac_button.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/breathing_pattern.dart';
import 'widgets/breathing_circle.dart';

/// Where a session has got to.
enum MeditationSessionState { idle, breathing, finished }

/// Two quiet minutes, following a circle.
///
/// The whole feature is one screen with one control on it. There is no
/// duration to pick, no sound to choose and nothing to configure, because
/// the point is to press one button and stop deciding things for a while.
///
/// **One clock.** A single [AnimationController] spans the entire
/// session: its value is how far through the two minutes we are, and both
/// the drawn breath and the words come from that same number by way of
/// [BreathingPattern.momentAt]. There is no second timer to drift against
/// and no way for the circle and the instruction to disagree. It exists
/// only while a session is running, and is stopped and reset the moment
/// one ends.
///
/// **Leaving the screen ends the session.** Backgrounding the app, or
/// switching to another part of the Almanac, stops it and returns here to
/// the beginning. A breathing session you cannot see is not happening,
/// and quietly "completing" one in a pocket would be a lie. It also keeps
/// the rule simple enough to state, which pausing and resuming would not
/// — and this screen deliberately has no resume control.
class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key, this.pattern = kAlmanacBreath});

  /// The rhythm to breathe to. Injected only so a test can use a short
  /// one; the app has exactly one pattern.
  final BreathingPattern pattern;

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _session;
  late final AppLifecycleListener _lifecycle;

  /// The current phase, republished only when it actually changes.
  ///
  /// The circle follows every frame; the words must not. Driving them
  /// from this instead means the instruction — and the announcement a
  /// screen reader makes from it — is rebuilt about thirty times in two
  /// minutes rather than seven thousand.
  final _phase = ValueNotifier<BreathingMoment>(
    const BreathingMoment(
      phase: BreathingPhase.inhale,
      elapsedInPhase: Duration.zero,
      phaseLength: Duration(seconds: 4),
    ),
  );

  MeditationSessionState _state = MeditationSessionState.idle;

  @override
  void initState() {
    super.initState();
    _session = AnimationController(
      vsync: this,
      duration: kMeditationSessionLength,
      // Two minutes must stay two minutes. Left to its default, a
      // controller shortens itself twentyfold when the device asks for
      // reduced motion — which is right for a transition and wrong for a
      // clock. Reduced motion changes how this looks, never how long it
      // lasts; see the `still` circle below.
      animationBehavior: AnimationBehavior.preserve,
    )..addListener(_onTick);

    // Both, and deliberately not `onInactive`: hidden and paused mean the
    // app is genuinely out of sight, whereas inactive is a notification
    // shade or an incoming call, which should not throw away somebody's
    // session. `_endSession` is idempotent, so whichever fires first
    // wins and the second does nothing.
    _lifecycle = AppLifecycleListener(
      onHide: _endSession,
      onPause: _endSession,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Switching to another part of the Almanac leaves this screen alive
    // but mutes its ticker, which would otherwise freeze a session
    // half-finished and resume it days later. Same rule as backgrounding:
    // end it.
    if (!TickerMode.valuesOf(context).enabled) _endSession();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _session.dispose();
    _phase.dispose();
    super.dispose();
  }

  Duration get _elapsed => kMeditationSessionLength * _session.value;

  void _onTick() {
    final moment = widget.pattern.momentAt(_elapsed);
    if (moment.phase != _phase.value.phase) _phase.value = moment;

    if (_session.isCompleted && _state == MeditationSessionState.breathing) {
      setState(() => _state = MeditationSessionState.finished);
    }
  }

  void _start() {
    _phase.value = widget.pattern.momentAt(Duration.zero);
    _session
      ..reset()
      ..forward();
    setState(() => _state = MeditationSessionState.breathing);
  }

  /// Stops everything and returns to the beginning.
  ///
  /// Safe to call when nothing is running, which is what lets the
  /// lifecycle hooks call it without first asking what state we are in.
  void _endSession() {
    if (_state != MeditationSessionState.breathing) return;
    _session
      ..stop()
      ..reset();
    setState(() => _state = MeditationSessionState.idle);
  }

  @override
  Widget build(BuildContext context) {
    // The app's existing reduced-motion convention, as used by the
    // Environment screen's sky.
    final still = MediaQuery.disableAnimationsOf(context);

    return AppScaffold(
      title: 'Meditation',
      trailing: const AlmanacButton(),
      body: [
        Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            _Circle(
              session: _session,
              pattern: widget.pattern,
              phase: _phase,
              still: still,
              running: _state == MeditationSessionState.breathing,
            ),
            const SizedBox(height: AppSpacing.xl),
            _Words(state: _state, phase: _phase, session: _session),
            const SizedBox(height: AppSpacing.xl),
            _Control(state: _state, onStart: _start, onStop: _endSession),
          ],
        ),
      ],
    );
  }
}

/// The breath itself.
///
/// Rebuilt every frame while a session runs, and only on a phase change
/// when the device has asked for reduced motion — so nothing repaints
/// sixty times a second to draw a circle that is not moving.
class _Circle extends StatelessWidget {
  const _Circle({
    required this.session,
    required this.pattern,
    required this.phase,
    required this.still,
    required this.running,
  });

  final AnimationController session;
  final BreathingPattern pattern;
  final ValueListenable<BreathingMoment> phase;
  final bool still;
  final bool running;

  @override
  Widget build(BuildContext context) {
    if (!running) {
      // Nothing is animating between sessions: the circle simply rests.
      return const BreathingCircle(
        openness: kBreathStillScale,
        sessionProgress: 0,
        still: true,
      );
    }

    if (still) {
      return ValueListenableBuilder<BreathingMoment>(
        valueListenable: phase,
        builder: (context, moment, _) => BreathingCircle(
          openness: moment.openness,
          sessionProgress: session.value,
          still: true,
        ),
      );
    }

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BreathingCircle(
        openness: pattern
            .momentAt(kMeditationSessionLength * session.value)
            .openness,
        sessionProgress: session.value,
      ),
    );
  }
}

/// What the screen says: one instruction, and one quiet line under it.
class _Words extends StatelessWidget {
  const _Words({
    required this.state,
    required this.phase,
    required this.session,
  });

  final MeditationSessionState state;
  final ValueListenable<BreathingMoment> phase;
  final AnimationController session;

  @override
  Widget build(BuildContext context) {
    if (state != MeditationSessionState.breathing) {
      return _Lines(
        heading: state == MeditationSessionState.finished
            ? 'Well done.'
            : 'Take a slow breath',
        supporting: state == MeditationSessionState.finished
            ? 'Two quiet minutes.'
            : 'Two quiet minutes, following the circle.',
        // Announced on arrival, which is how a screen reader learns the
        // session has ended without being told every second that it has
        // not.
        announce: state == MeditationSessionState.finished,
      );
    }

    return ValueListenableBuilder<BreathingMoment>(
      valueListenable: phase,
      builder: (context, moment, _) => _Lines(
        heading: moment.phase.instruction,
        // The drawn circle is not information a screen reader can use, so
        // the length of the phase is said out loud instead: "Breathe in,
        // 4 seconds". Rebuilt once per phase, so it is a cue to breathe
        // by rather than a stream of chatter.
        spoken:
            '${moment.phase.instruction}, '
            '${moment.phaseLength.inSeconds} seconds',
        supporting: _remaining(session.value),
        announce: true,
      ),
    );
  }

  /// A coarse sense of how much is left. Deliberately vague: the ring
  /// around the circle carries the detail, and a ticking clock is the
  /// opposite of what this screen is for.
  static String _remaining(double progress) {
    final left = kMeditationSessionLength * (1 - progress);
    if (left > const Duration(minutes: 1)) {
      return '${(left.inSeconds / 60).ceil()} minutes left';
    }
    if (left > const Duration(seconds: 20)) return 'Less than a minute left';
    return 'Almost there';
  }
}

class _Lines extends StatelessWidget {
  const _Lines({
    required this.heading,
    required this.supporting,
    this.spoken,
    this.announce = false,
  });

  final String heading;
  final String supporting;

  /// What a screen reader hears in place of [heading], when there is more
  /// to say than is worth printing.
  final String? spoken;
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Semantics(
          // Its own node, so the live region announces this line and
          // nothing else. When there is a spoken form it replaces the
          // printed one; otherwise the printed text is what is read.
          container: true,
          liveRegion: announce,
          label: spoken,
          excludeSemantics: spoken != null,
          child: Text(
            heading,
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          supporting,
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// One button, whichever state the screen is in.
class _Control extends StatelessWidget {
  const _Control({
    required this.state,
    required this.onStart,
    required this.onStop,
  });

  final MeditationSessionState state;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) => switch (state) {
    MeditationSessionState.idle => PrimaryButton(
      label: 'Start',
      onPressed: onStart,
    ),
    // Quieter than starting: stopping early is allowed, not encouraged.
    MeditationSessionState.breathing => OutlinedButton(
      onPressed: onStop,
      child: const Text('Stop'),
    ),
    MeditationSessionState.finished => PrimaryButton(
      label: 'Start again',
      onPressed: onStart,
    ),
  };
}
