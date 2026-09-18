import 'package:flutter/material.dart';

import 'colour_contrast.dart';

/// The app's semantic colour tokens for one season at one point in the day.
///
/// This is the layer that keeps seasons out of the rest of the app. Widgets
/// ask for roles — `background`, `accent`, `water` — and never for a season
/// or a hex value, so a screen written today automatically looks right in
/// winter at night without knowing that winter or night exist.
///
/// It is a [ThemeExtension], so it travels inside [ThemeData]: any widget
/// can reach it with `context.palette`, and Flutter interpolates it for
/// free when the active theme changes.
@immutable
class SeasonalPalette extends ThemeExtension<SeasonalPalette> {
  const SeasonalPalette({
    required this.name,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.onPrimarySoft,
    required this.secondary,
    required this.onSecondary,
    required this.accent,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.icon,
    required this.water,
    required this.earth,
    required this.disabled,
    required this.onDisabled,
    required this.error,
    required this.onError,
  });

  /// e.g. "Summer Day". Shown in the developer preview and used in tests.
  final String name;

  /// Whether this palette is a light or dark interpretation, which drives
  /// system UI (status bar icons) and Material's own defaults.
  final Brightness brightness;

  /// The page ground the whole app sits on.
  final Color background;

  /// Cards and grouped content resting on [background].
  final Color surface;

  /// A surface that needs to read as slightly closer to the viewer.
  final Color surfaceElevated;

  /// The season's main colour, for primary actions and emphasis.
  final Color primary;
  final Color onPrimary;

  /// A gently tinted container carrying primary-coloured content, e.g. the
  /// selected navigation pill or an illustration backdrop.
  final Color primarySoft;
  final Color onPrimarySoft;

  /// The season's supporting colour.
  final Color secondary;
  final Color onSecondary;

  /// The season's brightest note, used sparingly for highlights.
  final Color accent;
  final Color onAccent;

  /// Body and heading text on [background]/[surface].
  final Color textPrimary;

  /// Secondary and supporting text.
  final Color textSecondary;

  /// Outlines and dividers.
  final Color border;

  /// Default icon colour.
  final Color icon;

  /// Natural-element tokens, for imagery, illustrations and future feature
  /// content that needs to reference water or earth specifically.
  ///
  /// These are decorative fills. They are deliberately not held to the
  /// 3:1 contrast bar that interactive elements are — summer's shallow
  /// water on summer's sunlit ground is about 2.3:1 — so never use them
  /// for text, icons or controls, and never let them be the only thing
  /// carrying a piece of information. Use [primary], [icon] or [accent]
  /// for anything a user has to read or act on.
  final Color water;
  final Color earth;

  /// Disabled controls and the text on them.
  final Color disabled;
  final Color onDisabled;

  /// Errors, kept earthy rather than a saturated red.
  final Color error;
  final Color onError;

  @override
  SeasonalPalette copyWith({
    String? name,
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? primary,
    Color? onPrimary,
    Color? primarySoft,
    Color? onPrimarySoft,
    Color? secondary,
    Color? onSecondary,
    Color? accent,
    Color? onAccent,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? icon,
    Color? water,
    Color? earth,
    Color? disabled,
    Color? onDisabled,
    Color? error,
    Color? onError,
  }) {
    return SeasonalPalette(
      name: name ?? this.name,
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primarySoft: primarySoft ?? this.primarySoft,
      onPrimarySoft: onPrimarySoft ?? this.onPrimarySoft,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      icon: icon ?? this.icon,
      water: water ?? this.water,
      earth: earth ?? this.earth,
      disabled: disabled ?? this.disabled,
      onDisabled: onDisabled ?? this.onDisabled,
      error: error ?? this.error,
      onError: onError ?? this.onError,
    );
  }

  /// Blends towards [other]. This is what makes dawn and dusk gradual:
  /// the day and night palettes of a season are interpolated by how much
  /// daylight there is.
  ///
  /// **Grounds blend; content does not.** The backgrounds, surfaces and
  /// decorative fills cross-fade, which is the whole point — a sky that
  /// darkens over three quarters of an hour. Text, icons and the colours
  /// that sit *on* a coloured container do not, because fading them at the
  /// same time is what makes them disappear: a dark text colour and a
  /// light background moving towards each other meet in the middle, and
  /// halfway through dusk the two are the same grey. (They measured
  /// 1.01:1 before this was fixed, which is invisible.) Instead each
  /// content colour is *chosen* — the day one or the night one, whichever
  /// contrasts better with the ground it has landed on. The switch is a
  /// step rather than a fade, and it lands at the moment the two are
  /// equally legible, which is the least conspicuous place for it.
  ///
  /// **What is left.** Right at the crossover the ground itself is a
  /// mid-tone, and no colour a palette actually contains can reach 4.5:1
  /// against it. Measured across all four seasons, the worst point of the
  /// blend is 3.44:1 for body text on the page and 3.11:1 on a card —
  /// past the 3:1 bar for large text, icons and graphical objects, and
  /// short of the 4.5:1 body-text bar, for the few minutes either side of
  /// the midpoint of dawn and dusk. Closing that last gap means designing
  /// the palettes to it, not changing how they blend, so it is recorded
  /// here rather than papered over.
  /// `palette_accessibility_test.dart` holds the floor.
  @override
  SeasonalPalette lerp(covariant SeasonalPalette? other, double t) {
    if (other == null) return this;

    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;

    /// Whichever of [candidates] reads best on [ground].
    Color mostLegibleOn(Color ground, List<Color> candidates) =>
        candidates.reduce(
          (a, b) =>
              _contrastRatio(b, ground) > _contrastRatio(a, ground) ? b : a,
        );

    // ── The page's grounds ────────────────────────────────────────
    //
    // Two things happen here, and both are the Step 18 twilight fix.
    //
    // First the background is nudged out of the narrow mid-tone band
    // where *no* ink can be read at 4.5:1 — see [groundReadableAt]. That
    // band is about 0.1775 to 0.1833 in relative luminance, so escaping
    // it costs a hair of lightness for a few seconds twice a day.
    //
    // Then the surfaces are **tied to it** rather than interpolated
    // separately. Blended independently they drift apart at the
    // crossover — measured at 0.159, 0.183 and higher in one frame of
    // spring's dawn — and grounds that straddle the mid-tone cannot all
    // be served by one ink: whichever way the text goes, one of them
    // fails. Off the crossover the designed surfaces are used exactly as
    // drawn.
    final background = groundReadableAt(mix(this.background, other.background));
    final crossing = (t - 0.5).abs() < 0.25;

    final surface = crossing
        ? background
        : groundReadableAt(mix(this.surface, other.surface));
    // The inset surface leans the way the page already leans — further
    // from the mid-tone, never across it. Stepping it the other way puts
    // the two grounds on opposite sides of the crossover, and then no
    // single ink can clear 4.5:1 on both: whichever way the text goes,
    // one of them fails.
    final surfaceElevated = crossing
        ? _shifted(
            background,
            background.computeLuminance() < 0.18 ? -0.05 : 0.05,
          )
        : groundReadableAt(mix(this.surfaceElevated, other.surfaceElevated));
    final primary = mix(this.primary, other.primary);
    final primarySoft = mix(this.primarySoft, other.primarySoft);
    final secondary = mix(this.secondary, other.secondary);
    final accent = mix(this.accent, other.accent);
    final disabled = mix(this.disabled, other.disabled);
    final error = mix(this.error, other.error);

    // Everything the user reads on the page follows the page itself, so
    // text, icons and outlines flip together rather than one at a time.
    final pageContent =
        _contrastRatio(other.textPrimary, background) >
            _contrastRatio(textPrimary, background)
        ? other
        : this;

    /// The colour to put on [ground], **guaranteed** to clear [floor].
    ///
    /// The better of the two designed options where that is enough; the
    /// strongest content colour either palette has where it is not; and,
    /// when a mid-tone ground defeats even that, the strongest option
    /// stepped away from the ground until it clears the bar (see
    /// [legibleOn] in `colour_contrast.dart`).
    ///
    /// **This last step is the Step 18 twilight fix.** Before it, the
    /// blend picked the best *designed* colour and accepted whatever
    /// ratio that gave — which at the midpoint of dawn and dusk was about
    /// 3.44:1 for body text, 3.11:1 for content on a card and 3.00:1 for
    /// icons. Readable-ish, and below the bar for twenty minutes twice a
    /// day. A colour is now moved rather than shrugged at, and it gives
    /// up as little of its hue as the ground demands.
    Color legibleFor(
      Color ground,
      Color mine,
      Color theirs, {
      double floor = _minimumContentContrast,
    }) {
      final designed = mostLegibleOn(ground, [mine, theirs]);
      if (_contrastRatio(designed, ground) >= floor) return designed;

      final strongest = mostLegibleOn(ground, [
        textPrimary,
        other.textPrimary,
        designed,
      ]);
      if (_contrastRatio(strongest, ground) >= floor) return strongest;

      return legibleOn(strongest, ground, minimum: floor);
    }

    /// An ink that clears the body floor on **every** ground it will be
    /// seen on, not just the first.
    ///
    /// The page has three: the background, the surface and the inset
    /// surface. They are close but not equal, and fixing text against the
    /// background alone left it at 4.47:1 on the surface at one point of
    /// spring's dawn. See [legibleOnAll], which picks a direction once
    /// rather than chasing each ground in turn.
    Color inkOn(List<Color> grounds, Color mine, Color theirs) => legibleOnAll(
      mostLegibleOn(grounds.first, [
        mine,
        theirs,
        textPrimary,
        other.textPrimary,
      ]),
      grounds,
    );

    final pageGrounds = [background, surface, surfaceElevated];

    return SeasonalPalette(
      // The name and the brightness describe which palette is really in
      // force, so they follow the text rather than a fixed midpoint —
      // that keeps the status-bar icons on the same side as the words.
      name: pageContent.name,
      brightness: pageContent.brightness,
      background: background,
      surface: surface,
      surfaceElevated: surfaceElevated,
      primary: primary,
      onPrimary: legibleFor(
        primary,
        onPrimary,
        other.onPrimary,
        floor: kBodyTextContrast,
      ),
      primarySoft: primarySoft,
      onPrimarySoft: legibleFor(
        primarySoft,
        onPrimarySoft,
        other.onPrimarySoft,
        floor: kBodyTextContrast,
      ),
      secondary: secondary,
      onSecondary: legibleFor(
        secondary,
        onSecondary,
        other.onSecondary,
        floor: kBodyTextContrast,
      ),
      accent: accent,
      onAccent: legibleFor(
        accent,
        onAccent,
        other.onAccent,
        floor: kBodyTextContrast,
      ),
      // The page's own words. Stepped if the crossover ground
      // defeats both designed inks: the Environment's masthead, date and
      // tagline are all set in this.
      textPrimary: inkOn(pageGrounds, textPrimary, other.textPrimary),
      // Supporting text and icons are only quieter shades of the same
      // idea, so at the crossover — where a mid-tone ground defeats even
      // the better designed colour — they give up their quietness and
      // borrow the primary. A few minutes of flatter hierarchy beats a
      // few minutes of unreadable captions.
      textSecondary: inkOn(pageGrounds, textSecondary, other.textSecondary),
      // A control boundary — the Almanac ring, the bar's hairline —
      // so it holds the graphical floor rather than following the page.
      border: legibleFor(background, border, other.border),
      icon: legibleFor(background, icon, other.icon),
      // Decorative, and never carrying meaning on their own, so these are
      // free to fade.
      water: mix(water, other.water),
      earth: mix(earth, other.earth),
      disabled: disabled,
      onDisabled: legibleFor(disabled, onDisabled, other.onDisabled),
      error: error,
      onError: legibleFor(
        error,
        onError,
        other.onError,
        floor: kBodyTextContrast,
      ),
    );
  }

  @override
  String toString() => 'SeasonalPalette($name)';
}

/// The floor a content colour must clear against the ground it lands on
/// during a blend, before [SeasonalPalette.lerp] gives up on the designed
/// colour and reaches for the strongest one available.
///
/// 3:1 is the WCAG AA bar for large text, icons and graphical objects. It
/// is what is actually achievable at the moment a light palette and a
/// dark one cross over; see the note on [SeasonalPalette.lerp].
const _minimumContentContrast = 3.0;

/// Moves a colour's lightness by [by], clamped.
///
/// Used during the twilight blend to place the inset surface a fixed step
/// from the page rather than letting it drift to its own mid-tone.
Color _shifted(Color colour, double by) {
  final hsl = HSLColor.fromColor(colour);
  return hsl.withLightness((hsl.lightness + by).clamp(0.0, 1.0)).toColor();
}

/// WCAG relative-luminance contrast ratio, 1:1 to 21:1.
///
/// Used only to decide which of two designed colours to keep during a
/// blend. Note what a ratio can and cannot say: it measures lightness
/// difference only, so two colours of different hue but equal lightness
/// score 1:1. That is fine for this job — picking between a light and a
/// dark option — and is why the palettes themselves are checked by hand
/// as well as by test.
double _contrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}
