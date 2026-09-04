import 'package:flutter/material.dart';

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
  @override
  SeasonalPalette lerp(covariant SeasonalPalette? other, double t) {
    if (other == null) return this;

    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;

    return SeasonalPalette(
      // Names and brightness are discrete, so they switch at the midpoint
      // rather than blending.
      name: t < 0.5 ? name : other.name,
      brightness: t < 0.5 ? brightness : other.brightness,
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceElevated: mix(surfaceElevated, other.surfaceElevated),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      primarySoft: mix(primarySoft, other.primarySoft),
      onPrimarySoft: mix(onPrimarySoft, other.onPrimarySoft),
      secondary: mix(secondary, other.secondary),
      onSecondary: mix(onSecondary, other.onSecondary),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      border: mix(border, other.border),
      icon: mix(icon, other.icon),
      water: mix(water, other.water),
      earth: mix(earth, other.earth),
      disabled: mix(disabled, other.disabled),
      onDisabled: mix(onDisabled, other.onDisabled),
      error: mix(error, other.error),
      onError: mix(onError, other.onError),
    );
  }

  @override
  String toString() => 'SeasonalPalette($name)';
}
