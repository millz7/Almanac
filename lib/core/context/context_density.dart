/// The Almanac's one presentation rule for contextual suggestions:
/// **context is shown only when it adds something.**
///
/// A screen that can say something about today from several independent
/// directions — the moon, a cycle phase, a festival, the weather — must
/// not stack a card for each one merely because the data exists. The
/// most ambient context (weather, today) yields when it would only
/// repeat a practice something more specific has already suggested, or
/// when the screen already carries as many suggestions as it can hold
/// without burying its own core choices.
///
/// Deliberately a rule, not a ranking system: two plain checks, no
/// scoring, no learning, and the same answer every time for the same
/// day. See `docs/almanac_visual_language.md`.
abstract final class ContextDensity {
  /// Whether a further suggestion of [candidate] earns its place beneath
  /// [alreadyShown].
  ///
  /// False when it repeats something already on screen, or when [limit]
  /// suggestions are already showing.
  static bool admits<T>({
    required T candidate,
    required List<T> alreadyShown,
    required int limit,
  }) => alreadyShown.length < limit && !alreadyShown.contains(candidate);
}
