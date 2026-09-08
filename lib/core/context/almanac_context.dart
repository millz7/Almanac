import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../environment/day_night.dart';
import '../environment/environment_providers.dart';
import '../environment/moon_phase.dart';
import '../time/clock_providers.dart';
import 'almanac_moment.dart';

export '../environment/environment_providers.dart'
    show currentSeasonProvider, resolvedHemisphereProvider;
export '../time/clock_providers.dart' show todayProvider;
export 'almanac_moment.dart';
export 'almanac_intent.dart';
export 'feature_availability.dart';

/// The moon's phase right now.
///
/// A **selector**, not a second moon system: it prefers the phase the
/// resolved environment already carries, and before that has arrived it
/// asks the same [moonServiceProvider] the environment asks. Written the
/// same way as [currentSeasonProvider], for the same reason — so a screen
/// never has to flash a wrong moon for a frame, and so there is exactly
/// one place in the app that decides what the moon is doing.
final currentMoonProvider = Provider<MoonPhaseState>((ref) {
  final environment = ref.watch(naturalEnvironmentProvider).value;
  if (environment != null) return environment.moon;

  return ref.watch(moonServiceProvider).phaseAt(ref.watch(clockProvider)());
});

/// Where the day has got to, once sunrise and sunset have resolved.
///
/// Null until then. Unlike the season and the moon there is no honest way
/// to work this out early without a position, so it says nothing rather
/// than guessing.
final currentDaylightProvider = Provider<DayNightState?>(
  (ref) => ref.watch(naturalEnvironmentProvider).value?.dayNight,
);

/// The whole current moment, for a consumer that genuinely needs several
/// parts of it at once.
///
/// Composed from the individual selectors above, so it can never
/// disagree with them, and so nothing here calculates anything.
final almanacMomentProvider = Provider<AlmanacMoment>(
  (ref) => AlmanacMoment(
    today: ref.watch(todayProvider),
    season: ref.watch(currentSeasonProvider),
    hemisphere: ref.watch(resolvedHemisphereProvider).hemisphere,
    moon: ref.watch(currentMoonProvider),
    daylight: ref.watch(currentDaylightProvider),
  ),
);
