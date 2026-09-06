import 'package:flutter/foundation.dart';

/// One part of a breath.
enum BreathingPhase {
  inhale('Breathe in'),
  hold('Hold'),
  exhale('Breathe out');

  const BreathingPhase(this.instruction);

  /// What the screen says, and what a screen reader announces, while this
  /// phase is running.
  final String instruction;
}

/// One phase of a pattern, and how long it lasts.
@immutable
class BreathingStep {
  const BreathingStep(this.phase, this.duration);

  final BreathingPhase phase;
  final Duration duration;

  @override
  bool operator ==(Object other) =>
      other is BreathingStep &&
      other.phase == phase &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(phase, duration);

  @override
  String toString() =>
      'BreathingStep(${phase.name}, ${duration.inMilliseconds}ms)';
}

/// A rhythm to breathe to: an ordered list of phases that repeats.
///
/// Deliberately data rather than behaviour, and deliberately the only
/// place the timings live. The screen asks the pattern what is happening
/// at a given moment; it does not know that a breath is four seconds
/// long, so changing the rhythm later — or adding a second one — does not
/// mean rewriting the screen.
@immutable
class BreathingPattern {
  const BreathingPattern({required this.name, required this.steps});

  final String name;
  final List<BreathingStep> steps;

  /// How long one full breath takes.
  Duration get cycleLength =>
      steps.fold(Duration.zero, (total, step) => total + step.duration);

  /// What is happening [elapsed] into a session.
  ///
  /// A pure function of the elapsed time: the same instant always gives
  /// the same answer, however the caller arrived at it. That is what lets
  /// the animation and the words come from one source and never disagree,
  /// and what makes the whole rhythm testable without a widget.
  BreathingMoment momentAt(Duration elapsed) {
    assert(steps.isNotEmpty, 'a pattern needs at least one phase');
    final cycle = cycleLength;
    // Negative elapsed would mean a caller has done something odd; treat
    // it as the very start rather than reflecting it into the middle of a
    // breath.
    final within = elapsed.isNegative
        ? Duration.zero
        : Duration(microseconds: elapsed.inMicroseconds % cycle.inMicroseconds);

    var start = Duration.zero;
    for (final step in steps) {
      final end = start + step.duration;
      if (within < end || step == steps.last) {
        final into = within - start;
        return BreathingMoment(
          phase: step.phase,
          elapsedInPhase: into,
          phaseLength: step.duration,
        );
      }
      start = end;
    }
    // Unreachable: the loop always returns on the last step.
    throw StateError('pattern has no steps');
  }
}

/// Where a breath has got to at one instant.
@immutable
class BreathingMoment {
  const BreathingMoment({
    required this.phase,
    required this.elapsedInPhase,
    required this.phaseLength,
  });

  final BreathingPhase phase;
  final Duration elapsedInPhase;

  /// How long this phase lasts in total. Carried so the screen can say
  /// "Breathe in, 4 seconds" without consulting the pattern again.
  final Duration phaseLength;

  /// How far through this phase, 0.0 to 1.0.
  double get progress => phaseLength.inMicroseconds <= 0
      ? 1
      : (elapsedInPhase.inMicroseconds / phaseLength.inMicroseconds).clamp(
          0.0,
          1.0,
        );

  /// How open the breath is: 0.0 fully out, 1.0 fully in.
  ///
  /// The quantity the circle is drawn from, kept here rather than in the
  /// widget so the shape of the breath is testable. It is deliberately
  /// *linear* — the easing that makes it feel like breathing rather than
  /// like a machine is presentation, and belongs with the drawing.
  double get openness => switch (phase) {
    BreathingPhase.inhale => progress,
    BreathingPhase.hold => 1,
    BreathingPhase.exhale => 1 - progress,
  };

  /// Whole seconds remaining in this phase, rounded up, for the spoken
  /// label. Never zero while the phase is still running.
  int get secondsRemaining {
    final remaining = phaseLength - elapsedInPhase;
    if (remaining <= Duration.zero) return 0;
    return (remaining.inMilliseconds / 1000).ceil();
  }

  @override
  bool operator ==(Object other) =>
      other is BreathingMoment &&
      other.phase == phase &&
      other.elapsedInPhase == elapsedInPhase &&
      other.phaseLength == phaseLength;

  @override
  int get hashCode => Object.hash(phase, elapsedInPhase, phaseLength);

  @override
  String toString() =>
      'BreathingMoment(${phase.name}, ${(progress * 100).round()}%)';
}

/// The app's breathing rhythm.
///
/// A longer out-breath than in-breath, which is the part that actually
/// settles you, with a short pause at the top. Twelve seconds a breath.
/// One pattern, on purpose: this is somewhere to sit for two minutes, not
/// something to configure.
const kAlmanacBreath = BreathingPattern(
  name: 'Almanac breath',
  steps: [
    BreathingStep(BreathingPhase.inhale, Duration(seconds: 4)),
    BreathingStep(BreathingPhase.hold, Duration(seconds: 2)),
    BreathingStep(BreathingPhase.exhale, Duration(seconds: 6)),
  ],
);

/// How long a session lasts.
///
/// Two minutes, which is exactly ten breaths of [kAlmanacBreath] — so a
/// session ends at the end of an out-breath rather than halfway through
/// one.
const kMeditationSessionLength = Duration(minutes: 2);
