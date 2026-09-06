import 'package:flutter/foundation.dart';

import 'breathing_pattern.dart';

export 'breathing_pattern.dart';

/// The stable identity of a practice. Not persisted anywhere, but named
/// rather than positional so tests and code read the same way.
enum TechniqueId { focus, sleep, balance, releaseTension }

/// One way to breathe: a name, a line about it, and the rhythm itself.
@immutable
class MeditationTechnique {
  const MeditationTechnique({
    required this.id,
    required this.name,
    required this.description,
    required this.pattern,
  });

  final TechniqueId id;
  final String name;

  /// One short line, to help someone choose. Not a lesson.
  final String description;

  final BreathingPattern pattern;

  @override
  String toString() => 'MeditationTechnique($name)';
}

/// The four practices.
///
/// Four doors into the same quiet room. Adding a fifth is an entry here
/// and nothing else: the screen reads the pattern through
/// [BreathingPattern.momentAt] and never asks which technique it is.
///
/// None of these descriptions claims a medical or therapeutic effect.
/// They say what the breathing is, and what it is traditionally used for.
abstract final class MeditationTechniques {
  /// Square breathing: equal in, hold, out.
  static const focus = MeditationTechnique(
    id: TechniqueId.focus,
    name: 'Focus',
    description: 'Square breathing for steady attention.',
    pattern: BreathingPattern(
      steps: [
        BreathingStep(
          phase: BreathingPhase.inhale,
          duration: Duration(seconds: 4),
          instruction: 'Breathe in',
        ),
        BreathingStep(
          phase: BreathingPhase.hold,
          duration: Duration(seconds: 4),
          instruction: 'Hold',
        ),
        BreathingStep(
          phase: BreathingPhase.exhale,
          duration: Duration(seconds: 4),
          instruction: 'Breathe out',
        ),
      ],
    ),
  );

  /// 4-7-8: a long hold and a longer out-breath.
  static const sleep = MeditationTechnique(
    id: TechniqueId.sleep,
    name: 'Sleep',
    description: 'Four in, seven held, eight out — for settling at night.',
    pattern: BreathingPattern(
      steps: [
        BreathingStep(
          phase: BreathingPhase.inhale,
          duration: Duration(seconds: 4),
          instruction: 'Breathe in',
        ),
        BreathingStep(
          phase: BreathingPhase.hold,
          duration: Duration(seconds: 7),
          instruction: 'Hold',
        ),
        BreathingStep(
          phase: BreathingPhase.exhale,
          duration: Duration(seconds: 8),
          instruction: 'Breathe out',
        ),
      ],
    ),
  );

  /// Alternate-nostril breathing.
  ///
  /// A full cycle is both sides: in on the left, hold, out on the right,
  /// then in on the right, hold, out on the left. The hold is counted
  /// down, because the count is part of the practice rather than a
  /// progress readout.
  ///
  /// The four-second holds come from the practice. The in- and
  /// out-breaths are given four and six seconds — "until the lungs are
  /// empty" needs a length to animate to, and a slightly longer out than
  /// in is the usual advice.
  static const balance = MeditationTechnique(
    id: TechniqueId.balance,
    name: 'Balance',
    description: 'Alternate nostrils, evenly, side to side.',
    pattern: BreathingPattern(
      steps: [
        BreathingStep(
          phase: BreathingPhase.inhale,
          duration: Duration(seconds: 4),
          instruction: 'Inhale through the left nostril',
          nostril: Nostril.left,
          saysSeconds: false,
        ),
        BreathingStep(
          phase: BreathingPhase.hold,
          duration: Duration(seconds: 4),
          instruction: 'Hold with both nostrils closed',
          nostril: Nostril.both,
          counted: true,
        ),
        BreathingStep(
          phase: BreathingPhase.exhale,
          duration: Duration(seconds: 6),
          instruction: 'Exhale through the right nostril',
          nostril: Nostril.right,
          saysSeconds: false,
        ),
        BreathingStep(
          phase: BreathingPhase.inhale,
          duration: Duration(seconds: 4),
          instruction: 'Inhale through the right nostril',
          nostril: Nostril.right,
          saysSeconds: false,
        ),
        BreathingStep(
          phase: BreathingPhase.hold,
          duration: Duration(seconds: 4),
          instruction: 'Hold with both nostrils closed',
          nostril: Nostril.both,
          counted: true,
        ),
        BreathingStep(
          phase: BreathingPhase.exhale,
          duration: Duration(seconds: 6),
          instruction: 'Exhale through the left nostril',
          nostril: Nostril.left,
          saysSeconds: false,
        ),
      ],
    ),
  );

  /// A deep breath in through the nose, and a long open sigh out.
  ///
  /// The sound is the user's, not the app's: nothing here plays audio and
  /// nothing listens.
  static const releaseTension = MeditationTechnique(
    id: TechniqueId.releaseTension,
    name: 'Release Tension',
    description: 'A deep breath in, and a long open sigh out.',
    pattern: BreathingPattern(
      steps: [
        BreathingStep(
          phase: BreathingPhase.inhale,
          duration: Duration(seconds: 4),
          instruction: 'Deep inhale through the nose',
          saysSeconds: false,
        ),
        BreathingStep(
          phase: BreathingPhase.exhale,
          duration: Duration(seconds: 6),
          instruction: 'Exhale through the mouth with a haa sound, tongue out',
          saysSeconds: false,
        ),
      ],
    ),
  );

  /// In the order they are offered.
  static const all = <MeditationTechnique>[
    focus,
    sleep,
    balance,
    releaseTension,
  ];

  static MeditationTechnique byId(TechniqueId id) =>
      all.firstWhere((technique) => technique.id == id);
}

/// How long a session lasts, in whole minutes.
///
/// Four is the recommendation and the default — long enough to settle,
/// short enough to actually do. The range is wide enough to be useful and
/// narrow enough not to need a picker.
const kDefaultSessionMinutes = 4;
const kMinSessionMinutes = 2;
const kMaxSessionMinutes = 20;

/// The quiet second between tapping the orb and the first breath.
///
/// Deliberate: the interface disappears, and there is a moment of
/// nothing at all before anyone is asked to breathe.
const kSettlingPause = Duration(seconds: 1);
