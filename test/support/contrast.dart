import 'dart:math' as math;
import 'dart:ui';

/// WCAG 2.1 relative luminance of a colour.
double relativeLuminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4) as double;

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG 2.1 contrast ratio between two colours, from 1.0 (identical) to
/// 21.0 (black on white). Order does not matter.
double contrastRatio(Color a, Color b) {
  final luminanceA = relativeLuminance(a);
  final luminanceB = relativeLuminance(b);
  final lighter = math.max(luminanceA, luminanceB);
  final darker = math.min(luminanceA, luminanceB);
  return (lighter + 0.05) / (darker + 0.05);
}
