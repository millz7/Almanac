import 'package:flutter/foundation.dart';

/// What the breath is doing, which is what the orb's size follows.
///
/// Deliberately only three: bigger, still, smaller. Everything else a
/// technique needs to say — which nostril, what to do with your mouth —
/// belongs to the step, not to this.
enum BreathingPhase { inhale, hold, exhale }

/// Which side of the nose a step uses.
///
/// Only alternate-nostril breathing needs this, which is why it is
/// optional — but it is real information, not decoration, so it lives in
/// the model rather than being buried in a sentence the UI has to parse.
enum Nostril {
  left('left'),
  right('right'),
  both('both');

  const Nostril(this.label);

  final String label;
}

/// One part of a breath: how long it lasts and what to do during it.
@immutable
class BreathingStep {
  const BreathingStep({
    required this.phase,
    required this.duration,
    required this.instruction,
    this.nostril,
    this.counted = false,
    this.saysSeconds = true,
  });

  final BreathingPhase phase;
  final Duration duration;

  /// What to do, in the technique's own words: "Breathe in", "Inhale
  /// through the left nostril", "Exhale through the mouth with a haa
  /// sound, tongue out".
  ///
  /// Per step rather than per phase, because an inhale does not mean the
  /// same thing in every technique.
  final String instruction;

  /// The side of the nose this step uses, for techniques that alternate.
  final Nostril? nostril;

  /// Whether the seconds should be counted down while this step runs.
  ///
  /// True for alternate-nostril breathing's hold, where the count is part
  /// of the practice rather than a progress readout.
  final bool counted;

  /// Whether [spokenInstruction] should say how long the step lasts.
  ///
  /// True where the timing is the instruction ("Hold, 7 seconds") and
  /// false where the step is described by its action rather than its
  /// length ("Inhale through the left nostril") — reading a duration out
  /// after one of those makes it sound like a stopwatch.
  final bool saysSeconds;

  /// What a screen reader hears. Built from the duration rather than
  /// written out, so a change to the timing cannot leave the words lying.
  String get spokenInstruction =>
      saysSeconds ? '$instruction, ${duration.inSeconds} seconds' : instruction;

  @override
  bool operator ==(Object other) =>
      other is BreathingStep &&
      other.phase == phase &&
      other.duration == duration &&
      other.instruction == instruction &&
      other.nostril == nostril &&
      other.counted == counted &&
      other.saysSeconds == saysSeconds;

  @override
  int get hashCode =>
      Object.hash(phase, duration, instruction, nostril, counted, saysSeconds);

  @override
  String toString() =>
      'BreathingStep(${phase.name}, ${duration.inMilliseconds}ms, '
      '"$instruction"${nostril == null ? '' : ', ${nostril!.label}'})';
}

/// A rhythm to breathe to: an ordered list of steps that repeats.
///
/// Deliberately data rather than behaviour, and deliberately the only
/// place the timings live. The screen asks the pattern what is happening
/// at a given moment; it does not know that Focus is a square or that
/// Balance changes sides, so adding another technique later does not mean
/// touching the breathing screen.
@immutable
class BreathingPattern {
  const BreathingPattern({required this.steps});

  final List<BreathingStep> steps;

  /// How long one full cycle takes. For Balance that is both sides.
  Duration get cycleLength =>
      steps.fold(Duration.zero, (total, step) => total + step.duration);

  /// What is happening [elapsed] into a session.
  ///
  /// A pure function of the elapsed time: the same instant always gives
  /// the same answer, however the caller arrived at it. That is what lets
  /// the orb and the words come from one source and never disagree, and
  /// what makes a whole practice testable without a widget.
  BreathingMoment momentAt(Duration elapsed) {
    assert(steps.isNotEmpty, 'a pattern needs at least one step');
    final cycle = cycleLength;
    // Negative elapsed would mean a caller has done something odd; treat
    // it as the very start rather than reflecting it into the middle of a
    // breath.
    final within = elapsed.isNegative
        ? Duration.zero
        : Duration(microseconds: elapsed.inMicroseconds % cycle.inMicroseconds);

    var start = Duration.zero;
    for (var index = 0; index < steps.length; index++) {
      final step = steps[index];
      final end = start + step.duration;
      if (within < end || index == steps.length - 1) {
        return BreathingMoment(
          step: step,
          stepIndex: index,
          elapsedInStep: within - start,
        );
      }
      start = end;
    }
    // Unreachable: the loop always returns on the last step.
    throw StateError('pattern has no steps');
  }
}

/// Where a breath has got to at one instant.
///
/// The whole of what the presentation needs, and the only thing it reads.
/// A screen holding one of these does not know which technique produced
/// it.
@immutable
class BreathingMoment {
  const BreathingMoment({
    required this.step,
    required this.stepIndex,
    required this.elapsedInStep,
  });

  final BreathingStep step;

  /// Which step of the cycle this is. Carried so the presentation can
  /// tell one step from another when two of them read alike — Balance
  /// holds twice a cycle, and the second hold is a different moment from
  /// the first.
  final int stepIndex;

  final Duration elapsedInStep;

  BreathingPhase get phase => step.phase;
  Duration get stepLength => step.duration;
  String get instruction => step.instruction;
  String get spokenInstruction => step.spokenInstruction;
  Nostril? get nostril => step.nostril;

  /// How far through this step, 0.0 to 1.0.
  double get progress => stepLength.inMicroseconds <= 0
      ? 1
      : (elapsedInStep.inMicroseconds / stepLength.inMicroseconds).clamp(
          0.0,
          1.0,
        );

  /// How open the breath is: 0.0 fully out, 1.0 fully in.
  ///
  /// The quantity the orb's size is drawn from, kept here rather than in
  /// the widget so the shape of the breath is testable. It is
  /// deliberately *linear* — the easing that makes it feel like breathing
  /// rather than like a machine is presentation, and belongs with the
  /// drawing.
  double get openness => switch (phase) {
    BreathingPhase.inhale => progress,
    BreathingPhase.hold => 1,
    BreathingPhase.exhale => 1 - progress,
  };

  /// Whole seconds remaining in this step, rounded up. Never zero while
  /// the step is still running.
  int get secondsRemaining {
    final remaining = stepLength - elapsedInStep;
    if (remaining <= Duration.zero) return 0;
    return (remaining.inMilliseconds / 1000).ceil();
  }

  /// The number to show while a counted step runs — 4, 3, 2, 1 — or null
  /// when this step is not counted.
  int? get countdown => step.counted ? secondsRemaining : null;

  @override
  bool operator ==(Object other) =>
      other is BreathingMoment &&
      other.step == step &&
      other.stepIndex == stepIndex &&
      other.elapsedInStep == elapsedInStep;

  @override
  int get hashCode => Object.hash(step, stepIndex, elapsedInStep);

  @override
  String toString() =>
      'BreathingMoment(${phase.name} #$stepIndex, '
      '${(progress * 100).round()}%)';
}
