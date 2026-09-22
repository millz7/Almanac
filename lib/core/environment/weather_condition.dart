/// A small, app-owned vocabulary for "what the sky is doing", translated
/// once from a weather provider's numeric codes so nothing downstream —
/// UI, narrative, cross-feature suggestions — ever has to know a vendor
/// code.
///
/// Deliberately coarse. This is not a meteorologist's classification; it
/// is the handful of distinctions that change what a sentence or a
/// suggestion says.
enum WeatherCondition {
  clear,
  mostlyClear,
  partlyCloudy,
  cloudy,
  fog,
  drizzle,
  rain,
  showers,
  thunderstorm,
  snow,
  mixedPrecipitation;

  /// Whether this condition is any form of precipitation happening right
  /// now (not a probability of one later).
  bool get isPrecipitating => switch (this) {
    WeatherCondition.drizzle ||
    WeatherCondition.rain ||
    WeatherCondition.showers ||
    WeatherCondition.thunderstorm ||
    WeatherCondition.snow ||
    WeatherCondition.mixedPrecipitation => true,
    WeatherCondition.clear ||
    WeatherCondition.mostlyClear ||
    WeatherCondition.partlyCloudy ||
    WeatherCondition.cloudy ||
    WeatherCondition.fog => false,
  };

  /// Whether the sky reads as genuinely open — clear or only lightly
  /// marked with cloud. Used to decide whether "clearing"/"clouding
  /// over" is worth saying.
  bool get isOpenSky => switch (this) {
    WeatherCondition.clear || WeatherCondition.mostlyClear => true,
    _ => false,
  };

  /// Translates Open-Meteo's WMO weather-interpretation code into the
  /// app's own vocabulary.
  ///
  /// The full table (WMO code 4677, as Open-Meteo documents it):
  /// 0 clear · 1/2/3 mainly clear/partly cloudy/overcast · 45/48 fog ·
  /// 51/53/55 drizzle · 56/57 freezing drizzle · 61/63/65 rain ·
  /// 66/67 freezing rain · 71/73/75 snow · 77 snow grains ·
  /// 80/81/82 rain showers · 85/86 snow showers ·
  /// 95 thunderstorm · 96/99 thunderstorm with hail.
  ///
  /// An unrecognised code — the docs reserve room to add variables
  /// without breaking existing ones, but a new *code* would be
  /// unprecedented — falls back to [cloudy] rather than throwing: the
  /// safest, least specific guess for something otherwise unreadable.
  static WeatherCondition fromWmoCode(int code) => switch (code) {
    0 => WeatherCondition.clear,
    1 => WeatherCondition.mostlyClear,
    2 => WeatherCondition.partlyCloudy,
    3 => WeatherCondition.cloudy,
    45 || 48 => WeatherCondition.fog,
    51 || 53 || 55 || 56 || 57 => WeatherCondition.drizzle,
    61 || 63 || 65 => WeatherCondition.rain,
    66 || 67 => WeatherCondition.mixedPrecipitation,
    71 || 73 || 75 || 77 => WeatherCondition.snow,
    80 || 81 || 82 => WeatherCondition.showers,
    85 || 86 => WeatherCondition.snow,
    95 || 96 || 99 => WeatherCondition.thunderstorm,
    _ => WeatherCondition.cloudy,
  };
}
