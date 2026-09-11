import 'package:flutter/material.dart';

/// The Almanac's semantic typography roles.
///
/// **A screen asks for a role, never for a size.** `pageTitle`,
/// `sectionLabel`, `annotation` — not `fontSize: 14, letterSpacing: 0.8`.
/// That is what lets the whole book change voice from one place when a
/// bundled display face arrives (see `almanac_fonts.dart`), and what
/// stops eight features quietly inventing eight slightly different
/// captions.
///
/// Each role maps onto a Material [TextTheme] slot — which carries the
/// family, the colour and the scale — and then says only what makes the
/// role itself: its size relative to its neighbours, its weight, and how
/// much air it is set with. Colour is left to the caller where the role
/// can legitimately be inked two ways.
///
/// The eleven roles, and what each is for:
///
/// | Role | Where it is used |
/// |---|---|
/// | [pageTitle] | the name of a page: "The Moon", "Cycle" |
/// | [chapterTitle] | a major division within a page |
/// | [eyebrow] | the small line above a title: a date, "TODAY" |
/// | [sectionLabel] | the written label above a passage |
/// | [bodyText] | the paragraph a person reads |
/// | [bodyQuiet] | supporting copy, one step back |
/// | [annotation] | the small print under a value or an illustration |
/// | [valueText] | an astronomical or measured value: "6:48 am" |
/// | [valueLabel] | the word under a value: "Sunrise" |
/// | [controlLabel] | the words on a button or an invitation |
/// | [navigationLabel] | a destination in the bottom bar |
///
/// [journalLabel] and [journalNote] are kept as the original names of
/// [sectionLabel] and the reflective-passage voice; both are used widely
/// and both mean exactly what they say.
extension AlmanacTextRoles on TextTheme {
  // ── Titles ────────────────────────────────────────────────────────

  /// The name of a page, in the display face. Set a little tighter than
  /// Material's own display sizes because an almanac's page titles are
  /// written, not shouted.
  TextStyle? get pageTitle =>
      displaySmall?.copyWith(fontSize: 32, fontWeight: FontWeight.w500);

  /// A major division inside a page — the phase name under the moon, a
  /// recipe's name at the head of its page.
  TextStyle? get chapterTitle => headlineSmall;

  /// The small line above a title: the date on the Environment, "TODAY"
  /// over a line of guidance. Letter-spaced and quiet, so it introduces
  /// without competing.
  TextStyle? get eyebrow => labelSmall?.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
    height: 1.3,
  );

  // ── Journal voice ─────────────────────────────────────────────────

  /// A small hand-written-feeling label: the words above a reflective
  /// passage, the caption under an illustration.
  ///
  /// Derived from [titleLarge] because that is the display role, then
  /// set small and lightly letter-spaced so it reads as a written note
  /// rather than a heading.
  TextStyle? get journalLabel => titleLarge?.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
    height: 1.3,
  );

  /// The canonical name for [journalLabel] in the Step 17 system.
  TextStyle? get sectionLabel => journalLabel;

  /// A reflective line, in the same display face as the headings and at
  /// reading size — the voice of a paragraph somebody wrote down rather
  /// than one an interface generated.
  TextStyle? get journalNote => titleLarge?.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );

  // ── Reading ───────────────────────────────────────────────────────

  /// The paragraph. Never in the display face, never below 15pt, and
  /// never traded for character.
  TextStyle? get bodyText => bodyLarge;

  /// Supporting copy, one step back from [bodyText] without becoming
  /// small print.
  TextStyle? get bodyQuiet => bodyMedium;

  /// The small print: a unit, a source, the line under an illustration.
  /// Still real text at a real contrast — see `AlmanacPaper.inkFaint`.
  TextStyle? get annotation => bodySmall;

  // ── Values ────────────────────────────────────────────────────────

  /// A measured value — a time, a percentage, a cycle day. In the text
  /// face rather than the display face: a number should be read, not
  /// admired, and the reference sets its times plainly.
  TextStyle? get valueText =>
      titleMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.3);

  /// The word beneath a value: "Sunrise", "Moon". Quiet enough that the
  /// value reads first.
  TextStyle? get valueLabel =>
      bodySmall?.copyWith(fontWeight: FontWeight.w500, height: 1.3);

  // ── Controls ──────────────────────────────────────────────────────

  /// The words on a button, a chip, or a written invitation.
  TextStyle? get controlLabel => labelLarge;

  /// A destination in the bottom bar. 13pt rather than Material's 10–12:
  /// this is a primary control, and small navigation text is the thing
  /// the short labels exist to avoid.
  TextStyle? get navigationLabel => labelMedium;
}
