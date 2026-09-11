import 'package:flutter/material.dart';

import 'colour_contrast.dart';
import 'seasonal_palette.dart';

/// The paper the Almanac's inner pages are printed on.
///
/// **The Environment changes with the world outside. The pages inside
/// the Almanac remain paper.**
///
/// This is the one place that colour is written down. It is a fixed warm
/// cream — the same in spring, summer, autumn and winter, and the same
/// at midday and at midnight — because opening a detail page should feel
/// like turning to a page of a physical almanac, not like stepping
/// outside again. A night version of this paper would be a different
/// book.
///
/// The Environment screen is the living painting and still responds
/// fully to season, sun and sky. Nothing here touches it.
///
/// Small contextual accents may still come from the active
/// [SeasonalPalette] — see [accentOn], which re-bases a seasonal colour
/// so it stays legible on cream even when it came from a night palette.
///
/// See `docs/almanac_visual_language.md`.
abstract final class AlmanacPaper {
  // ── Ground ────────────────────────────────────────────────────────
  //
  // Two grounds, not five. Every extra cream is a decision somebody has
  // to make on every page, and the answer to "which cream?" should
  // almost always be "the paper".

  /// The paper itself. Warm, slightly yellowed, and never anything else.
  /// The default background of every inner page.
  static const ground = Color(0xFFF7F1E3);

  /// The one inset ground: a passage tinted very slightly *into* the
  /// paper, the way a printed panel sits on a page rather than floating
  /// above it. For grouping that genuinely aids comprehension — never
  /// for decoration, and never with a shadow.
  ///
  /// Deliberately darker than [ground] rather than lighter. A lighter
  /// patch reads as a card hovering over the page; a darker one reads as
  /// ink laid on it.
  static const groundInset = Color(0xFFF0E9D8);

  // ── Ink ───────────────────────────────────────────────────────────
  //
  // Three weights of ink and no pure black anywhere. Each is measured
  // against [ground]: see `paper_tokens_test.dart`, which fails if any
  // of them drifts below the contrast its role needs.

  /// Ink. Warm near-black rather than pure black, which on cream reads
  /// as printing rather than as a screen. Titles and body copy.
  static const ink = Color(0xFF2B2720);

  /// A quieter ink, for captions, section labels and secondary lines.
  /// Dark enough to clear the body-text floor on the ground above, not
  /// merely the graphical one.
  static const inkMuted = Color(0xFF574F42);

  /// The faintest ink that is still real text: annotations, units, the
  /// small print under a value. Clears the body floor (4.5:1) — "faint"
  /// is about hierarchy, never about being hard to read.
  static const inkFaint = Color(0xFF6B6253);

  /// Ink for a control that cannot be used. Legible enough to read,
  /// clearly too light to press — and never the only signal that
  /// something is disabled.
  static const inkDisabled = Color(0xFF8A8070);

  // ── Rules ─────────────────────────────────────────────────────────

  /// The hairline a section rule is drawn in — and the boundary of a
  /// control that has one.
  ///
  /// Measured, not eyeballed: a line the reader has to *see* clears the
  /// 3:1 graphical floor, on the paper and on the inset ground alike.
  /// The previous value looked right and reached 2.79:1.
  static const rule = Color(0xFF8A8070);

  /// A quieter hairline, for a division that is felt more than seen —
  /// between the rows of a list, or under a line of a table. Decorative
  /// by definition: anything that must be *perceived* uses [rule].
  static const softRule = Color(0xFFD8CEB8);

  /// The wash behind a selected or focused element, under text that
  /// keeps its own ink. A tint of the paper rather than a colour laid
  /// over it, so selection never has to carry contrast on its own —
  /// there is always a second, non-colour signal beside it.
  static const selection = Color(0xFFE8DFC6);

  /// A seasonal colour, made safe to use on paper.
  ///
  /// A page keeps its contextual accent — the season is still present in
  /// a small way — but a palette's accent was chosen to sit on that
  /// palette's own ground, and a winter night's primary on cream would
  /// be a pale smudge. This steps the lightness until it clears the
  /// floor, giving up as little of the hue as the paper demands.
  static Color accentOn(Color seasonal) =>
      legibleOn(seasonal, ground, minimum: kGraphicalContrast);

  /// The active palette, re-printed on paper.
  ///
  /// Everything that describes a surface or a piece of text becomes a
  /// paper token; everything that carries the season — primary,
  /// secondary, accent, water, earth — is kept and re-based for
  /// legibility. Handing this to `AppTheme.fromPalette` means a page's
  /// widgets go on using `Theme.of(context).textTheme` and
  /// `context.palette` exactly as they do everywhere else, and get paper
  /// without having to know about it.
  static SeasonalPalette reprint(SeasonalPalette palette) => palette.copyWith(
    // Always a light page, whatever the sky is doing. Material reads
    // this to decide what its own defaults should be.
    brightness: Brightness.light,
    background: ground,
    surface: ground,
    // The one inset surface a paper page has — tinted into the page
    // rather than floated above it. See [groundInset].
    surfaceElevated: groundInset,
    textPrimary: ink,
    textSecondary: inkMuted,
    border: rule,
    disabled: groundInset,
    onDisabled: inkDisabled,
    icon: accentOn(palette.icon),
    primary: accentOn(palette.primary),
    primarySoft: legibleOn(
      palette.primarySoft,
      ground,
      // A soft fill sits behind text rather than being read itself, so
      // it only has to be distinguishable from the paper.
      minimum: 1.2,
    ),
    onPrimarySoft: ink,
    secondary: accentOn(palette.secondary),
    accent: accentOn(palette.accent),
    water: accentOn(palette.water),
    earth: accentOn(palette.earth),
    error: accentOn(palette.error),
  );
}
