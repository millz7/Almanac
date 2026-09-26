import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../environment/day_night.dart';
import '../environment/daypart.dart';
import '../environment/environment_providers.dart';
import '../environment/maramataka.dart';
import '../environment/moon_phase.dart';
import '../environment/tide.dart';
import '../environment/tide_providers.dart';
import '../environment/weather.dart';
import '../environment/weather_providers.dart';
import '../settings/settings_providers.dart';
import '../time/clock_providers.dart';
import 'almanac_moment.dart';

export '../environment/daypart.dart' show Daypart;
export '../environment/environment_providers.dart'
    show currentSeasonProvider, resolvedHemisphereProvider;
export '../environment/tide.dart'
    show
        TideAvailable,
        TideDirection,
        TideExtreme,
        TideExtremeType,
        TideLocationRequired,
        TideProviderUnavailable,
        TideSnapshot,
        TideState,
        TideUnavailableForLocation;
export '../environment/weather.dart' show WeatherCondition, WeatherSnapshot;
export '../time/clock_providers.dart' show todayProvider;
export '../environment/maramataka.dart';
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

/// Tonight's estimated Maramataka night — or null whenever the user has
/// not chosen to include the Māori lunar calendar.
///
/// Derived from [currentMoonProvider], the one Moon the whole app reads:
/// no second Moon calculation. Off by default, and while it is off
/// nothing anywhere in the app can see a Maramataka night.
final currentMaramatakaProvider = Provider<MaramatakaNight?>((ref) {
  if (!ref.watch(userSettingsProvider).includeMaramataka) return null;
  return Maramataka.nightForAge(ref.watch(currentMoonProvider).ageInDays);
});

/// Where the day has got to, once sunrise and sunset have resolved.
///
/// Null until then. Unlike the season and the moon there is no honest way
/// to work this out early without a position, so it says nothing rather
/// than guessing.
final currentDaylightProvider = Provider<DayNightState?>(
  (ref) => ref.watch(naturalEnvironmentProvider).value?.dayNight,
);

/// The most recent forecast, or null.
///
/// A thin selector over [weatherControllerProvider] — the same shape as
/// [currentMoonProvider] and [currentDaylightProvider] — flattening its
/// `AsyncValue` to a plain nullable snapshot, so a consumer never has to
/// branch on loading or error: there is either weather worth saying
/// something about, or there is nothing to say, and both look the same
/// from here. See `weather_providers.dart` for why null covers every
/// reason (no location, no network, a stale cache) without
/// distinguishing them.
///
/// Deliberately **not** part of [AlmanacMoment]: a [WeatherSnapshot]
/// carries the coordinates it was fetched for, and the moment's one firm
/// rule is that it holds no position at all. A consumer that wants
/// weather alongside the rest of the moment reads both providers.
final currentWeatherProvider = Provider<WeatherSnapshot?>(
  (ref) => ref.watch(weatherControllerProvider).value,
);

/// The tide at the shared location, right now — or null before the
/// controller has resolved once.
///
/// Unlike [currentWeatherProvider], the resolved value is a [TideState]
/// rather than a plain snapshot: a tide reading has more than one honest
/// reason to be absent, and callers that want to tell a missing position
/// apart from a position the marine model has nothing for read the
/// state's own type rather than a second flag. Null here means only
/// "not resolved yet" — the brief loading gap before the first result,
/// never a stand-in for one of the real states.
final currentTideProvider = Provider<TideState?>(
  (ref) => ref.watch(tideControllerProvider).value,
);

/// The human part of the day — morning, afternoon, evening, night — or
/// null before the environment has resolved once.
///
/// A thin selector over the same [naturalEnvironmentProvider] the rest of
/// this file reads, turning its resolved local time into a [Daypart] via
/// [daypartAt] so a weather suggestion can say "this morning" or "tonight"
/// without any feature touching a clock or a time zone itself.
final currentDaypartProvider = Provider<Daypart?>((ref) {
  final environment = ref.watch(naturalEnvironmentProvider).value;
  if (environment == null) return null;
  return daypartAt(environment.timeZone.wallTimeAt(environment.resolvedAt));
});

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
