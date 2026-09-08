import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/almanac_button.dart';
import '../../../app/navigation/immersive_session.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/context/cycle_phase_context.dart';
import '../../../core/context/almanac_context.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/cycle_meditation.dart';
import '../domain/meditation_technique.dart';
import '../domain/moon_meditation.dart';
import 'meditation_text.dart';
import 'widgets/breath_guidance.dart';
import 'widgets/duration_stepper.dart';
import 'widgets/glowing_orb.dart';
import 'widgets/moon_context_card.dart';
import 'widgets/technique_chooser.dart';

/// Where the user has got to.
enum MeditationStage {
  /// Four practices to choose between.
  choosingTechnique,

  /// A practice chosen, a length to set, and an orb to tap.
  ready,

  /// The quiet second after the interface goes and before the first
  /// breath is asked for.
  settling,

  /// Breathing.
  breathing,

  /// Done.
  finished;

  /// Whether the app's frame should step out of the way.
  bool get isImmersive =>
      this == MeditationStage.settling || this == MeditationStage.breathing;
}

/// A quiet room with a glowing ball in it.
///
/// Choose a practice, choose how long, tap the ball. Then everything else
/// goes away and the ball is the whole of it: bigger is breathing in,
/// still is holding, smaller is breathing out.
///
/// **One clock.** A single [AnimationController] spans the settling
/// second *and* the session, so the orb, the words and the timing all
/// come from one number. Elapsed below one second is the settling pause;
/// above it, subtract the pause and hand the rest to
/// [BreathingPattern.momentAt]. There is no second timer to drift
/// against, and no way for the orb and the instruction to disagree. It
/// exists only while a session runs, and is stopped and reset the moment
/// one ends.
///
/// **Leaving ends the session.** Backgrounding the app, or switching to
/// another part of the Almanac, stops it and returns to the setup. A
/// session you cannot see is not happening, and quietly completing one in
/// a pocket would be a lie.
class MeditationScreen extends ConsumerStatefulWidget {
  const MeditationScreen({super.key});

  @override
  ConsumerState<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends ConsumerState<MeditationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _session;

  /// Backgrounding, tab-switching and the app's frame, shared with Yoga.
  late final ImmersiveSession _immersion;

  /// The current step, republished only when it actually changes.
  ///
  /// The orb follows every frame; the words must not. Driving them from
  /// this means the instruction — and the announcement a screen reader
  /// makes from it — arrives once a step rather than once a frame.
  final _step = ValueNotifier<BreathingMoment?>(null);

  MeditationStage _stage = MeditationStage.choosingTechnique;
  MeditationTechnique? _technique;
  int _minutes = kDefaultSessionMinutes;

  /// The moon the user arrived with, when they came from the Moon page.
  ///
  /// Taken from the shared intent on arrival and held here for as long as
  /// this screen is the one in front of them. Dropped the moment it is
  /// not, because a contextual intent belongs to the journey that
  /// created it: opening Meditation from the navigation bar later must
  /// not find yesterday's moon still waiting.
  MoonPhase? _arrivedFromMoon;

  /// The cycle phase the user arrived with, when they came from Cycle
  /// Syncing's reflective suggestion.
  ///
  /// Independent of [_arrivedFromMoon]. A moon and a cycle are two
  /// separate observations about the same day, and Meditation may hold
  /// both at once without ever combining them into one claim.
  CyclePhase? _arrivedForPhase;

  @override
  void initState() {
    super.initState();
    _session = AnimationController(
      vsync: this,
      // Set for real when a session starts; a controller needs one now.
      duration: kSettlingPause + Duration(minutes: _minutes),
      // The chosen minutes must stay the chosen minutes. Left to its
      // default, a controller shortens itself twentyfold when the device
      // asks for reduced motion — right for a transition, wrong for a
      // clock. Reduced motion changes how this looks, never how long it
      // lasts; see `still` on the orb.
      animationBehavior: AnimationBehavior.preserve,
    )..addListener(_onTick);

    _immersion = ImmersiveSession(ref: ref, onLeave: _endSession);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _immersion.checkVisibility(context);
    _syncArrival();
  }

  /// Collects an intent on arrival, and lets go of it on the way out.
  ///
  /// Assigned directly rather than through `setState`: this runs
  /// immediately before the build it belongs to, so the new value is
  /// already picked up — and the phase is local state, not a provider.
  ///
  /// **The intent is emptied after the frame, not during it.** Reading it
  /// here is free; clearing it is a change to a provider, and Riverpod
  /// rightly refuses that from a widget life-cycle. So the value is
  /// copied now and the hand-off is closed on the next frame, which also
  /// means the first frame already shows the right context instead of
  /// flickering into it.
  void _syncArrival() {
    // The same seam the immersive session uses to notice it is no longer
    // the visible branch.
    if (!TickerMode.valuesOf(context).enabled) {
      _arrivedFromMoon = null;
      _arrivedForPhase = null;
      return;
    }

    final intent = ref.read(almanacIntentProvider);
    // Two doors into the same room, and each is remembered separately.
    if (intent is MoonMeditationIntent) {
      _arrivedFromMoon = intent.phase;
    } else if (intent is CycleMeditationIntent) {
      _arrivedForPhase = intent.phase;
    } else {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Takes rather than clears, so a journey to somewhere else that
      // began in the same frame is not thrown away.
      ref.read(almanacIntentProvider.notifier).take(FeatureId.meditation);
    });
  }

  @override
  void deactivate() {
    // Whatever the reason this screen is leaving the tree, the frame
    // comes back.
    _immersion.exit();
    super.deactivate();
  }

  @override
  void dispose() {
    _immersion.dispose();
    _session.dispose();
    _step.dispose();
    super.dispose();
  }

  Duration get _sessionLength => Duration(minutes: _minutes);

  /// Time since the orb was tapped, settling pause included.
  Duration get _elapsed =>
      (_session.duration ?? Duration.zero) * _session.value;

  /// Time since the first breath was asked for. Negative during settling.
  Duration get _breathElapsed => _elapsed - kSettlingPause;

  void _onTick() {
    final elapsed = _elapsed;

    // The settling second, ending exactly once.
    if (_stage == MeditationStage.settling && elapsed >= kSettlingPause) {
      setState(() => _stage = MeditationStage.breathing);
    }

    if (_stage == MeditationStage.breathing) {
      final moment = _technique!.pattern.momentAt(_breathElapsed);
      final previous = _step.value;
      if (previous == null ||
          previous.stepIndex != moment.stepIndex ||
          // A cycle can be shorter than a session, so the same step comes
          // round again; the step index alone would not notice.
          moment.elapsedInStep < previous.elapsedInStep) {
        _step.value = moment;
      }
    }

    if (_session.isCompleted && _stage == MeditationStage.breathing) {
      _session.stop();
      _immersion.exit();
      setState(() => _stage = MeditationStage.finished);
    }
  }

  void _chooseTechnique(MeditationTechnique technique) => setState(() {
    _technique = technique;
    _stage = MeditationStage.ready;
  });

  void _backToTechniques() {
    _endSession();
    setState(() {
      _technique = null;
      _stage = MeditationStage.choosingTechnique;
    });
  }

  void _setMinutes(int minutes) => setState(
    () => _minutes = minutes.clamp(kMinSessionMinutes, kMaxSessionMinutes),
  );

  void _start() {
    _step.value = null;
    _session
      ..duration = kSettlingPause + _sessionLength
      ..reset()
      ..forward();
    _immersion.enter();
    setState(() => _stage = MeditationStage.settling);
  }

  /// Stops everything and returns to the setup.
  ///
  /// Safe to call when nothing is running, which is what lets the
  /// lifecycle hooks call it without first asking what state we are in.
  void _endSession() {
    if (!_stage.isImmersive) return;
    _session
      ..stop()
      ..reset();
    _step.value = null;
    _immersion.exit();
    setState(() => _stage = MeditationStage.ready);
  }

  @override
  Widget build(BuildContext context) {
    // The app's existing reduced-motion convention, as used by the
    // Environment screen's sky.
    final still = MediaQuery.disableAnimationsOf(context);

    if (_stage.isImmersive) {
      return _Immersive(
        session: _session,
        technique: _technique!,
        step: _step,
        settling: _stage == MeditationStage.settling,
        still: still,
        onEnd: _endSession,
      );
    }

    return AppScaffold(
      title: 'Meditation',
      // Which practice you are in, said once, where every screen in the
      // app says that sort of thing.
      subtitle: _technique?.name,
      trailing: const AlmanacButton(),
      body: [
        switch (_stage) {
          MeditationStage.choosingTechnique => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // One Almanac: the same day the Moon page and Cycle
              // Syncing are looking at. Above the usual choices, and it
              // changes none of them.
              _TodayContext(
                arrivedFromMoon: _arrivedFromMoon,
                arrivedForPhase: _arrivedForPhase,
                onChoose: _chooseTechnique,
              ),
              TechniqueChooser(onChosen: _chooseTechnique),
            ],
          ),
          MeditationStage.finished => _Finished(
            minutes: _minutes,
            onStartAgain: _start,
            onChooseAnother: _backToTechniques,
          ),
          _ => _Ready(
            minutes: _minutes,
            onMinutesChanged: _setMinutes,
            onStart: _start,
            onChangeTechnique: _backToTechniques,
          ),
        },
      ],
    );
  }
}

/// What today has to say, from up to two independent directions.
///
/// **A moon and a cycle are two observations, never one claim.** They
/// are shown as two small suggestions under one restrained heading, so
/// the page does not repeat "For today" twice and does not push the
/// four practices down the screen. Nothing here ever says a menstrual
/// new moon means anything.
///
/// Either may be absent — Meditation opened normally with no Cycle in
/// the Almanac has only the moon — and then the other is shown on its
/// own, exactly as before.
class _TodayContext extends ConsumerWidget {
  const _TodayContext({
    required this.arrivedFromMoon,
    required this.arrivedForPhase,
    required this.onChoose,
  });

  final MoonPhase? arrivedFromMoon;
  final CyclePhase? arrivedForPhase;
  final ValueChanged<MeditationTechnique> onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclePhase = arrivedForPhase ?? ref.watch(almanacCyclePhaseProvider);
    // The moon is always available; a cycle phase may not be.
    final arrived = arrivedFromMoon != null || arrivedForPhase != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // On a direct entry the heading is said once, here, and each
        // suggestion below simply names what it is about.
        if (!arrived) ...[
          Text(
            MeditationText.forToday,
            style: Theme.of(context).textTheme.journalLabel
                ?.copyWith(color: context.palette.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        _MoonContext(arrivedFrom: arrivedFromMoon, onChoose: onChoose),
        if (cyclePhase case final phase?)
          _CycleContext(
            phase: phase,
            arrived: arrivedForPhase != null,
            onChoose: onChoose,
          ),
      ],
    );
  }
}

/// The cycle phase, and the practice that suits it.
///
/// Reads the phase from the app's shared seam, so Meditation never
/// imports Cycle and never learns anything about bleeding.
class _CycleContext extends StatelessWidget {
  const _CycleContext({
    required this.phase,
    required this.arrived,
    required this.onChoose,
  });

  final CyclePhase phase;

  /// Whether the user came through Cycle Syncing's door, which decides
  /// only how the heading reads.
  final bool arrived;

  final ValueChanged<MeditationTechnique> onChoose;

  @override
  Widget build(BuildContext context) {
    final suggestion = CycleMeditations.forPhase(phase);
    return MoonContextCard(
      heading: arrived ? CycleMeditationIntent(phase).heading : phase.phrase,
      technique: CycleMeditations.techniqueFor(phase),
      invitation: suggestion.invitation,
      onBegin: () => onChoose(CycleMeditations.techniqueFor(phase)),
    );
  }
}

/// Today's moon, and the practice that suits it.
///
/// Reads the moon from the shared [currentMoonProvider] — the same one
/// the Environment page and the Moon detail page read, so all three
/// agree by construction rather than by coincidence.
///
/// [arrivedFrom] is the phase the user travelled with, when they came
/// through the Moon's doorway. When it is null they opened Meditation
/// normally, and the same suggestion appears under a quieter heading
/// rather than being withheld: the context is true either way, and only
/// the wording knows how they got here.
class _MoonContext extends ConsumerWidget {
  const _MoonContext({required this.arrivedFrom, required this.onChoose});

  final MoonPhase? arrivedFrom;
  final ValueChanged<MeditationTechnique> onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The phase they arrived with, if any, otherwise tonight's. They are
    // normally the same; they differ only if the moon has moved on since
    // the tap, and the phase in hand is the honest one to answer.
    final phase = arrivedFrom ?? ref.watch(currentMoonProvider).phase;
    final suggestion = MoonMeditations.forPhase(phase);

    return MoonContextCard(
      // The "For today" heading is said once by the block above, so a
      // direct entry's moon suggestion simply names the moon.
      heading: arrivedFrom == null
          ? phase.label
          : MoonMeditationIntent(arrivedFrom!).heading,
      technique: MoonMeditations.techniqueFor(phase),
      invitation: suggestion.invitation,
      onBegin: () => onChoose(MoonMeditations.techniqueFor(phase)),
    );
  }
}

/// A practice chosen, and an orb waiting to be tapped.
class _Ready extends StatelessWidget {
  const _Ready({
    required this.minutes,
    required this.onMinutesChanged,
    required this.onStart,
    required this.onChangeTechnique,
  });

  final int minutes;
  final ValueChanged<int> onMinutesChanged;
  final VoidCallback onStart;
  final VoidCallback onChangeTechnique;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        // Already the focus of the page, and already the control.
        _TappableOrb(
          label: 'Begin',
          size: kOrbSetupSize,
          onTap: onStart,
          child: const GlowingOrb(
            openness: kOrbStillScale,
            size: kOrbSetupSize,
            still: true,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Tap to begin',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),

        const SizedBox(height: AppSpacing.xl),
        DurationStepper(minutes: minutes, onChanged: onMinutesChanged),

        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: onChangeTechnique,
          child: const Text('Choose a different practice'),
        ),
      ],
    );
  }
}

/// Nothing but the orb.
///
/// No title, no controls, no progress, no navigation. The one thing that
/// is not the orb is the line of guidance underneath, which arrives with
/// each breath and fades — the parts of a practice a size cannot say.
class _Immersive extends StatelessWidget {
  const _Immersive({
    required this.session,
    required this.technique,
    required this.step,
    required this.settling,
    required this.still,
    required this.onEnd,
  });

  final AnimationController session;
  final MeditationTechnique technique;
  final ValueListenable<BreathingMoment?> step;
  final bool settling;
  final bool still;
  final VoidCallback onEnd;

  /// Where the breath is now, read straight from the clock.
  BreathingMoment _momentNow() => technique.pattern.momentAt(
    (session.duration ?? Duration.zero) * session.value - kSettlingPause,
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        // A stack rather than a column, so the length of a line of
        // guidance can never move the orb. Release Tension's out-breath
        // needs a whole sentence and Focus's needs two words; the orb
        // sits in the same place for both, and at any text size.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final orbBox = math.min(kOrbImmersiveSize, constraints.maxWidth);

            return Stack(
              children: [
                Center(
                  child: _TappableOrb(
                    label: 'End the session',
                    size: orbBox,
                    onTap: onEnd,
                    child: settling
                        // The quiet second: the orb, and nothing being
                        // asked of anyone yet.
                        ? GlowingOrb(
                            openness: kOrbStillScale,
                            size: orbBox,
                            still: true,
                          )
                        : _BreathingOrb(
                            session: session,
                            step: step,
                            momentNow: _momentNow,
                            size: orbBox,
                            still: still,
                          ),
                  ),
                ),

                Positioned(
                  top: constraints.maxHeight / 2 + orbBox / 2 + AppSpacing.xl,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  child: settling
                      ? Text(
                          'Tap the orb to end',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall,
                        )
                      : ValueListenableBuilder<BreathingMoment?>(
                          valueListenable: step,
                          builder: (context, moment, _) => moment == null
                              ? const SizedBox.shrink()
                              : still
                              ? BreathGuidance(moment: moment, persistent: true)
                              : AnimatedBuilder(
                                  animation: session,
                                  builder: (context, _) => BreathGuidance(
                                    moment: _momentNow(),
                                    persistent: false,
                                  ),
                                ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The orb, following the breath.
///
/// Rebuilt every frame while a session runs, and only on a step change
/// when the device has asked for reduced motion — so nothing repaints
/// sixty times a second to draw an orb that is not moving.
class _BreathingOrb extends StatelessWidget {
  const _BreathingOrb({
    required this.session,
    required this.step,
    required this.momentNow,
    required this.size,
    required this.still,
  });

  final AnimationController session;
  final ValueListenable<BreathingMoment?> step;
  final BreathingMoment Function() momentNow;
  final double size;
  final bool still;

  @override
  Widget build(BuildContext context) {
    if (still) {
      return ValueListenableBuilder<BreathingMoment?>(
        valueListenable: step,
        builder: (context, moment, _) => GlowingOrb(
          openness: kOrbStillScale,
          size: size,
          still: true,
          nostril: moment?.nostril,
          countdown: moment?.countdown,
        ),
      );
    }

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final moment = momentNow();
        return GlowingOrb(
          openness: moment.openness,
          size: size,
          nostril: moment.nostril,
          countdown: moment.countdown,
        );
      },
    );
  }
}

/// The orb as a control, in one place so it behaves the same before and
/// during a session.
///
/// The painting inside says nothing to a screen reader — the guidance
/// does that. What this adds is the one thing the orb *is*: a labelled
/// button, so a session can be begun and ended without a visible control
/// cluttering the room.
class _TappableOrb extends StatelessWidget {
  const _TappableOrb({
    required this.label,
    required this.size,
    required this.onTap,
    required this.child,
  });

  final String label;
  final double size;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Its own node, so the orb is announced as the one control it is
      // rather than being merged into whatever is around it.
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(dimension: size, child: child),
      ),
    );
  }
}

/// The end. Two words and two ways on.
class _Finished extends StatelessWidget {
  const _Finished({
    required this.minutes,
    required this.onStartAgain,
    required this.onChooseAnother,
  });

  final int minutes;
  final VoidCallback onStartAgain;
  final VoidCallback onChooseAnother;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        const GlowingOrb(
          openness: kOrbStillScale,
          size: kOrbSetupSize,
          still: true,
        ),
        const SizedBox(height: AppSpacing.xl),

        Semantics(
          container: true,
          liveRegion: true,
          child: Text('Well done.', style: textTheme.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(describeSessionLength(minutes), style: textTheme.bodyMedium),

        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(label: 'Start again', onPressed: onStartAgain),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: onChooseAnother,
          child: const Text('Choose another practice'),
        ),
      ],
    );
  }
}
