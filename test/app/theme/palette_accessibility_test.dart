import 'package:almanac/app/theme/seasonal_palettes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/contrast.dart';

/// WCAG AA for normal-size body text.
const _textMinimum = 4.5;

/// WCAG AA for user-interface components and graphical objects.
const _uiMinimum = 3.0;

/// Floor for the illustrative `water` and `earth` tokens.
///
/// These are large decorative fills for imagery, not UI components, so
/// WCAG 1.4.11 does not apply to them — and it could not be met anyway
/// while keeping the supplied summer colours, since a mid-tone sage-teal
/// on a pale cream ground tops out around 2.3:1. They must still be
/// clearly distinguishable from the ground, and they must never be used
/// for text, icons or controls: those roles have their own tokens.
const _illustrativeMinimum = 1.8;

void main() {
  group('every seasonal palette is readable', () {
    for (final palette in SeasonalPalettes.all) {
      group(palette.name, () {
        void expectContrast(
          String description,
          Color foreground,
          Color background,
          double minimum,
        ) {
          final ratio = contrastRatio(foreground, background);
          expect(
            ratio,
            greaterThanOrEqualTo(minimum),
            reason:
                '${palette.name}: $description is ${ratio.toStringAsFixed(2)}:1, '
                'below the ${minimum.toStringAsFixed(1)}:1 minimum',
          );
        }

        test('body text on all three surfaces', () {
          expectContrast(
            'textPrimary on background',
            palette.textPrimary,
            palette.background,
            _textMinimum,
          );
          expectContrast(
            'textPrimary on surface',
            palette.textPrimary,
            palette.surface,
            _textMinimum,
          );
          expectContrast(
            'textPrimary on surfaceElevated',
            palette.textPrimary,
            palette.surfaceElevated,
            _textMinimum,
          );
        });

        test('secondary text stays legible', () {
          expectContrast(
            'textSecondary on background',
            palette.textSecondary,
            palette.background,
            _textMinimum,
          );
          expectContrast(
            'textSecondary on surface',
            palette.textSecondary,
            palette.surface,
            _textMinimum,
          );
        });

        test('text on coloured fills', () {
          expectContrast(
            'onPrimary on primary',
            palette.onPrimary,
            palette.primary,
            _textMinimum,
          );
          expectContrast(
            'onPrimarySoft on primarySoft',
            palette.onPrimarySoft,
            palette.primarySoft,
            _textMinimum,
          );
          expectContrast(
            'onSecondary on secondary',
            palette.onSecondary,
            palette.secondary,
            _textMinimum,
          );
          expectContrast(
            'onAccent on accent',
            palette.onAccent,
            palette.accent,
            _textMinimum,
          );
          expectContrast(
            'onError on error',
            palette.onError,
            palette.error,
            _textMinimum,
          );
        });

        test('interactive and graphical elements meet the UI minimum', () {
          expectContrast(
            'border on background',
            palette.border,
            palette.background,
            _uiMinimum,
          );
          expectContrast(
            'icon on background',
            palette.icon,
            palette.background,
            _uiMinimum,
          );
          expectContrast(
            'primary on background',
            palette.primary,
            palette.background,
            _uiMinimum,
          );
          expectContrast(
            'error on background',
            palette.error,
            palette.background,
            _uiMinimum,
          );
        });

        test('the illustrative tokens stay distinguishable', () {
          expectContrast(
            'water on background',
            palette.water,
            palette.background,
            _illustrativeMinimum,
          );
          expectContrast(
            'earth on background',
            palette.earth,
            palette.background,
            _illustrativeMinimum,
          );
          // Water and earth are deliberately similar in lightness and
          // differ in hue, which a contrast ratio cannot measure. So this
          // only checks they are genuinely different colours; the rule
          // that meaning must never rest on hue alone is enforced by
          // always pairing them with a label or icon in the UI.
          expect(palette.water, isNot(palette.earth));
        });

        test('disabled state is visibly distinct but still readable', () {
          expectContrast(
            'onDisabled on disabled',
            palette.onDisabled,
            palette.disabled,
            _uiMinimum,
          );
          // A disabled control must not be mistaken for an enabled one.
          expect(
            contrastRatio(palette.onDisabled, palette.disabled),
            lessThan(contrastRatio(palette.textPrimary, palette.background)),
            reason:
                '${palette.name}: disabled text should read as quieter than '
                'primary text',
          );
        });
      });
    }
  });

  group('night palettes are comfortable in low light', () {
    final nightPalettes = SeasonalPalettes.all.where(
      (palette) => palette.brightness == Brightness.dark,
    );

    test('there is a night palette for all four seasons', () {
      expect(nightPalettes.length, 4);
    });

    for (final palette in nightPalettes) {
      test('${palette.name} avoids pure white on pure black', () {
        expect(
          palette.background,
          isNot(const Color(0xFF000000)),
          reason: 'a pure black ground is harsh; use a deep tinted one',
        );
        expect(
          palette.textPrimary,
          isNot(const Color(0xFFFFFFFF)),
          reason: 'pure white text glares in low light',
        );

        // Very high contrast is uncomfortable at night, so the text should
        // be bright enough to read but not maximally so.
        final ratio = contrastRatio(palette.textPrimary, palette.background);
        expect(ratio, greaterThanOrEqualTo(_textMinimum));
        expect(
          ratio,
          lessThan(20),
          reason: 'approaching 21:1 means white-on-black glare',
        );
      });
    }
  });
}
