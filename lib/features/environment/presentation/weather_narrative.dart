import 'package:timezone/timezone.dart' as tz;

import '../../../core/environment/daypart.dart';
import '../../../core/environment/weather.dart';
import '../../../core/environment/weather_feel.dart';

export '../../../core/environment/weather_feel.dart' show WeatherThresholds;

String _tempWord(TemperatureFeel feel) => switch (feel) {
  TemperatureFeel.cold => 'cold',
  TemperatureFeel.cool => 'cool',
  TemperatureFeel.mild => 'mild',
  TemperatureFeel.warm => 'warm',
  TemperatureFeel.hot => 'hot',
};

/// Whether [condition] reads as a headline event worth leading the
/// sentence with — "Rain this morning..." — rather than a quiet
/// background adjective. Drizzle and fog stay adjectival ("a damp
/// morning", "a foggy morning"); anything heavier than that leads.
bool _isHeadlineCondition(WeatherCondition condition) => switch (condition) {
  WeatherCondition.rain ||
  WeatherCondition.showers ||
  WeatherCondition.thunderstorm ||
  WeatherCondition.snow ||
  WeatherCondition.mixedPrecipitation => true,
  _ => false,
};

/// The word this condition takes as a sentence subject: "Rain this
/// morning...", "A thunderstorm this evening...".
String _precipNoun(WeatherCondition condition) => switch (condition) {
  WeatherCondition.rain => 'Rain',
  WeatherCondition.showers => 'Showers',
  WeatherCondition.thunderstorm => 'A thunderstorm',
  WeatherCondition.snow => 'Snow',
  WeatherCondition.mixedPrecipitation => 'Sleet',
  _ => 'Rain',
};

/// The plain, lower-case, article-free form of the same word: "rain",
/// "showers", "storm" — for a clause where it is not the subject, as in
/// "the storm easing later" rather than "the a thunderstorm easing
/// later".
String _precipWord(WeatherCondition condition) => switch (condition) {
  WeatherCondition.rain => 'rain',
  WeatherCondition.showers => 'showers',
  WeatherCondition.thunderstorm => 'storm',
  WeatherCondition.snow => 'snow',
  WeatherCondition.mixedPrecipitation => 'sleet',
  _ => 'rain',
};

/// The adjective a quiet, non-headline condition takes: "a bright
/// morning", "a damp morning".
String? _skyAdjective(WeatherCondition condition) => switch (condition) {
  WeatherCondition.clear => 'clear',
  WeatherCondition.mostlyClear => 'bright',
  WeatherCondition.partlyCloudy => 'partly cloudy',
  WeatherCondition.cloudy => 'cloudy',
  WeatherCondition.fog => 'foggy',
  WeatherCondition.drizzle => 'damp',
  _ => null,
};

/// A bucket coarse enough that a genuine change of weather crosses it,
/// and a small fluctuation never does. Trend detection throughout this
/// file compares these buckets, never a raw percentage — so a cloud
/// cover reading moving from 49% to 47% can never by itself read as
/// "clearing".
enum _SkyBucket { openSky, overcast, wet }

_SkyBucket _bucketOf(WeatherCondition condition, double precipProbability) {
  if (condition.isPrecipitating) return _SkyBucket.wet;
  if (precipProbability >= WeatherThresholds.likelyFrom) return _SkyBucket.wet;
  if (condition.isOpenSky) return _SkyBucket.openSky;
  return _SkyBucket.overcast;
}

/// The connective word a change clause reaches for, by the daypart the
/// sentence is spoken from.
String _connector(Daypart daypart) => switch (daypart) {
  Daypart.morning => 'later',
  Daypart.afternoon => 'towards evening',
  Daypart.evening => 'overnight',
  Daypart.night => 'towards morning',
};

/// The hours worth looking ahead through from [localNow], long enough to
/// reach a little way into the *next* daypart — which is what lets a
/// morning sentence say something about the afternoon, an evening
/// sentence about the night, and so on.
List<HourlyWeather> _lookAhead(
  List<HourlyWeather> hourly,
  Daypart daypart,
  tz.TZDateTime localNow,
) {
  final hoursAhead = switch (daypart) {
    Daypart.morning => 9,
    Daypart.afternoon => 8,
    Daypart.evening => 11,
    Daypart.night => 9,
  };
  final cutoff = localNow.toUtc().add(Duration(hours: hoursAhead));
  return [
    for (final hour in hourly)
      if (!hour.time.isBefore(localNow.toUtc()) && hour.time.isBefore(cutoff))
        hour,
  ];
}

/// The dominant sky bucket across [hours] — simply the most common one,
/// so one stray hour of drizzle in an otherwise dry afternoon does not
/// flip the whole reading.
_SkyBucket? _dominantBucket(List<HourlyWeather> hours) {
  if (hours.isEmpty) return null;
  final counts = <_SkyBucket, int>{};
  for (final hour in hours) {
    final bucket = _bucketOf(
      hour.condition,
      hour.precipitationProbabilityPercent,
    );
    counts[bucket] = (counts[bucket] ?? 0) + 1;
  }
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

double _highestChance(List<HourlyWeather> hours) => hours.isEmpty
    ? 0
    : hours
          .map((hour) => hour.precipitationProbabilityPercent)
          .reduce((a, b) => a > b ? a : b);

WindFeel? _dominantWind(List<HourlyWeather> hours) {
  if (hours.isEmpty) return null;
  final average =
      hours.map((hour) => hour.windSpeedKmh).reduce((a, b) => a + b) /
      hours.length;
  return windFeelOf(average);
}

TemperatureFeel? _dominantTemp(List<HourlyWeather> hours) {
  if (hours.isEmpty) return null;
  final average =
      hours.map((hour) => hour.temperatureC).reduce((a, b) => a + b) /
      hours.length;
  return temperatureFeelOf(average);
}

/// One clause about what changes, or null when nothing crosses a
/// meaningful threshold — see [WeatherThresholds]. Checked in priority
/// order: precipitation first (the most consequential to a day), then
/// sky, then wind, then temperature, and only the first genuine change
/// found is said — one clause keeps the sentence to about one line.
String? _changeClause({
  required CurrentWeather now,
  required List<HourlyWeather> ahead,
  required Daypart daypart,
}) {
  final connector = _connector(daypart);
  final nowBucket = _bucketOf(now.condition, 0);
  final aheadBucket = _dominantBucket(ahead);
  final aheadChance = _highestChance(ahead);

  if (aheadBucket != null &&
      nowBucket == _SkyBucket.wet &&
      aheadBucket != _SkyBucket.wet) {
    // Currently wet, clearing up: the special "before dawn" phrasing is
    // reserved for a night sentence about rain finally easing off.
    final verb = daypart == Daypart.night
        ? 'easing before dawn'
        : 'easing $connector';
    return 'the ${_precipWord(now.condition)} $verb';
  }

  if (nowBucket != _SkyBucket.wet && aheadBucket == _SkyBucket.wet) {
    // Currently dry, wet weather developing or merely possible.
    if (aheadChance >= WeatherThresholds.likelyFrom) {
      return 'showers developing $connector';
    }
    if (aheadChance >= WeatherThresholds.chanceFrom) {
      return 'a chance of showers $connector';
    }
    // Below even a "chance" threshold: not worth a confident claim.
  }

  if (nowBucket == _SkyBucket.overcast && aheadBucket == _SkyBucket.openSky) {
    return 'the sky clearing $connector';
  }
  if (nowBucket == _SkyBucket.openSky && aheadBucket == _SkyBucket.overcast) {
    return 'cloud building $connector';
  }

  final nowWind = windFeelOf(now.windSpeedKmh);
  final aheadWind = _dominantWind(ahead);
  if (aheadWind != null) {
    if (nowWind == WindFeel.calm && aheadWind != WindFeel.calm) {
      return 'the wind picking up $connector';
    }
    if (nowWind != WindFeel.calm && aheadWind == WindFeel.calm) {
      return 'the wind easing $connector';
    }
  }

  final nowTemp = temperatureFeelOf(now.apparentTemperatureC);
  final aheadTemp = _dominantTemp(ahead);
  if (aheadTemp != null && aheadTemp != nowTemp) {
    final warming = aheadTemp.index > nowTemp.index;
    return warming
        ? 'milder air moving in $connector'
        : 'things turning cooler $connector';
  }

  return null;
}

/// The sentence itself.
///
/// **Not a numerical report.** It never states a temperature or a
/// percentage; it interprets the forecast into the kind of thing a
/// person says about the day — see `weather_narrative_test.dart` for a
/// representative set of the sentences this produces.
///
/// Pure and deterministic: the same [weather] and [localNow] always
/// produce the same sentence, with no randomness and no call out to
/// anything generative.
String describeWeather({
  required WeatherSnapshot weather,
  required tz.TZDateTime localNow,
}) {
  final daypart = daypartAt(localNow);
  final now = weather.current;
  final ahead = _lookAhead(weather.hourly, daypart, localNow);
  final change = _changeClause(now: now, ahead: ahead, daypart: daypart);

  final tempFeel = temperatureFeelOf(now.apparentTemperatureC);
  final windFeel = windFeelOf(now.windSpeedKmh);

  if (_isHeadlineCondition(now.condition)) {
    final lead = '${_precipNoun(now.condition)} ${daypart.phrase}';
    if (change == null) return '$lead.';
    // The lead already names the precipitation as the subject, so a
    // clause that would otherwise repeat it ("the rain easing later")
    // drops that repeated subject ("easing later").
    final bare = change.replaceFirst(
      RegExp('^the (rain|showers|snow|sleet|storm) '),
      '',
    );
    return '$lead, $bare.';
  }

  // At most two adjectives before the daypart noun, so the sentence
  // never turns into a list. "Mild" — the neutral middle of the
  // temperature range — is worth saying only when it is paired with
  // wind, which needs a temperature to mean anything ("mild, breezy" is
  // a different day from "cold, breezy"); on a calm day the sky
  // adjective already carries the sentence, and a calm, merely mild day
  // says just that.
  final windy = windFeel != WindFeel.calm;
  final skyAdjective = _skyAdjective(now.condition);
  final adjectives = <String>[];
  if (tempFeel != TemperatureFeel.mild) adjectives.add(_tempWord(tempFeel));
  if (windy) {
    adjectives.add(windFeel == WindFeel.windy ? 'windy' : 'breezy');
    if (tempFeel == TemperatureFeel.mild) adjectives.insert(0, 'mild');
  } else if (skyAdjective != null) {
    adjectives.add(skyAdjective);
  }
  if (adjectives.isEmpty) adjectives.add(_tempWord(tempFeel));

  final noun = daypart == Daypart.night
      ? 'night'
      : daypart.phrase.replaceFirst('this ', '');
  final opener = 'A ${adjectives.join(', ')} $noun';

  if (change == null) return '$opener.';
  return '$opener, with $change.';
}
