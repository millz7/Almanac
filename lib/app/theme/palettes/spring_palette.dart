import 'package:flutter/material.dart';

import '../seasonal_palette.dart';

/// PROVISIONAL — placeholder spring palette.
///
/// These colours exist only to prove the seasonal engine works for a
/// season other than summer. They have **not** been designed: the real
/// spring identity is a later design step. They are contrast-checked so
/// the app stays readable, and nothing more.
///
/// Replace wholesale. Do not build on these values.
abstract final class SpringPalettes {
  static const day = SeasonalPalette(
    name: 'Spring Day',
    brightness: Brightness.light,
    background: Color(0xFFF4F7EC),
    surface: Color(0xFFFBFDF6),
    surfaceElevated: Color(0xFFFFFFFF),
    primary: Color(0xFF3F6B43),
    onPrimary: Color(0xFFF4F7EC),
    primarySoft: Color(0xFFDCEBD8),
    onPrimarySoft: Color(0xFF24421F),
    secondary: Color(0xFF7A6140),
    onSecondary: Color(0xFFF4F7EC),
    accent: Color(0xFF9CC4E0),
    onAccent: Color(0xFF1E3345),
    textPrimary: Color(0xFF23301F),
    textSecondary: Color(0xFF55604F),
    border: Color(0xFF77856F),
    icon: Color(0xFF3F6B43),
    water: Color(0xFF5D93A8),
    earth: Color(0xFF8A6A45),
    disabled: Color(0xFFE4E8DC),
    onDisabled: Color(0xFF6F7A69),
    error: Color(0xFFA8442A),
    onError: Color(0xFFF4F7EC),
  );

  static const night = SeasonalPalette(
    name: 'Spring Night',
    brightness: Brightness.dark,
    background: Color(0xFF16211A),
    surface: Color(0xFF1D2A20),
    surfaceElevated: Color(0xFF26362A),
    primary: Color(0xFF9BC49A),
    onPrimary: Color(0xFF16211A),
    primarySoft: Color(0xFF2A3E2C),
    onPrimarySoft: Color(0xFFC3DCC0),
    secondary: Color(0xFFC2A277),
    onSecondary: Color(0xFF1A130B),
    accent: Color(0xFF8FB6D2),
    onAccent: Color(0xFF12202B),
    textPrimary: Color(0xFFE8EFE2),
    textSecondary: Color(0xFFA9B7A4),
    border: Color(0xFF5D7861),
    icon: Color(0xFF9BC49A),
    water: Color(0xFF5F97AD),
    earth: Color(0xFFA47C50),
    disabled: Color(0xFF2A362B),
    onDisabled: Color(0xFF8A998A),
    error: Color(0xFFE0765A),
    onError: Color(0xFF1A130B),
  );
}
