import 'package:flutter/material.dart';

import '../seasonal_palette.dart';

/// PROVISIONAL — placeholder winter palette.
///
/// These colours exist only to prove the seasonal engine works for a
/// season other than summer. They have **not** been designed: the real
/// winter identity is a later design step. They are contrast-checked so
/// the app stays readable, and nothing more.
///
/// Replace wholesale. Do not build on these values.
abstract final class WinterPalettes {
  static const day = SeasonalPalette(
    name: 'Winter Day',
    brightness: Brightness.light,
    background: Color(0xFFEFF2F4),
    surface: Color(0xFFF7F9FA),
    surfaceElevated: Color(0xFFFFFFFF),
    primary: Color(0xFF3A5B70),
    onPrimary: Color(0xFFEFF2F4),
    primarySoft: Color(0xFFD7E1E8),
    onPrimarySoft: Color(0xFF23384A),
    secondary: Color(0xFF5C5A63),
    onSecondary: Color(0xFFEFF2F4),
    accent: Color(0xFF7FA9BF),
    onAccent: Color(0xFF16242D),
    textPrimary: Color(0xFF1C2429),
    textSecondary: Color(0xFF4E585F),
    border: Color(0xFF73838D),
    icon: Color(0xFF3A5B70),
    water: Color(0xFF4A7E96),
    earth: Color(0xFF6B5F52),
    disabled: Color(0xFFE1E6E9),
    onDisabled: Color(0xFF6E777D),
    error: Color(0xFFA8442A),
    onError: Color(0xFFEFF2F4),
  );

  static const night = SeasonalPalette(
    name: 'Winter Night',
    brightness: Brightness.dark,
    background: Color(0xFF10171C),
    surface: Color(0xFF182127),
    surfaceElevated: Color(0xFF212C33),
    primary: Color(0xFF8FB3C7),
    onPrimary: Color(0xFF10171C),
    primarySoft: Color(0xFF22333D),
    onPrimarySoft: Color(0xFFBBD4E1),
    secondary: Color(0xFF9A98A4),
    onSecondary: Color(0xFF14161A),
    accent: Color(0xFFA9CBDD),
    onAccent: Color(0xFF16242D),
    textPrimary: Color(0xFFE6EDF1),
    textSecondary: Color(0xFFA6B4BC),
    border: Color(0xFF5C7280),
    icon: Color(0xFF8FB3C7),
    water: Color(0xFF5A93AC),
    earth: Color(0xFF8C7A68),
    disabled: Color(0xFF232C32),
    onDisabled: Color(0xFF87949C),
    error: Color(0xFFE0765A),
    onError: Color(0xFF14161A),
  );
}
