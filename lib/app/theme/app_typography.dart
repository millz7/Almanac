import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography tokens.
///
/// Pairs an editorial serif ([Fraunces], for headings and display text —
/// it has the warm, slightly hand-crafted character of a nature magazine
/// masthead) with a clean, highly readable sans-serif ([Inter], for body
/// and UI text). Widgets should pull from a [TextTheme] via
/// `Theme.of(context).textTheme` rather than constructing [TextStyle]s
/// directly, so sizes stay centralised here.
abstract final class AppTypography {
  static TextTheme textTheme(Color onSurface, Color onSurfaceMuted) {
    final display = GoogleFonts.frauncesTextTheme();
    final body = GoogleFonts.interTextTheme();

    return TextTheme(
      displayLarge: display.displayLarge?.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w500,
        height: 1.1,
        color: onSurface,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w500,
        height: 1.12,
        color: onSurface,
      ),
      displaySmall: display.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w500,
        height: 1.15,
        color: onSurface,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: onSurface,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        height: 1.22,
        color: onSurface,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: onSurface,
      ),
      titleLarge: display.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: onSurface,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: onSurface,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: onSurface,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: onSurface,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: onSurface,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: onSurfaceMuted,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.2,
        color: onSurface,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.2,
        color: onSurfaceMuted,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.4,
        color: onSurfaceMuted,
      ),
    );
  }

  static TextTheme get light =>
      textTheme(AppColors.textPrimary, AppColors.textSecondary);
}
