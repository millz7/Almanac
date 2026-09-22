/// The deterministic thresholds behind every weather-derived sentence in
/// the app — the TODAY narrative and every feature's quiet weather
/// suggestion alike.
///
/// Gathered in one place, in `core/environment`, so every feature reads
/// the same numbers rather than each carrying its own copy that could
/// silently drift apart. Named and documented so they can be read,
/// reviewed and tested without hunting through sentence-building logic.
abstract final class WeatherThresholds {
  // ── Temperature, from the apparent ("feels like") reading, °C ──────
  static const coldBelow = 5.0;
  static const coolBelow = 12.0;
  static const mildBelow = 21.0;
  static const warmBelow = 28.0;
  // 28.0 and above reads as hot.

  // ── Wind, from the 10 m speed, km/h ─────────────────────────────────
  static const breezyFrom = 20.0;
  static const windyFrom = 40.0;

  // ── Precipitation probability, over a look-ahead window, % ─────────
  static const chanceFrom = 30.0;
  static const likelyFrom = 60.0;
}

enum TemperatureFeel { cold, cool, mild, warm, hot }

TemperatureFeel temperatureFeelOf(double apparentC) {
  if (apparentC < WeatherThresholds.coldBelow) return TemperatureFeel.cold;
  if (apparentC < WeatherThresholds.coolBelow) return TemperatureFeel.cool;
  if (apparentC < WeatherThresholds.mildBelow) return TemperatureFeel.mild;
  if (apparentC < WeatherThresholds.warmBelow) return TemperatureFeel.warm;
  return TemperatureFeel.hot;
}

enum WindFeel { calm, breezy, windy }

WindFeel windFeelOf(double kmh) {
  if (kmh >= WeatherThresholds.windyFrom) return WindFeel.windy;
  if (kmh >= WeatherThresholds.breezyFrom) return WindFeel.breezy;
  return WindFeel.calm;
}
