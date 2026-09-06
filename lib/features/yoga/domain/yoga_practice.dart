import 'package:flutter/foundation.dart';

import '../../meditation/domain/breathing_pattern.dart';

export '../../meditation/domain/breathing_pattern.dart'
    show BreathingPattern, BreathingStep, BreathingPhase;

/// Which way round an asymmetric pose is done.
///
/// A pose with a side always appears twice in a sequence, once each way.
enum BodySide {
  left('left'),
  right('right');

  const BodySide(this.label);

  final String label;
}

/// The shape a step is, for drawing.
///
/// A small vocabulary rather than one entry per pose: several poses share
/// a shape, and the point is to show the general form of the body, not to
/// be an illustration. See `PoseFigure`.
enum PoseShape {
  /// Sitting, however is comfortable.
  seated,

  /// Standing tall.
  standing,

  /// Folded forward from the hips.
  folded,

  /// On hands and knees, spine rounding and lengthening.
  allFours,

  /// Curled forward, hips to heels.
  curled,

  /// Sitting or standing, leaning to one side.
  sideBend,

  /// One foot forward, the back knee down.
  lunge,

  /// Sitting, turned gently to one side.
  twist,

  /// Lying down.
  lying,
}

/// One movement in a practice.
@immutable
class YogaStep {
  const YogaStep({
    required this.pose,
    required this.duration,
    required this.instruction,
    required this.shape,
    this.side,
    this.breathing,
    this.breathNote,
  }) : assert(
         breathing == null || breathNote == null,
         'a step is either paced by a rhythm or described in words',
       );

  /// What this movement is called: "Cat cow", "Child's pose".
  final String pose;

  final Duration duration;

  /// What to do, in plain words, assuming no experience. Never a claim
  /// about what a pose does to anybody.
  final String instruction;

  final PoseShape shape;

  /// Which way round, for the poses that have a side.
  final BodySide? side;

  /// A rhythm to breathe to, for the steps where the breath *is* the
  /// movement.
  ///
  /// This is Meditation's own [BreathingPattern], not a second engine:
  /// the same `momentAt` works out which part of the breath a step is in,
  /// from the same session clock. Null for steps whose breath is a note
  /// rather than a count.
  final BreathingPattern? breathing;

  /// A few words about the breath, where a count would be too much.
  final String? breathNote;

  /// The pose and its side, as one name: "Low lunge, left".
  String get name => side == null ? pose : '$pose, ${side!.label}';

  @override
  bool operator ==(Object other) =>
      other is YogaStep &&
      other.pose == pose &&
      other.duration == duration &&
      other.instruction == instruction &&
      other.shape == shape &&
      other.side == side &&
      other.breathNote == breathNote;

  @override
  int get hashCode =>
      Object.hash(pose, duration, instruction, shape, side, breathNote);

  @override
  String toString() => 'YogaStep($name, ${duration.inSeconds}s)';
}

/// A practice: a name, a line about it, and a sequence to move through.
///
/// Data, not behaviour. Adding a fourth practice is an entry in
/// `YogaPractices` and nothing else — the screen asks the practice what
/// is happening now and never asks which one it is.
@immutable
class YogaPractice {
  const YogaPractice({
    required this.id,
    required this.name,
    required this.description,
    required this.sequence,
  });

  final YogaPracticeId id;
  final String name;

  /// One short line, to help someone choose. Not a lesson, and not a
  /// promise about what it will do for them.
  final String description;

  final List<YogaStep> sequence;

  /// How long the whole practice takes.
  Duration get length =>
      sequence.fold(Duration.zero, (total, step) => total + step.duration);

  /// Rounded to the nearest minute, for the chooser.
  int get approximateMinutes => (length.inSeconds / 60).round();

  /// What is happening [elapsed] into the practice.
  ///
  /// A pure function of the elapsed time — the same instant always gives
  /// the same answer — so the figure, the words, the step timer and the
  /// count through the sequence all come from one number and cannot
  /// disagree. Past the end it holds on the final step, which is what
  /// lets the last frame of a practice look like the last step rather
  /// than like the first.
  YogaMoment momentAt(Duration elapsed) {
    assert(sequence.isNotEmpty, 'a practice needs at least one step');
    final into = elapsed.isNegative ? Duration.zero : elapsed;

    var start = Duration.zero;
    for (var index = 0; index < sequence.length; index++) {
      final step = sequence[index];
      final end = start + step.duration;
      if (into < end || index == sequence.length - 1) {
        return YogaMoment(
          step: step,
          stepNumber: index + 1,
          totalSteps: sequence.length,
          elapsedInStep: into - start,
        );
      }
      start = end;
    }
    throw StateError('practice has no steps');
  }
}

/// The stable identity of a practice.
enum YogaPracticeId { morning, ground, unwind }

/// Where a practice has got to at one instant.
///
/// Everything the presentation needs, and the only thing it reads.
@immutable
class YogaMoment {
  const YogaMoment({
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    required this.elapsedInStep,
  });

  final YogaStep step;

  /// One-based, because it is shown to a person: "3 of 8".
  final int stepNumber;
  final int totalSteps;

  final Duration elapsedInStep;

  String get name => step.name;
  String get instruction => step.instruction;
  PoseShape get shape => step.shape;
  BodySide? get side => step.side;

  /// How long is left in this movement, never below zero.
  Duration get remainingInStep {
    final remaining = step.duration - elapsedInStep;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Whole seconds left, rounded up — what the screen shows.
  int get secondsRemaining => (remainingInStep.inMilliseconds / 1000).ceil();

  /// How far through this movement, 0.0 to 1.0.
  double get progress => step.duration.inMicroseconds <= 0
      ? 1
      : (elapsedInStep.inMicroseconds / step.duration.inMicroseconds).clamp(
          0.0,
          1.0,
        );

  /// Where the breath is, for a step that is paced by one.
  ///
  /// Uses Meditation's engine on the time already spent in this step, so
  /// there is nothing extra to keep in step with anything.
  BreathingMoment? get breath => step.breathing?.momentAt(elapsedInStep);

  /// What to say about the breath: the current phase for a paced step, or
  /// the step's own note. Null when a step says nothing about breathing.
  String? get breathCue => switch (step.breathing) {
    null => step.breathNote,
    final pattern => pattern.momentAt(elapsedInStep).instruction,
  };

  /// How open the breath is, 0–1, for a figure that moves with it. Null
  /// for steps that are held rather than flowed.
  double? get openness => breath?.openness;

  /// Everything a screen reader needs about this movement, in one line.
  ///
  /// The pose, then what to do, then the breath if there is anything to
  /// say — because the drawn figure is not information anybody can be
  /// assumed to see.
  String get spokenInstruction =>
      ['$name.', instruction, ?step.breathNote].join(' ');

  @override
  bool operator ==(Object other) =>
      other is YogaMoment &&
      other.step == step &&
      other.stepNumber == stepNumber &&
      other.totalSteps == totalSteps &&
      other.elapsedInStep == elapsedInStep;

  @override
  int get hashCode => Object.hash(step, stepNumber, totalSteps, elapsedInStep);

  @override
  String toString() =>
      'YogaMoment($name, $stepNumber of $totalSteps, '
      '${secondsRemaining}s left)';
}
