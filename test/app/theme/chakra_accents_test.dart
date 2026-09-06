import 'package:almanac/app/theme/chakra_accents.dart';
import 'package:almanac/app/theme/seasonal_palettes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/contrast.dart';

/// WCAG AA for graphical objects, which is what a chakra point is.
const _uiMinimum = 3.0;

/// How far an accent may drift from its traditional hue before it stops
/// being that colour. Thirty degrees is about a fifth of the way to the
/// next named colour.
const _hueTolerance = 30.0;

double _hueOf(Color colour) => HSLColor.fromColor(colour).hue;

/// Shortest distance between two hue angles, 0–180.
double _hueDistance(double a, double b) {
  final raw = (a - b).abs() % 360;
  return raw > 180 ? 360 - raw : raw;
}

void main() {
  group('every chakra accent, in every season and at every hour', () {
    for (final palette in SeasonalPalettes.all) {
      group(palette.name, () {
        for (final hue in ChakraHue.values) {
          test('${hue.label} is legible on the page', () {
            final ratio = contrastRatio(
              palette.chakraAccent(hue),
              palette.background,
            );
            expect(
              ratio,
              greaterThanOrEqualTo(_uiMinimum),
              reason:
                  '${palette.name}: ${hue.label} is '
                  '${ratio.toStringAsFixed(2)}:1 on the page',
            );
          });

          test('${hue.label} still looks like ${hue.label}', () {
            final distance = _hueDistance(
              _hueOf(palette.chakraAccent(hue)),
              hue.angle,
            );
            expect(
              distance,
              lessThanOrEqualTo(_hueTolerance),
              reason:
                  '${palette.name}: ${hue.label} has drifted '
                  '${distance.toStringAsFixed(1)} degrees',
            );
          });
        }

        test('the seven can be told apart from each other', () {
          for (final a in ChakraHue.values) {
            for (final b in ChakraHue.values) {
              if (a == b) continue;
              final distance = _hueDistance(
                _hueOf(palette.chakraAccent(a)),
                _hueOf(palette.chakraAccent(b)),
              );
              expect(
                distance,
                greaterThan(10),
                reason:
                    '${palette.name}: ${a.label} and ${b.label} are '
                    '${distance.toStringAsFixed(1)} degrees apart',
              );
            }
          }
        });

        test('the glow is a soft, transparent form of the accent', () {
          for (final hue in ChakraHue.values) {
            final accent = palette.chakraAccent(hue);
            final glow = palette.chakraGlow(hue);
            expect(glow.a, lessThan(0.3));
            expect(glow.r, accent.r);
            expect(glow.g, accent.g);
            expect(glow.b, accent.b);
          }
        });
      });
    }
  });

  group('the accents follow the palette they are drawn on', () {
    test('they are darker than a light page and lighter than a dark one', () {
      for (final palette in SeasonalPalettes.all) {
        final ground = relativeLuminance(palette.background);
        for (final hue in ChakraHue.values) {
          final accent = relativeLuminance(palette.chakraAccent(hue));
          if (ground > 0.5) {
            expect(accent, lessThan(ground), reason: palette.name);
          } else {
            expect(accent, greaterThan(ground), reason: palette.name);
          }
        }
      }
    });

    test('day and night are not the same colour', () {
      // The point of deriving accents rather than fixing them: the seven
      // are drawn in the light that is actually falling.
      for (final hue in ChakraHue.values) {
        expect(
          SummerPalettes.day.chakraAccent(hue),
          isNot(SummerPalettes.night.chakraAccent(hue)),
          reason: hue.label,
        );
      }
    });

    test('a blend part-way through dusk still produces a legible accent', () {
      // Dawn and dusk interpolate the palette, so the accents are asked
      // for on grounds that no designed palette contains.
      for (var step = 0; step <= 10; step++) {
        final blended = SummerPalettes.day.lerp(
          SummerPalettes.night,
          step / 10,
        );
        for (final hue in ChakraHue.values) {
          final ratio = contrastRatio(
            blended.chakraAccent(hue),
            blended.background,
          );
          expect(
            ratio,
            greaterThanOrEqualTo(_uiMinimum),
            reason:
                '${hue.label} at ${step / 10} through dusk is '
                '${ratio.toStringAsFixed(2)}:1',
          );
        }
      }
    });
  });
}
