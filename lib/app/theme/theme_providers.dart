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

  // Sunrise/sunset resolution is asynchronous, so for the first frame
  // the season comes from the clock and the known hemisphere — see
  // [currentSeasonProvider] — and the daylight from full day, rather
  // than flashing an arbitrary palette.
  final environment = ref.watch(naturalEnvironmentProvider).value;
  return SeasonalPalettes.resolve(
    season: ref.watch(currentSeasonProvider),
    daylight: environment?.dayNight.daylight ?? 1,
  );
});
