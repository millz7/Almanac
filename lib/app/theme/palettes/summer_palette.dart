import 'package:flutter/material.dart';

import '../seasonal_palette.dart';

/// The six supplied summer reference colours.
///
/// These come from the visual references for the app's summer identity and
/// are the foundation of the whole season: sunlight on sand, a golden
/// afternoon, terracotta earth, shallow water and deep clear ocean. They
/// are named for what they are in nature, not for their hue.
///
/// Treat these as fixed. Everything else in the summer palettes is derived
/// from them (deepened for text, lightened for surfaces).
abstract final class SummerReferenceColors {
  /// #FFF8BF — pale sunlit cream, the colour of hot sand at midday.
  static const sunlitCream = Color(0xFFFFF8BF);

  /// #FCD574 — golden afternoon sun.
  static const sun = Color(0xFFFCD574);

  /// #D28F54 — warm terracotta clay.
  static const clay = Color(0xFFD28F54);

  /// #834530 — deep sun-baked earth.
  static const earth = Color(0xFF834530);

  /// #82AE9E — shallow water over pale sand.
  static const shallowWater = Color(0xFF82AE9E);

  /// #27555A — deep clear ocean.
  static const deepWater = Color(0xFF27555A);

  /// All six, in reference order. Used by tests to assert the palette
  /// really is built on the supplied colours.
  static const all = <Color>[
    sunlitCream,
    sun,
    clay,
    earth,
    shallowWater,
    deepWater,
  ];
}

/// Summer, in daylight and at night.
///
/// The night palette is a deliberate reinterpretation rather than a dimmed
/// copy: the ground drops to deep ocean, the shallow water becomes the
/// luminous element (moonlight on water), the clay keeps its warmth and the
/// gold fades to the last light of the day.
abstract final class SummerPalettes {
  static const day = SeasonalPalette(
    name: 'Summer Day',
    brightness: Brightness.light,
    // Sunlight on sand, with cards resting on it like pale paper.
    background: SummerReferenceColors.sunlitCream,
    surface: Color(0xFFFFFCE0),
    surfaceElevated: Color(0xFFFFFEF3),
    // Deep ocean carries the primary actions.
    primary: SummerReferenceColors.deepWater,
    onPrimary: SummerReferenceColors.sunlitCream,
    primarySoft: Color(0xFFD7E5DE),
    onPrimarySoft: SummerReferenceColors.deepWater,
    // Sun-baked earth supports it.
    secondary: SummerReferenceColors.earth,
    onSecondary: SummerReferenceColors.sunlitCream,
    // The sun itself is the accent — used sparingly.
    accent: SummerReferenceColors.sun,
    onAccent: Color(0xFF3A2016),
    // Text is a deepened version of the earth tone, so it reads warm.
    textPrimary: Color(0xFF3A2016),
    textSecondary: Color(0xFF6B5140),
    border: Color(0xFFA9803F),
    icon: SummerReferenceColors.deepWater,
    water: SummerReferenceColors.shallowWater,
    earth: SummerReferenceColors.clay,
    disabled: Color(0xFFEFE3B4),
    onDisabled: Color(0xFF8A7355),
    error: Color(0xFFA8442A),
    onError: SummerReferenceColors.sunlitCream,
  );

  static const night = SeasonalPalette(
    name: 'Summer Night',
    brightness: Brightness.dark,
    // Deep water at night — dark, but never pure black.
    background: Color(0xFF0E2124),
    surface: Color(0xFF142E32),
    surfaceElevated: Color(0xFF1B3A3F),
    // Moonlight on shallow water becomes the brightest structural colour.
    primary: SummerReferenceColors.shallowWater,
    onPrimary: Color(0xFF0E2124),
    primarySoft: Color(0xFF1F4247),
    onPrimarySoft: Color(0xFFA9D3C4),
    // Clay still holds the day's warmth.
    secondary: Color(0xFFC9814A),
    onSecondary: Color(0xFF21120A),
    // Gold fades to the last of the sunset.
    accent: Color(0xFFE9C078),
    onAccent: Color(0xFF21120A),
    // Warm off-white rather than harsh white, for low-light comfort.
    textPrimary: Color(0xFFF2ECD2),
    textSecondary: Color(0xFFA9BDB4),
    border: Color(0xFF4E777C),
    icon: SummerReferenceColors.shallowWater,
    water: Color(0xFF3E7C82),
    earth: Color(0xFF9C6840),
    disabled: Color(0xFF23383B),
    onDisabled: Color(0xFF7E9691),
    error: Color(0xFFE0765A),
    onError: Color(0xFF21120A),
  );
}
