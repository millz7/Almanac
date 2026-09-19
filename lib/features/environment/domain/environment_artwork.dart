import '../../../core/environment/day_night.dart';
import '../../../core/environment/season.dart';

/// The four light states the Environment's artwork is painted for.
///
/// Deliberately its own small type rather than [DayPhase] reused: the
/// app's day/night model is about the *sun*, and this is about which
/// painting is on the wall. They happen to line up one-to-one today, and
/// [EnvironmentLightState.of] is the one place that says so — a pure
/// adaptation layer, not a second daylight model.
enum EnvironmentLightState {
  sunrise,
  day,
  sunset,
  night;

  /// Maps the app's real, calculated day/night state onto a plate.
  ///
  /// No clock thresholds and no guessing: [DayNightState.phase] already
  /// comes from the user's own sunrise and sunset, by way of the one
  /// solar service.
  static EnvironmentLightState of(DayNightState dayNight) =>
      switch (dayNight.phase) {
        DayPhase.dawn => EnvironmentLightState.sunrise,
        DayPhase.day => EnvironmentLightState.day,
        DayPhase.dusk => EnvironmentLightState.sunset,
        DayPhase.night => EnvironmentLightState.night,
      };
}

/// The Environment's artwork: sixteen approved plates, and the one map
/// from a moment to the right one.
///
/// **These files are the artwork.** They are bundled, licensed, final,
/// and nothing in the app redraws, recolours, traces or reinterprets
/// them. The landscape used to be drawn in code; that implementation was
/// retired when these arrived, and the classes that supported it were
/// deleted rather than left switched off underneath.
///
/// A painting carries no facts. The sun and moon inside these plates are
/// illustration — atmosphere, not instruments — and the real sunrise,
/// sunset, phase and percentage stay where they belong, in live text
/// beneath the picture.
abstract final class EnvironmentArtwork {
  /// Where the plates live. One directory, registered once in
  /// `pubspec.yaml`.
  static const directory = 'assets/environment';

  /// The plate for a season at a light state.
  ///
  /// Total by construction: both arguments are enums and the switch has
  /// no default, so adding a season or a light state stops the compiler
  /// here rather than falling through to a stand-in.
  static String forState({
    required Season season,
    required EnvironmentLightState light,
  }) => '$directory/${season.name}_${light.name}.webp';

  /// Every plate the app ships, in a fixed order: season by season, and
  /// within each season sunrise, day, sunset, night.
  static List<String> get all => [
    for (final season in Season.values)
      for (final light in EnvironmentLightState.values)
        forState(season: season, light: light),
  ];
}
