import 'package:flutter/material.dart';

/// WCAG relative-luminance contrast ratio, 1:1 to 21:1.
///
/// Note what a ratio can and cannot say: it measures lightness
/// difference only, so two colours of different hue but equal lightness
/// score 1:1. That is exactly what it is used for here — deciding
/// whether something will be legible on the ground it lands on — and is
/// why the palettes themselves are also checked by eye.
double contrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

/// WCAG AA for graphical objects and large text.
const kGraphicalContrast = 3.0;

/// WCAG AA for body text.
const kBodyTextContrast = 4.5;

/// Moves [colour] away from [ground] until it is legible against it.
///
/// Tries darkening and lightening and keeps whichever reads better,
/// rather than assuming a light ground wants a dark mark. That
/// assumption holds for the eight designed palettes but breaks in the
/// middle of dawn and dusk, where the ground is a mid-tone: there, one
/// direction runs out of room at about 2:1 while the other clears the
/// bar comfortably.
///
/// It moves in small lightness increments rather than jumping to black
/// or white, so a colour gives up as little of its hue as the ground
/// demands.
Color legibleOn(
  Color colour,
  Color ground, {
  double minimum = kGraphicalContrast,
}) {
  final darker = _stepUntilLegible(colour, ground, -_step, minimum);
  if (contrastRatio(darker, ground) >= minimum) return darker;

  final lighter = _stepUntilLegible(colour, ground, _step, minimum);
  return contrastRatio(lighter, ground) > contrastRatio(darker, ground)
      ? lighter
      : darker;
}

/// How far each attempt moves the lightness.
const _step = 0.02;

Color _stepUntilLegible(
  Color colour,
  Color ground,
  double step,
  double minimum,
) {
  var hsl = HSLColor.fromColor(colour);

  for (var i = 0; i < 50; i++) {
    if (contrastRatio(hsl.toColor(), ground) >= minimum) break;
    final lightness = (hsl.lightness + step).clamp(0.0, 1.0);
    if (lightness == hsl.lightness) break;
    hsl = hsl.withLightness(lightness);
  }

  return hsl.toColor();
}
