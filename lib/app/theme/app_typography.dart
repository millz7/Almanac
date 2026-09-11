import 'package:flutter/material.dart';

import 'almanac_fonts.dart';

/// Typography tokens: the Material [TextTheme] the whole app inherits.
///
/// Pairs an editorial **display** face (titles, dates, phase names —
/// the warm, slightly hand-crafted character of a field almanac's
/// masthead) with the platform's own **text** face for body and UI,
/// which is the most readable thing on any given screen. Which actual
/// typefaces those are is decided in one place, [AlmanacFonts], and no
/// screen names a font.
///
/// Widgets should pull from `Theme.of(context).textTheme` — or, better,
/// from the semantic roles in `almanac_text_roles.dart` — rather than
/// constructing [TextStyle]s of their own, so the scale stays here.
///
/// Typography does **not** change with the season; only its colour does.
/// The app should read as the same publication in January and July.
///
/// Sizes are unchanged from the first implementation. This file's job in
/// Step 17 was to stop the app fetching its fonts over the network (see
/// [AlmanacFonts]), not to reflow every page.
abstract final class AppTypography {
  /// The editorial face, used for everything with a heading's job.
  static const displayStyle = TextStyle(
    fontFamily: AlmanacFonts.display,
    fontFamilyFallback: AlmanacFonts.displayFallback,
  );

  /// The reading face, used for everything a person reads or presses.
  static const textStyle = TextStyle(
    fontFamily: AlmanacFonts.text,
    fontFamilyFallback: AlmanacFonts.textFallback,
  );

  static TextTheme textTheme(Color onSurface, Color onSurfaceMuted) {
    TextStyle display(double size, FontWeight weight, double height) =>
        displayStyle.copyWith(
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: onSurface,
        );

    TextStyle body(
      double size,
      FontWeight weight,
      double height, {
      Color? color,
      double? letterSpacing,
    }) => textStyle.copyWith(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? onSurface,
    );

    return TextTheme(
      displayLarge: display(57, FontWeight.w500, 1.1),
      displayMedium: display(45, FontWeight.w500, 1.12),
      displaySmall: display(36, FontWeight.w500, 1.15),
      headlineLarge: display(32, FontWeight.w500, 1.2),
      headlineMedium: display(28, FontWeight.w500, 1.22),
      headlineSmall: display(24, FontWeight.w600, 1.25),
      titleLarge: display(22, FontWeight.w600, 1.3),
      titleMedium: body(17, FontWeight.w600, 1.4),
      titleSmall: body(15, FontWeight.w600, 1.4),
      bodyLarge: body(17, FontWeight.w400, 1.5),
      bodyMedium: body(15, FontWeight.w400, 1.5),
      bodySmall: body(13, FontWeight.w400, 1.45, color: onSurfaceMuted),
      labelLarge: body(15, FontWeight.w600, 1.3, letterSpacing: 0.2),
      labelMedium: body(
        13,
        FontWeight.w600,
        1.3,
        letterSpacing: 0.2,
        color: onSurfaceMuted,
      ),
      labelSmall: body(
        11,
        FontWeight.w600,
        1.3,
        letterSpacing: 0.4,
        color: onSurfaceMuted,
      ),
    );
  }
}
