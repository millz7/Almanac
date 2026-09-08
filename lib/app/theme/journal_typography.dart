import 'package:flutter/material.dart';

/// The field-journal voice, as two typographic roles.
///
/// The Almanac should read more like somebody's notebook than a generic
/// Material app. That is a typeface decision, and this is the seam it
/// will be made behind: a page asks for `journalLabel` or `journalNote`
/// rather than assembling a [TextStyle] of its own, so when a genuine
/// hand-lettered face arrives it is these two getters that change and
/// nothing else.
///
/// **Current state, stated plainly.** Both roles are derived from the
/// editorial serif the app already carries — the warmest, most
/// hand-crafted thing in the existing typography. Choosing and shipping
/// a real handwritten face is a visual-design task, deliberately not
/// done by adding an arbitrary font dependency to satisfy a step. Fonts
/// are never downloaded at runtime.
extension AlmanacJournalText on TextTheme {
  /// A small hand-lettered-feeling label: the words above a reflective
  /// passage, the caption under an illustration.
  ///
  /// Derived from [titleLarge] because that is the serif role, then set
  /// small and lightly letter-spaced so it reads as a written note
  /// rather than a heading.
  TextStyle? get journalLabel => titleLarge?.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
    height: 1.3,
  );

  /// A reflective line, in the same serif as the headings and at reading
  /// size — the voice of a paragraph somebody wrote down rather than one
  /// an interface generated.
  TextStyle? get journalNote => titleLarge?.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );
}
