import 'package:flutter/material.dart';

/// Central colour tokens for the app.
///
/// The palette is drawn from the natural landscape: cream/parchment
/// grounds, sage/moss/fern greens, soil/bark/clay browns, and sky/ocean
/// blue used sparingly as an accent. Widgets should always reference
/// these tokens (or the [ColorScheme] built from them in `app_theme.dart`)
/// rather than hard-coding colour values.
abstract final class AppColors {
  // Cream / parchment — grounds and surfaces.
  static const cream = Color(0xFFFAF3E7);
  static const parchment = Color(0xFFF1E8D8);
  static const sand = Color(0xFFE9DEC7);

  // Greens — primary natural colour, used as the main brand colour.
  static const moss = Color(0xFF4F6444);
  static const fern = Color(0xFF7C9473);
  static const fernLight = Color(0xFFDCE6D2);
  static const forestDeep = Color(0xFF243019);
  static const sage = Color(0xFFA9B79E);

  // Browns — earth tones, used as the secondary natural colour.
  static const soil = Color(0xFF3A2E22);
  static const bark = Color(0xFF6B5744);
  static const clay = Color(0xFFA97C50);

  // Blues — an accent only. Never let blue dominate a screen.
  static const sky = Color(0xFF6FA1B8);
  static const ocean = Color(0xFF3E7189);
  static const oceanDeep = Color(0xFF1D3A44);
  static const rain = Color(0xFFD9E7EC);

  // Neutrals for text and outlines, warmed to sit with the palette above.
  static const textPrimary = Color(0xFF2E2A22);
  static const textSecondary = Color(0xFF6B6355);
  static const outline = Color(0xFFB7AC98);

  // A muted, earthy warning/error tone — never a saturated red.
  static const rust = Color(0xFFB3543A);
  static const rustLight = Color(0xFFF3DDD5);
}
