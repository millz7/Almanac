import 'package:flutter/material.dart';

import '../../core/environment/season.dart';
import 'colour_contrast.dart';
import 'seasonal_palettes.dart';

/// Illustration tokens for showing one season while standing in another.
///
/// Almost everything in the app is dressed in the season the user is
/// actually in, which is what [SeasonalPalette] is for. The Cookbook is
/// the first screen that shows all four at once: a winter recipe card in
/// midsummer should still feel like winter. These two tokens are how it
/// does that without any widget knowing a hex value or branching on a
/// season.
///
/// Both are derived from the same eight designed palettes, so the four
/// seasons stay in the same family as the rest of the app, and both are
/// checked for contrast by construction — see
/// `season_illustration_test.dart`, which holds the floors across every
/// active palette and every season.
///
/// The season's own palette is taken at the *active* palette's time of
/// day, so a card is lit the same way the page around it is.
SeasonalPalette paletteForSeason(SeasonalPalette active, Season season) =>
    SeasonalPalettes.resolve(
      season: season,
      daylight: active.brightness == Brightness.light ? 1 : 0,
    );

/// The strongest wash allowed: enough for a card to read as its season,
/// not so much that it stops looking like this app.
const _maxWash = 0.34;

/// A soft ground for a card belonging to [season].
///
/// The active surface, tinted towards the season's own gentlest colour.
/// The tint backs off in steps until body text on it clears 4.5:1, so a
/// card can never end up prettier than it is readable — and in the worst
/// case it is simply the ordinary card colour.
Color seasonWash(SeasonalPalette active, Season season) {
  final tint = paletteForSeason(active, season).primarySoft;

  for (var strength = _maxWash; strength > 0; strength -= 0.02) {
    final wash = Color.lerp(active.surface, tint, strength)!;
    if (contrastRatio(active.textPrimary, wash) >= kBodyTextContrast) {
      return wash;
    }
  }

  return active.surface;
}

/// The colour to draw a season's small botanical mark in, on
/// [seasonWash].
///
/// Decorative — the season is always written out in words beside it — but
/// still held to the 3:1 graphical-object bar, because a mark nobody can
/// make out is just noise.
Color seasonInk(SeasonalPalette active, Season season) => legibleOn(
  paletteForSeason(active, season).primary,
  seasonWash(active, season),
);
