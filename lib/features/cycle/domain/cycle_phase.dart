import '../../../core/context/cycle_phase.dart';

export '../../../core/context/cycle_phase.dart' show CyclePhase;

/// What the Cycle feature adds to the shared phase vocabulary.
///
/// The word itself is shared — the Cookbook, Yoga and Meditation all
/// speak it — but how Cycle *announces* a phase is Cycle's business, and
/// the announcement is built to keep one distinction visible: the app
/// knows the dates the user recorded, and everything else here is
/// arithmetic on top of an assumed cycle length.
extension CyclePhaseWording on CyclePhase {
  /// How the phase is announced, e.g. "Approximate follicular phase".
  String get heading => 'Approximate $phrase';

  /// A short reflective line. Never a prediction about how anyone feels.
  String get reflection => switch (this) {
    CyclePhase.menstrual => 'A quieter beginning.',
    CyclePhase.follicular => 'Something is beginning to build.',
    CyclePhase.ovulatory => 'A time often associated with outward energy.',
    CyclePhase.luteal => 'A time often associated with turning inward.',
  };
}

/// The one line that has to accompany every reflection in this feature.
const kExperienceMayDiffer = 'Your experience may be different.';
