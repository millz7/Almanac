import 'package:flutter/material.dart';

import '../seasonal_palette.dart';

/// PROVISIONAL — placeholder autumn palette.
///
/// These colours exist only to prove the seasonal engine works for a
/// season other than summer. They have **not** been designed: the real
/// autumn identity is a later design step. They are contrast-checked so
/// the app stays readable, and nothing more.
///
/// Replace wholesale. Do not build on these values.
abstract final class AutumnPalettes {
  static const day = SeasonalPalette(
    name: 'Autumn Day',
    brightness: Brightness.light,
    background: Color(0xFFF7F0E2),
    surface: Color(0xFFFCF8EE),
    surfaceElevated: Color(0xFFFFFDF7),
    primary: Color(0xFF8A4A2B),
    onPrimary: Color(0xFFF7F0E2),
    primarySoft: Color(0xFFEFDCC4),
    onPrimarySoft: Color(0xFF5C3A24),
    secondary: Color(0xFF6E6231),
    onSecondary: Color(0xFFF7F0E2),
    accent: Color(0xFFE0A03C),
    onAccent: Color(0xFF2E1A0C),
    textPrimary: Color(0xFF33220F),
    textSecondary: Color(0xFF6B5940),
    border: Color(0xFF93794D),
    icon: Color(0xFF8A4A2B),
    water: Color(0xFF4E7F86),
    earth: Color(0xFF7A4A22),
    disabled: Color(0xFFEDE3D0),
    onDisabled: Color(0xFF857154),
    error: Color(0xFFA8442A),
    onError: Color(0xFFF7F0E2),
  );

  static const night = SeasonalPalette(
    name: 'Autumn Night',
    brightness: Brightness.dark,
    background: Color(0xFF1E1712),
    surface: Color(0xFF291F18),
    surfaceElevated: Color(0xFF342821),
    primary: Color(0xFFD08A5C),
    onPrimary: Color(0xFF1E1712),
    primarySoft: Color(0xFF3E2C20),
    onPrimarySoft: Color(0xFFE7C4A4),
    secondary: Color(0xFFB0A05C),
    onSecondary: Color(0xFF1A1608),
    accent: Color(0xFFE8B45E),
    onAccent: Color(0xFF2E1A0C),
    textPrimary: Color(0xFFF1E7D8),
    textSecondary: Color(0xFFBBA894),
    border: Color(0xFF806852),
    icon: Color(0xFFD08A5C),
    water: Color(0xFF5A8F96),
    earth: Color(0xFFA9713F),
    disabled: Color(0xFF33271F),
    onDisabled: Color(0xFF9C8874),
    error: Color(0xFFE0765A),
    onError: Color(0xFF1A1308),
  );
}
