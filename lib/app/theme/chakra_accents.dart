import 'package:flutter/material.dart';

import 'colour_contrast.dart';
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

/// The floor an accent must clear against the ground it is drawn on:
/// the WCAG AA bar for graphical objects, which is what these are.
const _minimumContrast = kGraphicalContrast;

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
    return legibleOn(seasoned, background, minimum: _minimumContrast);
  }

  /// The same colour as a soft halo, for glow behind a point or a symbol.
  ///
  /// Decorative only. It carries no information on its own and is never
  /// the sole signal of anything.
  Color chakraGlow(ChakraHue hue) => chakraAccent(hue).withValues(alpha: 0.16);
}
