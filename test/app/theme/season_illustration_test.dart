import 'package:almanac/app/theme/season_illustration.dart';
import 'package:almanac/app/theme/seasonal_palettes.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/contrast.dart';

/// WCAG AA for body text, which is what sits on a recipe card.
const _textMinimum = 4.5;

/// WCAG AA for graphical objects, which is what a sprig is.
const _graphicalMinimum = 3.0;

void main() {
  group('a season card, in every season and at every hour', () {
    for (final active in SeasonalPalettes.all) {
      group(active.name, () {
        for (final season in Season.values) {
          test('${season.label} can be read', () {
            final wash = seasonWash(active, season);
            final ratio = contrastRatio(active.textPrimary, wash);

            expect(
              ratio,
              greaterThanOrEqualTo(_textMinimum),
              reason:
                  '${active.name}: body text on a ${season.label} card is '
                  '${ratio.toStringAsFixed(2)}:1',
            );
          });

          test('${season.label}\'s sprig can be made out', () {
            final ink = seasonInk(active, season);
            final ratio = contrastRatio(ink, seasonWash(active, season));

            expect(
              ratio,
              greaterThanOrEqualTo(_graphicalMinimum),
              reason:
                  '${active.name}: the ${season.label} sprig is '
                  '${ratio.toStringAsFixed(2)}:1 on its card',
            );
          });
        }

        test('the four cards are not all the same', () {
          final washes = {
            for (final season in Season.values) seasonWash(active, season),
          };
          final inks = {
            for (final season in Season.values) seasonInk(active, season),
          };

          // Four seasons should look like four seasons. A wash can fall
          // back to the plain surface when contrast demands it, so the
          // sprigs are the part that must always differ.
          expect(inks, hasLength(4), reason: active.name);
          expect(washes.length, greaterThanOrEqualTo(2), reason: active.name);
        });

        test('a card is a gentle tint of the surface, not a block', () {
          for (final season in Season.values) {
            final wash = seasonWash(active, season);
            // Close enough to the card colour that the page still reads
            // as one page.
            expect(
              contrastRatio(wash, active.surface),
              lessThan(1.6),
              reason: '${active.name}: ${season.label}',
            );
          }
        });
      });
    }
  });

  group('the season being shown', () {
    test('is lit the same way the page around it is', () {
      // A winter card in midsummer is still winter, but it is not lit
      // for a different time of day than the screen it sits on.
      expect(
        paletteForSeason(SummerPalettes.day, Season.winter).brightness,
        Brightness.light,
      );
      expect(
        paletteForSeason(SummerPalettes.night, Season.winter).brightness,
        Brightness.dark,
      );
      expect(
        paletteForSeason(WinterPalettes.night, Season.spring),
        SpringPalettes.night,
      );
    });

    test('is the season asked for, not the one in force', () {
      for (final season in Season.values) {
        expect(
          paletteForSeason(SummerPalettes.day, season),
          SeasonalPalettes.resolve(season: season, daylight: 1),
        );
      }
    });
  });
}
