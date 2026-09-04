import 'package:flutter/foundation.dart';

import '../../core/environment/season.dart';
import 'palettes/autumn_palette.dart';
import 'palettes/spring_palette.dart';
import 'palettes/summer_palette.dart';
import 'palettes/winter_palette.dart';
import 'seasonal_palette.dart';

export 'palettes/autumn_palette.dart';
export 'palettes/spring_palette.dart';
export 'palettes/summer_palette.dart';
export 'palettes/winter_palette.dart';
export 'seasonal_palette.dart';

/// One season's pair of palettes.
@immutable
class SeasonalPaletteSet {
  const SeasonalPaletteSet({required this.day, required this.night});

  final SeasonalPalette day;
  final SeasonalPalette night;

  /// Picks the palette for a given amount of daylight.
  ///
  /// At the extremes this returns the designed palette itself, untouched —
  /// which matters both for fidelity and for efficiency, since those are
  /// `const` instances and so comparing them is free. Only during dawn and
  /// dusk is a new blended palette created.
  SeasonalPalette resolve(double daylight) {
    final t = daylight.clamp(0.0, 1.0);
    if (t <= 0) return night;
    if (t >= 1) return day;
    return night.lerp(day, t);
  }
}

/// The app's complete set of seasonal palettes: four seasons, each with a
/// day and a night interpretation.
///
/// This is the only place that maps a [Season] to actual colours. Nothing
/// else in the app should branch on the season.
abstract final class SeasonalPalettes {
  static const spring = SeasonalPaletteSet(
    day: SpringPalettes.day,
    night: SpringPalettes.night,
  );
  static const summer = SeasonalPaletteSet(
    day: SummerPalettes.day,
    night: SummerPalettes.night,
  );
  static const autumn = SeasonalPaletteSet(
    day: AutumnPalettes.day,
    night: AutumnPalettes.night,
  );
  static const winter = SeasonalPaletteSet(
    day: WinterPalettes.day,
    night: WinterPalettes.night,
  );

  static SeasonalPaletteSet forSeason(Season season) => switch (season) {
    Season.spring => spring,
    Season.summer => summer,
    Season.autumn => autumn,
    Season.winter => winter,
  };

  /// The palette for a season at a given amount of daylight (0 = night,
  /// 1 = full day). This is the entry point the theme uses.
  static SeasonalPalette resolve({
    required Season season,
    required double daylight,
  }) => forSeason(season).resolve(daylight);

  /// Used when no palette has been installed in the theme yet — see
  /// `context.palette`. Should never be reached in the running app.
  static const fallback = SummerPalettes.day;

  /// Every palette in the system, for tests and the developer preview.
  static const all = <SeasonalPalette>[
    SpringPalettes.day,
    SpringPalettes.night,
    SummerPalettes.day,
    SummerPalettes.night,
    AutumnPalettes.day,
    AutumnPalettes.night,
    WinterPalettes.day,
    WinterPalettes.night,
  ];
}
