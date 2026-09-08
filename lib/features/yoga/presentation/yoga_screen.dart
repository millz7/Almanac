import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/almanac_button.dart';
import '../../../app/navigation/immersive_session.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/context/cycle_phase_context.dart';
import '../../../core/context/almanac_context.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/cycle_yoga.dart';
import '../domain/yoga_practices.dart';
import 'widgets/cycle_context_card.dart';
import 'widgets/pose_figure.dart';
import 'widgets/practice_chooser.dart';
import 'widgets/step_guidance.dart';

/// Where the user has got to.
enum YogaStage {
  /// Three practices to choose between.
  choosingPractice,

  /// A practice chosen, and a Start control.
  ready,

  /// Moving.
  practising,

  /// Done.
  finished;

  bool get isImmersive => this == YogaStage.practising;
}

/// Somewhere to move.
///
/// The same shape as Meditation — choose, prepare, begin — and the same
/// clock architecture, but the opposite of its wordlessness: a movement
/// has to be described before anyone can follow it, so the practice
/// screen keeps its words. They are simply kept quiet, and kept below the
/// figure.
///
/// **One clock.** A single [AnimationController] spans the whole
/// practice. Its value is how far through the sequence we are, and the
/// figure, the pose name, the instruction, the breath cue, the step
/// timer and the count through the sequence all come from that one number
/// by way of [YogaPractice.momentAt]. There is no second timer to drift
/// against.
///
/// **Leaving ends the practice.** Backgrounding the app, or switching to
/// another part of the Almanac, stops it and returns to the setup — the
/// same rule as Meditation, and the same [ImmersiveSession] enforcing it.
/// A practice you cannot see is not happening.
class YogaScreen extends ConsumerStatefulWidget {
  const YogaScreen({super.key});

  @override
  ConsumerState<YogaScreen> createState() => _YogaScreenState();
}

class _YogaScreenState extends ConsumerState<YogaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _practice;

  /// Backgrounding, tab-switching and the app's frame, shared with
  /// Meditation.
  late final ImmersiveSession _immersion;

  /// The current movement, republished only when it actually changes.
  ///
  /// The figure follows every frame on the flowing steps; the words must
  /// not. Driving them from this means the instruction — and the
  /// announcement a screen reader makes from it — arrives once a movement
  /// rather than once a frame.
  final _step = ValueNotifier<YogaMoment?>(null);

  /// Whole seconds left in the current movement, republished only when
  /// the number changes — so the countdown costs one rebuild a second
  /// rather than sixty.
  final _secondsLeft = ValueNotifier<int>(0);

  YogaStage _stage = YogaStage.choosingPractice;
  YogaPractice? _chosen;

  /// The cycle phase the user arrived with, when they came from Cycle
  /// Syncing's movement guidance.
  ///
  /// Held for as long as this screen is the one in front of them, and
  /// dropped the moment it is not: a contextual intent belongs to the
  /// journey that created it.
  CyclePhase? _arrivedForPhase;

  @override
  void initState() {
    super.initState();
    _practice = AnimationController(
      vsync: this,
      // Set for real when a practice starts; a controller needs one now.
      duration: const Duration(minutes: 1),
      // A practice must take as long as it takes. Left to its default, a
      // controller shortens itself twentyfold when the device asks for
      // reduced motion — right for a transition, wrong for a clock.
      // Reduced motion changes how this looks, never how long it lasts;
      // see `still` below.
      animationBehavior: AnimationBehavior.preserve,
    )..addListener(_onTick);

    _immersion = ImmersiveSession(ref: ref, onLeave: _endPractice);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _immersion.checkVisibility(context);
    _syncArrival();
  }

  /// Collects an intent on arrival, and lets go of it on the way out.
  ///
  /// Read now, emptied after the frame: changing a provider from a
  /// widget life-cycle is not allowed, and deferring it also means the
  /// first frame already shows the right context.
  void _syncArrival() {
    if (!TickerMode.valuesOf(context).enabled) {
      _arrivedForPhase = null;
      return;
    }

    final intent = ref.read(almanacIntentProvider);
    if (intent is! CycleYogaIntent) return;

    _arrivedForPhase = intent.phase;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(almanacIntentProvider.notifier).take(FeatureId.yoga);
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
    _practice.dispose();
    _step.dispose();
    _secondsLeft.dispose();
    super.dispose();
  }

  Duration get _elapsed =>
      (_practice.duration ?? Duration.zero) * _practice.value;

  YogaMoment _momentNow() => _chosen!.momentAt(_elapsed);

  void _onTick() {
    if (_stage != YogaStage.practising) return;

    final moment = _momentNow();
    if (_step.value?.stepNumber != moment.stepNumber) _step.value = moment;
    if (_secondsLeft.value != moment.secondsRemaining) {
      _secondsLeft.value = moment.secondsRemaining;
    }

    if (_practice.isCompleted) {
      _practice.stop();
      _immersion.exit();
      setState(() => _stage = YogaStage.finished);
    }
  }

  void _choosePractice(YogaPractice practice) => setState(() {
    _chosen = practice;
    _stage = YogaStage.ready;
  });

  void _backToPractices() {
    _endPractice();
    setState(() {
      _chosen = null;
      _stage = YogaStage.choosingPractice;
    });
  }

  void _start() {
    final practice = _chosen!;
    _practice
      ..duration = practice.length
      ..reset()
      ..forward();
    _step.value = practice.momentAt(Duration.zero);
    _secondsLeft.value = _step.value!.secondsRemaining;
    _immersion.enter();
    setState(() => _stage = YogaStage.practising);
  }

  /// Stops everything and returns to the setup.
  ///
  /// Safe to call when nothing is running, which is what lets the
  /// lifecycle hooks call it without first asking what state we are in.
  void _endPractice() {
    if (!_stage.isImmersive) return;
    _practice
      ..stop()
      ..reset();
    _step.value = null;
    _immersion.exit();
    setState(() => _stage = YogaStage.ready);
  }

  @override
  Widget build(BuildContext context) {
    // The app's existing reduced-motion convention, as used by
    // Meditation's orb and the Environment's sky.
    final still = MediaQuery.disableAnimationsOf(context);

    if (_stage.isImmersive) {
      return _Practising(
        practice: _practice,
        step: _step,
        secondsLeft: _secondsLeft,
        momentNow: _momentNow,
        still: still,
        onEnd: _endPractice,
      );
    }

    return AppScaffold(
      title: 'Yoga',
      // Which practice you are in, said once, where every screen in the
      // app says that sort of thing.
      subtitle: _chosen?.name,
      trailing: const AlmanacButton(),
      body: [
        switch (_stage) {
          YogaStage.choosingPractice => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // One Almanac: the same day Cycle Syncing is looking at.
              // Above the usual choices, and it changes none of them.
              _CycleContext(
                arrivedFor: _arrivedForPhase,
                onChoose: _choosePractice,
              ),
              PracticeChooser(onChosen: _choosePractice),
            ],
          ),
          YogaStage.finished => _Finished(
            practice: _chosen!,
            onBeginAgain: _start,
            onChooseAnother: _backToPractices,
          ),
          _ => _Ready(
            practice: _chosen!,
            onStart: _start,
            onChangePractice: _backToPractices,
          ),
        },
      ],
    );
  }
}

/// A practice chosen, and a Start control.
class _Ready extends StatelessWidget {
  const _Ready({
    required this.practice,
    required this.onStart,
    required this.onChangePractice,
  });

  final YogaPractice practice;
  final VoidCallback onStart;
  final VoidCallback onChangePractice;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        // The first movement, so it is clear what you are about to do.
        PoseFigure(
          shape: practice.sequence.first.shape,
          side: practice.sequence.first.side,
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          practice.description,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${practice.approximateMinutes} minutes, '
          '${practice.sequence.length} movements',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),

        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(label: 'Start', onPressed: onStart),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: onChangePractice,
          child: const Text('Choose a different practice'),
        ),
      ],
    );
  }
}

/// Moving.
///
/// The figure, then the words, then one quiet way out. No title, no
/// navigation bar, nothing to press by accident.
class _Practising extends StatelessWidget {
  const _Practising({
    required this.practice,
    required this.step,
    required this.secondsLeft,
    required this.momentNow,
    required this.still,
    required this.onEnd,
  });

  final AnimationController practice;
  final ValueListenable<YogaMoment?> step;
  final ValueListenable<int> secondsLeft;
  final YogaMoment Function() momentNow;
  final bool still;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Scrollable, so a long instruction at a large text size has
        // somewhere to go rather than being clipped.
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimens.maxContentWidth,
              ),
              child: ValueListenableBuilder<YogaMoment?>(
                valueListenable: step,
                builder: (context, moment, _) {
                  if (moment == null) return const SizedBox.shrink();

                  return Column(
                    children: [
                      _Figure(
                        practice: practice,
                        moment: moment,
                        momentNow: momentNow,
                        still: still,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      ValueListenableBuilder<int>(
                        valueListenable: secondsLeft,
                        // Once a second, not once a frame — and reading
                        // the clock again rather than reusing the moment
                        // above, whose position within the movement was
                        // frozen at the step boundary. The breath cue
                        // moves *inside* a movement, and its phases turn
                        // on whole seconds, so this is exactly often
                        // enough to catch them.
                        builder: (context, seconds, _) => StepGuidance(
                          moment: momentNow(),
                          secondsRemaining: seconds,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),
                      // Clear, and the quietest thing on the screen.
                      TextButton(
                        onPressed: onEnd,
                        child: const Text('End practice'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The pose, drawn.
///
/// Rebuilt every frame only for the movements that flow with the breath,
/// and only when the device has not asked for less motion — so a held
/// pose does not repaint sixty times a second to draw a figure that is
/// not moving.
class _Figure extends StatelessWidget {
  const _Figure({
    required this.practice,
    required this.moment,
    required this.momentNow,
    required this.still,
  });

  final AnimationController practice;
  final YogaMoment moment;
  final YogaMoment Function() momentNow;
  final bool still;

  @override
  Widget build(BuildContext context) {
    // A held pose has no breath to follow, and a device asking for less
    // motion should not get any.
    if (still || moment.openness == null) {
      return PoseFigure(shape: moment.shape, side: moment.side);
    }

    return AnimatedBuilder(
      animation: practice,
      builder: (context, _) {
        final now = momentNow();
        return PoseFigure(
          shape: now.shape,
          side: now.side,
          openness: now.openness,
        );
      },
    );
  }
}

/// The end. A few words and two ways on.
class _Finished extends StatelessWidget {
  const _Finished({
    required this.practice,
    required this.onBeginAgain,
    required this.onChooseAnother,
  });

  final YogaPractice practice;
  final VoidCallback onBeginAgain;
  final VoidCallback onChooseAnother;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        // Lying down, whichever practice it was: the end of one is a
        // good time to stay still for a moment.
        const PoseFigure(shape: PoseShape.lying),
        const SizedBox(height: AppSpacing.xl),

        Semantics(
          container: true,
          liveRegion: true,
          child: Text('Practice complete.', style: textTheme.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          practice.name,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),

        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(label: 'Begin again', onPressed: onBeginAgain),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: onChooseAnother,
          child: const Text('Choose another practice'),
        ),
      ],
    );
  }
}

/// The cycle phase, and the practice that suits it.
///
/// Reads the phase from the app's shared seam — the same one the
/// Cookbook and Meditation read — so Yoga never imports Cycle and never
/// learns anything about bleeding.
///
/// [arrivedFor] is the phase the user travelled with, when they came
/// through Cycle Syncing's door. When it is null they opened Yoga
/// normally: the same suggestion appears under a quieter heading if
/// there is a phase to answer for, and nothing at all if there is not.
class _CycleContext extends ConsumerWidget {
  const _CycleContext({required this.arrivedFor, required this.onChoose});

  final CyclePhase? arrivedFor;
  final ValueChanged<YogaPractice> onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(almanacCyclePhaseProvider(arrivedFor));
    // No Cycle in the Almanac, or nothing for it to say.
    if (phase == null) return const SizedBox.shrink();

    return CycleContextCard(
      heading: arrivedFor == null
          ? YogaText.forToday
          : CycleYogaIntent(arrivedFor!).heading,
      suggestion: CycleYoga.forPhase(phase),
      onBegin: () => onChoose(CycleYoga.practiceFor(phase)),
    );
  }
}

/// The one contextual heading Yoga adds.
abstract final class YogaText {
  /// Shown when Yoga was opened normally rather than through a doorway.
  /// It mentions today; it does not announce it.
  static const forToday = 'For today';
}
