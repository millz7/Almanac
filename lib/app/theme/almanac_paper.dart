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
  /// The paper itself. Warm, slightly yellowed, and never anything else.
  static const ground = Color(0xFFF7F1E3);

  /// Ink. Warm near-black rather than pure black, which on cream reads
  /// as printing rather than as a screen.
  static const ink = Color(0xFF2B2720);

  /// A quieter ink, for captions and secondary lines. Dark enough to
  /// clear the body-text floor on the ground above, not merely the
  /// graphical one.
  static const inkMuted = Color(0xFF574F42);

  /// The hairline a section rule is drawn in.
  static const rule = Color(0xFF9A9080);

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
    // The one raised surface a paper page has: a shade whiter, as if a
    // second sheet were laid on the first.
    surfaceElevated: const Color(0xFFFDF9F0),
    textPrimary: ink,
    textSecondary: inkMuted,
    border: rule,
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
