import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/environment/environment_providers.dart';
import '../../dev/theme_preview.dart';
import 'seasonal_palettes.dart';

/// The palette the app is currently wearing.
///
/// This is the join between the natural world and the interface, and the
/// only thing the app's [ThemeData] depends on. Order of precedence:
///
/// 1. A developer preview override, if one is active (debug builds only).
/// 2. The resolved natural environment — the user's real season and
///    daylight.
/// 3. A bootstrap palette for the brief moment before location and solar
///    data have resolved.
///
/// Outside dawn and dusk this returns a `const` palette instance, so
/// re-resolving the environment when nothing has actually changed does not
/// rebuild the app's theme.
final activePaletteProvider = Provider<SeasonalPalette>((ref) {
  final preview = ref.watch(themePreviewProvider);
  if (preview != null) {
    return SeasonalPalettes.resolve(
      season: preview.season,
      daylight: preview.daylight,
    );
  }

  final environment = ref.watch(naturalEnvironmentProvider).value;
  if (environment != null) {
    return SeasonalPalettes.resolve(
      season: environment.season.season,
      daylight: environment.dayNight.daylight,
    );
  }

  // Location and sunrise/sunset are asynchronous. For the first frame,
  // show the correct season for the device clock in daylight rather than
  // flashing an arbitrary palette.
  final now = ref.watch(clockProvider)();
  final season = ref
      .watch(seasonServiceProvider)
      .seasonAt(now, kBootstrapHemisphere)
      .season;
  return SeasonalPalettes.resolve(season: season, daylight: 1);
});
