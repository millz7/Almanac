/// The stable identity of every part of the app a user can have.
///
/// The name is what gets written to disk, so **these names must not
/// change**: renaming a value would silently drop that feature from the
/// Almanac of everybody who had chosen it. The user-facing wording lives
/// in `FeatureDefinition` and is free to change without touching this.
enum FeatureId {
  /// The living Almanac — season, sky, sun and moon. Always present, and
  /// the only one the user cannot remove.
  environment,

  meditation,
  yoga,
  chakras,
  cycle,
  cookbook,
  garden,
  natureLog;

  /// Reads an id back from storage, returning null for anything
  /// unrecognised.
  ///
  /// Unrecognised rather than throwing, because a value could come from a
  /// newer version of the app that has since been downgraded, or from a
  /// feature that was removed. Dropping it quietly is better than
  /// refusing to start.
  static FeatureId? tryParse(String stored) {
    for (final id in FeatureId.values) {
      if (id.name == stored) return id;
    }
    return null;
  }
}
