import 'dart:ui';

import '../../../app/theme/seasonal_palette.dart';
import '../../../core/environment/day_night.dart';
import '../../../core/environment/season.dart';
import 'almanac_landscape.dart';

/// Which of the day's four faces the scene is wearing.
///
/// Dawn and dusk are separate states, not one "twilight" reversed: the
/// sunrise and sunset references are visibly different pictures, and the
/// app already knows which one it is in — [DayNightState.phase] carries
/// it, from real calculated sunrise and sunset.
enum LandscapeLight {
  /// Early light. Cool overhead, warm and low at the horizon.
  dawn,

  /// Full day.
  day,

  /// The light going. Warmer and more saturated overhead than dawn, with
  /// the band of colour sitting higher in the sky.
  dusk,

  /// After dark.
  night;

  static LandscapeLight of(DayPhase phase) => switch (phase) {
    DayPhase.dawn => LandscapeLight.dawn,
    DayPhase.day => LandscapeLight.day,
    DayPhase.dusk => LandscapeLight.dusk,
    DayPhase.night => LandscapeLight.night,
  };
}

/// The shape of a flower, as a silhouette.
///
/// Explicitly **not** one five-petal icon recoloured four ways — that was
/// rejected by name. A daisy and an umbel differ in outline before they
/// differ in colour, which is what lets somebody tell the season at a
/// glance and what makes the drawing honest at the size it is drawn.
enum FlowerForm {
  /// A flat head on a thin stalk, many tiny florets: cow parsley and its
  /// relatives. Spring's white froth along the bank.
  umbel,

  /// A ring of separate petals around a disc. Spring and early summer.
  daisy,

  /// **Summer's approved accent.** A tight cluster of very small
  /// five-petal flowers with a pale eye — read as a *cluster*, never as
  /// one large bloom, and small enough to stay an accent rather than a
  /// border.
  forgetMeNot,

  /// A dry globe of seeds on a bare stem: what is left standing in
  /// autumn and winter. Not a flower, and drawn as one silhouette.
  seedHead,
}

/// One flower on the bank: a form, a colour, and how much of it there is.
class FlowerPlanting {
  const FlowerPlanting({
    required this.form,
    required this.colour,
    required this.centre,
    required this.share,
  });

  final FlowerForm form;
  final Color colour;

  /// The eye at the middle of the bloom, where the form has one.
  final Color centre;

  /// The fraction of the fixed planting positions that carry this form.
  /// The positions themselves never move — see
  /// [AlmanacLandscape.plantings].
  final double share;
}

/// What the bough in the top-left corner is carrying this season.
enum BoughDress {
  /// Blossom on a mostly bare branch. Spring.
  blossom,

  /// Full leaf. Summer.
  leaf,

  /// Turned leaf, thinner. Autumn.
  turned,

  /// Bare twigs and a few seed pods. Winter.
  bare,
}

/// Everything about how the one place looks right now.
///
/// **It carries the form; it does not make one.** [form] is
/// [AlmanacLandscape.form] — the single shared instance — so a test can
/// build every season at every light and assert the geometry is
/// identical, and so there is nowhere for a seasonal mountain to hide.
///
/// Colour is derived from the active [SeasonalPalette] wherever the
/// palette has an opinion (water, earth, primary, accent), and from the
/// small documented set of scene tints below where it does not. A painter
/// reads this and never mixes a colour of its own.
class LandscapeAppearance {
  const LandscapeAppearance({
    required this.light,
    required this.season,
    required this.daylight,
    required this.source,
    required this.skyStops,
    required this.sunColour,
    required this.sunGlow,
    required this.starStrength,
    required this.farRange,
    required this.nearRange,
    required this.headland,
    required this.island,
    required this.water,
    required this.waterLight,
    required this.bankColour,
    required this.boulderColour,
    required this.foliage,
    required this.foliageShade,
    required this.vegetationDensity,
    required this.flowers,
    required this.bough,
    required this.boughColour,
    required this.blossomColour,
    required this.haze,
  });

  /// The fixed place. Always [AlmanacLandscape.form].
  LandscapeForm get form => AlmanacLandscape.form;

  final LandscapeLight light;
  final Season season;

  /// The three things this was resolved from. Kept so two appearances
  /// can be compared without comparing thirty colours: [resolve] is a
  /// pure function of them, so equal inputs mean an equal appearance —
  /// which is what lets the painter decline to repaint a static scene.
  final double daylight;
  final SeasonalPalette source;

  /// Top, upper-middle, lower-middle and horizon colours of the sky.
  final List<Color> skyStops;

  final Color sunColour;
  final Color sunGlow;

  /// 0 by day, 1 in the deepest part of the night.
  final double starStrength;

  final Color farRange;
  final Color nearRange;
  final Color headland;
  final Color island;
  final Color water;

  /// The colour of the light lying on the water.
  final Color waterLight;

  final Color bankColour;
  final Color boulderColour;

  final Color foliage;
  final Color foliageShade;

  /// How much of the fixed planting list is drawn, and how full each
  /// plant is. Summer is 1.0; winter leaves the same bank sparse.
  final double vegetationDensity;

  final List<FlowerPlanting> flowers;

  final BoughDress bough;
  final Color boughColour;
  final Color blossomColour;

  /// Atmospheric wash laid over the distance: how much the far range
  /// dissolves into the sky. Higher at dawn and dusk.
  final double haze;

  /// Builds the appearance for a moment.
  ///
  /// Takes the resolved environment's own season, day/night state and
  /// palette. It calculates nothing astronomical: `daylight`, `phase` and
  /// the sun's progress are all already worked out upstream, by the one
  /// solar service. There is no second sun in this file, and no clock.
  factory LandscapeAppearance.resolve({
    required Season season,
    required DayNightState dayNight,
    required SeasonalPalette palette,
  }) {
    final light = LandscapeLight.of(dayNight.phase);
    final day = dayNight.daylight.clamp(0.0, 1.0);

    // How far the scene is settled towards the dark. Night is not "the
    // day, dimmed": the palette has already switched, and this only
    // deepens what the palette gives.
    final dark = 1 - day;

    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

    final tints = _SeasonTints.of(season);
    final sky = switch (light) {
      LandscapeLight.day => [
        mix(tints.skyHigh, palette.water, 0.35),
        tints.skyHigh,
        tints.skyLow,
        mix(tints.skyLow, tints.horizonWarm, 0.25),
      ],
      // Dawn: cool above, one warm band low down, and a pale gap of
      // clean light just over the hills. Early rather than fiery.
      LandscapeLight.dawn => [
        _dawnHigh,
        mix(_dawnHigh, _dawnMid, 0.7),
        _dawnMid,
        mix(_dawnLow, tints.horizonWarm, 0.45),
      ],
      // Dusk: the colour sits higher and runs hotter, and the top of the
      // sky is already going violet. Not dawn played backwards.
      LandscapeLight.dusk => [
        _duskHigh,
        mix(_duskHigh, _duskMid, 0.55),
        _duskMid,
        mix(_duskLow, tints.horizonWarm, 0.30),
      ],
      LandscapeLight.night => [
        mix(tints.nightHigh, const Color(0xFF060A16), 0.35),
        tints.nightHigh,
        tints.nightLow,
        mix(tints.nightLow, tints.nightHorizon, 0.6),
      ],
    };

    // Distance reads as haze, and haze is strongest when the light is
    // low — which is also what keeps a sunrise from looking like a
    // daytime scene with an orange sky pasted behind it.
    final haze = switch (light) {
      LandscapeLight.day => 0.18,
      LandscapeLight.dawn => 0.46,
      LandscapeLight.dusk => 0.40,
      LandscapeLight.night => 0.30,
    };

    final horizonLight = sky.last;
    Color inAir(Color colour, double distance) =>
        mix(colour, horizonLight, haze * distance);

    final far = inAir(mix(tints.rock, palette.water, 0.30), 1.0);
    final near = inAir(mix(tints.rock, palette.primary, 0.22), 0.62);

    final foliage = mix(tints.foliage, palette.primary, 0.22);
    final waterBase = mix(palette.water, tints.waterTint, 0.45);

    return LandscapeAppearance(
      light: light,
      season: season,
      daylight: day,
      source: palette,
      skyStops: sky,
      sunColour: switch (light) {
        LandscapeLight.night => tints.moonlight,
        LandscapeLight.day => _sunDay,
        _ => _sunLow,
      },
      sunGlow: switch (light) {
        LandscapeLight.night => tints.moonlight,
        LandscapeLight.day => mix(_sunDay, tints.horizonWarm, 0.5),
        _ => tints.horizonWarm,
      },
      starStrength: switch (light) {
        LandscapeLight.night => 1,
        LandscapeLight.dawn ||
        LandscapeLight.dusk => (dark - 0.45).clamp(0.0, 1.0),
        LandscapeLight.day => 0,
      },
      farRange: far,
      nearRange: near,
      headland: inAir(mix(foliage, tints.rock, 0.35), 0.45),
      island: inAir(mix(foliage, tints.rock, 0.20), 0.30),
      water: waterBase,
      waterLight: switch (light) {
        LandscapeLight.night => tints.moonlight,
        LandscapeLight.day => mix(horizonLight, _sunDay, 0.45),
        _ => mix(horizonLight, _sunLow, 0.55),
      },
      bankColour: mix(palette.earth, tints.bank, 0.55),
      boulderColour: mix(tints.rock, palette.earth, 0.35),
      foliage: foliage,
      foliageShade: mix(foliage, tints.rock, 0.40),
      vegetationDensity: tints.density,
      flowers: tints.flowersOn(dark),
      bough: tints.bough,
      boughColour: mix(tints.rock, palette.earth, 0.55),
      blossomColour: tints.blossom,
      haze: haze,
    );
  }

  /// Whether the sun, rather than the moon, is the body in the sky.
  bool get sunIsUp => light != LandscapeLight.night;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LandscapeAppearance &&
          other.season == season &&
          other.light == light &&
          other.daylight == daylight &&
          other.source == source;

  @override
  int get hashCode => Object.hash(season, light, daylight, source);

  @override
  String toString() => 'LandscapeAppearance(${season.name}, ${light.name})';
}

// ── Scene tints ──────────────────────────────────────────────────────
//
// The palette knows what a season's *interface* looks like. It does not
// know what a hillside looks like at dawn, and stretching it to say so
// would make every screen in the app wear the landscape's colours.
//
// So a small, named, documented set of scene colours lives here — never
// in a painter, which is the rule from the visual language: a painter
// reads an appearance and mixes nothing of its own. Each one is blended
// with a palette token before it reaches the canvas, so the season is
// still doing the work.

/// Full daylight sun. Pale, not yellow: a summer sun at noon is white.
const _sunDay = Color(0xFFFFF3D2);

/// A sun near the horizon, seen through more air.
const _sunLow = Color(0xFFF6C46A);

/// Dawn: cool blue overhead, lilac through the middle, clean pale gold
/// at the bottom. The references' sunrises are pale; they are not fires.
const _dawnHigh = Color(0xFF8FA9C8);
const _dawnMid = Color(0xFFD8B6C4);
const _dawnLow = Color(0xFFF6DCB4);

/// Dusk: violet overhead, rose through the middle, a hotter band low
/// down. Higher, deeper and more saturated than dawn.
const _duskHigh = Color(0xFF6E6C9E);
const _duskMid = Color(0xFFD98C8C);
const _duskLow = Color(0xFFF2A65A);

/// One season's own colours.
class _SeasonTints {
  const _SeasonTints({
    required this.skyHigh,
    required this.skyLow,
    required this.horizonWarm,
    required this.nightHigh,
    required this.nightLow,
    required this.nightHorizon,
    required this.moonlight,
    required this.rock,
    required this.foliage,
    required this.waterTint,
    required this.bank,
    required this.density,
    required this.bough,
    required this.blossom,
    required this.flowers,
  });

  final Color skyHigh;
  final Color skyLow;
  final Color horizonWarm;
  final Color nightHigh;
  final Color nightLow;
  final Color nightHorizon;
  final Color moonlight;
  final Color rock;
  final Color foliage;
  final Color waterTint;
  final Color bank;
  final double density;
  final BoughDress bough;
  final Color blossom;
  final List<FlowerPlanting> flowers;

  /// The bank's flowers, dimmed into the dark rather than removed: a
  /// cow-parsley head is still a pale shape at midnight.
  List<FlowerPlanting> flowersOn(double dark) => [
    for (final flower in flowers)
      FlowerPlanting(
        form: flower.form,
        colour: Color.lerp(flower.colour, _nightWash, dark * 0.62)!,
        centre: Color.lerp(flower.centre, _nightWash, dark * 0.62)!,
        share: flower.share,
      ),
  ];

  static const _nightWash = Color(0xFF243250);

  static _SeasonTints of(Season season) => switch (season) {
    Season.spring => _spring,
    Season.summer => _summer,
    Season.autumn => _autumn,
    Season.winter => _winter,
  };

  /// **Spring.** Fresh, lighter greens and an open sky. New growth, and
  /// white blossom on a branch that is not yet full.
  static const _spring = _SeasonTints(
    skyHigh: Color(0xFF9FC1DA),
    skyLow: Color(0xFFD6E5EC),
    horizonWarm: Color(0xFFF3E2C4),
    nightHigh: Color(0xFF16243F),
    nightLow: Color(0xFF243C5C),
    nightHorizon: Color(0xFF3C5878),
    moonlight: Color(0xFFE8EDF6),
    rock: Color(0xFF6E7F92),
    foliage: Color(0xFF7FA35C),
    waterTint: Color(0xFF9DBFCE),
    bank: Color(0xFF8FA660),
    density: 0.70,
    bough: BoughDress.blossom,
    blossom: Color(0xFFF7DFE4),
    flowers: [
      FlowerPlanting(
        form: FlowerForm.umbel,
        colour: Color(0xFFF6F3E6),
        centre: Color(0xFFE6E0C8),
        share: 0.45,
      ),
      FlowerPlanting(
        form: FlowerForm.daisy,
        colour: Color(0xFFFCFBF4),
        centre: Color(0xFFE9C35C),
        share: 0.35,
      ),
    ],
  );

  /// **Summer.** Distinctly lusher than spring: richer, fuller greens, a
  /// denser bank, and the approved forget-me-not clusters. Warm without
  /// the whole scene turning gold — that is what sunset is for.
  static const _summer = _SeasonTints(
    skyHigh: Color(0xFF7FB2D8),
    skyLow: Color(0xFFCADEEA),
    horizonWarm: Color(0xFFF0E3C0),
    nightHigh: Color(0xFF111E36),
    nightLow: Color(0xFF1C3350),
    nightHorizon: Color(0xFF36536F),
    moonlight: Color(0xFFEDF1F7),
    rock: Color(0xFF5F7488),
    foliage: Color(0xFF4F7C3E),
    waterTint: Color(0xFF7FAEC4),
    bank: Color(0xFF6E8F44),
    density: 1.0,
    bough: BoughDress.leaf,
    blossom: Color(0xFFDCE9C8),
    flowers: [
      FlowerPlanting(
        form: FlowerForm.forgetMeNot,
        colour: Color(0xFF7FA8D6),
        centre: Color(0xFFF6E7A8),
        share: 0.40,
      ),
      FlowerPlanting(
        form: FlowerForm.daisy,
        colour: Color(0xFFFBFAF3),
        centre: Color(0xFFE9C35C),
        share: 0.25,
      ),
      FlowerPlanting(
        form: FlowerForm.umbel,
        colour: Color(0xFFF2F0E2),
        centre: Color(0xFFDED7BE),
        share: 0.20,
      ),
    ],
  );

  /// **Autumn.** Greens recede into warmer earth tones and the bank goes
  /// to seed — under a **normal daytime sky**. Autumn is a season, not a
  /// permanent sunset, and there is a test that says so.
  static const _autumn = _SeasonTints(
    skyHigh: Color(0xFF93B6D2),
    skyLow: Color(0xFFD3E1E8),
    horizonWarm: Color(0xFFEFDCB8),
    nightHigh: Color(0xFF16202F),
    nightLow: Color(0xFF283549),
    nightHorizon: Color(0xFF4A4E5E),
    moonlight: Color(0xFFF0EBDF),
    rock: Color(0xFF6B7385),
    foliage: Color(0xFF9A7434),
    waterTint: Color(0xFF8FAEBE),
    bank: Color(0xFFA08245),
    density: 0.78,
    bough: BoughDress.turned,
    blossom: Color(0xFFC96F2C),
    flowers: [
      FlowerPlanting(
        form: FlowerForm.seedHead,
        colour: Color(0xFFB08A4E),
        centre: Color(0xFF8A6A34),
        share: 0.50,
      ),
      FlowerPlanting(
        form: FlowerForm.umbel,
        colour: Color(0xFFD9C79A),
        centre: Color(0xFFB49A64),
        share: 0.25,
      ),
    ],
  );

  /// **Winter.** Quieter and sparser: the same bank with less standing on
  /// it, cool muted tones, and more of the shoreline showing through
  /// because there is less in front of it.
  static const _winter = _SeasonTints(
    skyHigh: Color(0xFFA8BFD4),
    skyLow: Color(0xFFDCE6EC),
    horizonWarm: Color(0xFFEDE4D6),
    nightHigh: Color(0xFF141E31),
    nightLow: Color(0xFF223047),
    nightHorizon: Color(0xFF41536B),
    moonlight: Color(0xFFF2F6FB),
    rock: Color(0xFF7C8CA0),
    foliage: Color(0xFF7E8C78),
    waterTint: Color(0xFFA6BECE),
    bank: Color(0xFFBFC4BA),
    density: 0.38,
    bough: BoughDress.bare,
    blossom: Color(0xFFD8CFC0),
    flowers: [
      FlowerPlanting(
        form: FlowerForm.seedHead,
        colour: Color(0xFF9E9484),
        centre: Color(0xFF7D7365),
        share: 0.55,
      ),
    ],
  );
}
