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

/// Moves [colour] until it is legible on **every** ground it will be
/// seen on.
///
/// A page has more than one ground — the background, the surface, the
/// inset surface — and they are close but not equal. Fixing an ink
/// against one of them can leave it a whisker short on another: during
/// spring's dawn, text fixed against the background alone measured
/// 4.47:1 on the surface.
///
/// The direction is chosen **once**, by trying both and keeping whichever
/// ends up better against the worst ground. Stepping per-ground instead
/// lets the colour oscillate — one pass darkens it for the background,
/// the next lightens it for the surface — and it converges on nothing.
Color legibleOnAll(
  Color colour,
  List<Color> grounds, {
  double minimum = kBodyTextContrast,
}) {
  if (grounds.isEmpty) return colour;

  double worstOn(Color candidate) => grounds
      .map((ground) => contrastRatio(candidate, ground))
      .reduce((a, b) => a < b ? a : b);

  if (worstOn(colour) >= minimum) return colour;

  final darker = _stepAllUntilLegible(colour, grounds, -_step, minimum);
  if (worstOn(darker) >= minimum) return darker;

  final lighter = _stepAllUntilLegible(colour, grounds, _step, minimum);
  return worstOn(lighter) > worstOn(darker) ? lighter : darker;
}

Color _stepAllUntilLegible(
  Color colour,
  List<Color> grounds,
  double step,
  double minimum,
) {
  var hsl = HSLColor.fromColor(colour);

  for (var i = 0; i < 50; i++) {
    final worst = grounds
        .map((ground) => contrastRatio(hsl.toColor(), ground))
        .reduce((a, b) => a < b ? a : b);
    if (worst >= minimum) break;

    final lightness = (hsl.lightness + step).clamp(0.0, 1.0);
    if (lightness == hsl.lightness) break;
    hsl = hsl.withLightness(lightness);
  }

  return hsl.toColor();
}

/// The best contrast any ink could possibly reach on [ground].
///
/// Black gives `(L + 0.05) / 0.05`; white gives `1.05 / (L + 0.05)`.
/// Whichever is larger is the ceiling — no ink can do better.
double bestPossibleContrastOn(Color ground) {
  final luminance = ground.computeLuminance();
  final withBlack = (luminance + 0.05) / 0.05;
  final withWhite = 1.05 / (luminance + 0.05);
  return withBlack > withWhite ? withBlack : withWhite;
}

/// Nudges a **ground** out of the narrow band where no ink can be read on
/// it at [minimum].
///
/// This is the other half of the twilight fix, and the half that actually
/// mattered. Dawn and dusk blend a light palette's background with a dark
/// one's, and for a few seconds the result passes through a mid-tone. A
/// mid-tone ground has a *ceiling*: at a relative luminance of about
/// 0.18, black reaches 4.6:1 and white reaches 4.5:1, and between roughly
/// 0.1775 and 0.1833 neither reaches 4.5:1 at all. No amount of stepping
/// the ink can fix that, because the problem is the paper, not the pen.
///
/// The band is very narrow, so escaping it costs a hair of lightness for
/// a few seconds twice a day — far less than the page being unreadable.
Color groundReadableAt(Color ground, {double minimum = kBodyTextContrast}) {
  if (bestPossibleContrastOn(ground) >= minimum) return ground;

  // Leave by the nearer door: darker if it is already dark, lighter if
  // it is already light, so the ground keeps moving the way it was going.
  final step = ground.computeLuminance() < 0.18 ? -_step : _step;

  var hsl = HSLColor.fromColor(ground);
  for (var i = 0; i < 50; i++) {
    if (bestPossibleContrastOn(hsl.toColor()) >= minimum) break;
    final lightness = (hsl.lightness + step).clamp(0.0, 1.0);
    if (lightness == hsl.lightness) break;
    hsl = hsl.withLightness(lightness);
  }
  return hsl.toColor();
}
