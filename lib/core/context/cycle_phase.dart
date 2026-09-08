/// The four broad phases of a menstrual cycle, as this app names them.
///
/// **Why this lives in `core/context/` rather than in the Cycle
/// feature.** Four features now speak about a phase: Cycle works one
/// out, and the Cookbook, Yoga and Meditation each answer for what they
/// would offer during it. Giving each its own copy of the word — or
/// passing a string between them — would be four vocabularies that can
/// drift. So the vocabulary is shared and typed, and the *meaning* each
/// feature attaches to it stays with that feature: Cycle owns how a
/// phase is estimated, the Cookbook owns which recipes suit one, Yoga
/// owns which practice, Meditation owns which breathing.
///
/// This carries a label and nothing else. Every phase is an
/// **approximation drawn from a calendar**, not an observation of a
/// body, and the wording that says so belongs to the feature doing the
/// saying.
enum CyclePhase {
  menstrual('Menstrual'),
  follicular('Follicular'),
  ovulatory('Ovulatory'),
  luteal('Luteal');

  const CyclePhase(this.label);

  /// One word, e.g. "Follicular".
  final String label;

  /// "menstrual phase" — the phase in the middle of a sentence.
  String get phrase => '${label.toLowerCase()} phase';

  /// Reads a phase back from storage, returning null for anything
  /// unrecognised — a value could come from a newer version of the app.
  static CyclePhase? tryParse(String stored) {
    for (final phase in CyclePhase.values) {
      if (phase.name == stored) return phase;
    }
    return null;
  }
}
