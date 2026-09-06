import 'package:flutter/material.dart';

import 'seasonal_palette.dart';

/// The seven traditional chakra colours, as illustration tokens.
///
/// Each carries two things: the **word** for the colour, so nothing in
/// the app ever depends on a user seeing it, and the hue it is drawn in.
/// The hue is an angle rather than a hex value because the colour that
/// actually gets painted is worked out against the season in force — see
/// [ChakraAccents.chakraAccent].
enum ChakraHue {
  red('red', 6),
  orange('orange', 28),
  yellow('yellow', 46),
  green('green', 132),
  blue('blue', 205),
  indigo('indigo', 252),
  violet('violet', 288);

  const ChakraHue(this.label, this.angle);

  /// The colour's name in plain words, e.g. "red".
  final String label;

  /// Where the hue sits on the colour wheel, 0–360.
  final double angle;
}

/// How saturated a chakra accent is allowed to be.
///
/// The app is muted — sunlit ochres, sea greens, dusk blues — and a
/// primary-school rainbow dropped on top of it would look like a
/// different application. Half saturation keeps each hue recognisable as
/// the traditional colour without shouting.
const _saturation = 0.46;

/// How much of the season is stirred into every accent.
///
/// Small on purpose: enough that the seven feel drawn in the same ink as
/// the rest of the app, not so much that green stops looking green.
/// `chakra_accents_test.dart` holds each accent within 30 degrees of its
/// traditional hue.
const _seasonBlend = 0.12;

/// Where an accent starts before it is checked for legibility: darker
/// than the page on a light palette, lighter than it on a dark one.
const _lightnessOnLightGround = 0.40;
const _lightnessOnDarkGround = 0.64;

/// The floor an accent must clear against the ground it is drawn on.
/// 3:1 is the WCAG AA bar for graphical objects, which is what these are.
const _minimumContrast = 3.0;

/// Chakra colours, derived from the palette in force rather than fixed.
///
/// This is the only place in the app that knows what colour a chakra is.
/// Widgets ask the palette for an accent and get one that already suits
/// the season and the time of day, so there are no hex values scattered
/// through the chakra screens and nothing to keep in step by hand.
extension ChakraAccents on SeasonalPalette {
  /// The colour to draw [hue] in, on this palette's [background].
  ///
  /// Built in three steps: take the traditional hue at the app's muted
  /// saturation, stir in a little of the season's own primary, then push
  /// it away from the page until it clears 3:1 — so it stays a graphical
  /// object anyone can make out, in winter at night as well as at noon
  /// in summer.
  Color chakraAccent(ChakraHue hue) {
    final onLightGround = background.computeLuminance() > 0.5;
    final base = HSLColor.fromAHSL(
      1,
      hue.angle,
      _saturation,
      onLightGround ? _lightnessOnLightGround : _lightnessOnDarkGround,
    ).toColor();

    final seasoned = Color.lerp(base, primary, _seasonBlend)!;
    return _legibleOn(seasoned, background);
  }

  /// The same colour as a soft halo, for glow behind a point or a symbol.
  ///
  /// Decorative only. It carries no information on its own and is never
  /// the sole signal of anything.
  Color chakraGlow(ChakraHue hue) => chakraAccent(hue).withValues(alpha: 0.16);
}

/// Moves [colour] away from [ground] until it is legible against it.
///
/// Tries darkening and lightening and keeps whichever reads better,
/// rather than assuming a light page wants a dark accent. That assumption
/// holds for the eight designed palettes but breaks in the middle of dawn
/// and dusk, where the ground is a mid-tone the app never sits at for
/// long: there, one direction runs out of room at about 2:1 while the
/// other clears the bar comfortably.
///
/// It moves in small lightness increments rather than jumping to black or
/// white, so an accent gives up as little of its hue as the ground
/// demands.
Color _legibleOn(Color colour, Color ground) {
  final darker = _stepUntilLegible(colour, ground, -_step);
  if (_contrastRatio(darker, ground) >= _minimumContrast) return darker;

  final lighter = _stepUntilLegible(colour, ground, _step);
  return _contrastRatio(lighter, ground) > _contrastRatio(darker, ground)
      ? lighter
      : darker;
}

/// How far each attempt moves the lightness.
const _step = 0.02;

Color _stepUntilLegible(Color colour, Color ground, double step) {
  var hsl = HSLColor.fromColor(colour);

  for (var i = 0; i < 50; i++) {
    if (_contrastRatio(hsl.toColor(), ground) >= _minimumContrast) break;
    final lightness = (hsl.lightness + step).clamp(0.0, 1.0);
    if (lightness == hsl.lightness) break;
    hsl = hsl.withLightness(lightness);
  }

  return hsl.toColor();
}

/// WCAG relative-luminance contrast ratio, 1:1 to 21:1.
double _contrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}
