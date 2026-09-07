/// The four broad phases this feature names.
///
/// Every one of them is an **approximation drawn from a calendar**, not
/// an observation of a body. The app knows one thing for certain — the
/// dates the user recorded — and everything else here is arithmetic on
/// top of an assumed cycle length. The wording is built to keep that
/// distinction visible: [heading] says "approximate" out loud, and
/// [reflection] is offered as something often associated with a phase
/// rather than something anybody will feel.
enum CyclePhase {
  menstrual('Menstrual', 'A quieter beginning.'),
  follicular('Follicular', 'Something is beginning to build.'),
  ovulatory('Ovulatory', 'A time often associated with outward energy.'),
  luteal('Luteal', 'A time often associated with turning inward.');

  const CyclePhase(this.label, this.reflection);

  /// One word, e.g. "Follicular".
  final String label;

  /// A short reflective line. Never a prediction about how anyone feels.
  final String reflection;

  /// How the phase is announced, e.g. "Approximate follicular phase".
  String get heading => 'Approximate ${label.toLowerCase()} phase';
}

/// The one line that has to accompany every reflection in this feature.
const kExperienceMayDiffer = 'Your experience may be different.';
