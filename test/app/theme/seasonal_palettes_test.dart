import 'package:almanac/app/theme/seasonal_palettes.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('summer palette uses the supplied reference colours', () {
    test('every supplied colour appears in the summer day palette', () {
      const palette = SummerPalettes.day;
      final used = <Color>{
        palette.background,
        palette.surface,
        palette.surfaceElevated,
        palette.primary,
        palette.onPrimary,
        palette.primarySoft,
        palette.onPrimarySoft,
        palette.secondary,
        palette.onSecondary,
        palette.accent,
        palette.onAccent,
        palette.textPrimary,
        palette.textSecondary,
        palette.border,
        palette.icon,
        palette.water,
        palette.earth,
      };

      for (final reference in SummerReferenceColors.all) {
        expect(
          used,
          contains(reference),
          reason:
              'supplied summer colour '
              '#${reference.toARGB32().toRadixString(16).substring(2).toUpperCase()} '
              'is not used anywhere in the summer day palette',
        );
      }
    });

    test('the supplied hex values are exactly as provided', () {
      expect(SummerReferenceColors.sunlitCream, const Color(0xFFFFF8BF));
      expect(SummerReferenceColors.sun, const Color(0xFFFCD574));
      expect(SummerReferenceColors.clay, const Color(0xFFD28F54));
      expect(SummerReferenceColors.earth, const Color(0xFF834530));
      expect(SummerReferenceColors.shallowWater, const Color(0xFF82AE9E));
      expect(SummerReferenceColors.deepWater, const Color(0xFF27555A));
    });

    test('summer night is a distinct interpretation, not a dimmed copy', () {
      const day = SummerPalettes.day;
      const night = SummerPalettes.night;

      expect(night.brightness, Brightness.dark);
      expect(night.background, isNot(day.background));
      // It still keeps summer's own colours rather than becoming generic:
      // the shallow water becomes the luminous element at night.
      expect(night.primary, SummerReferenceColors.shallowWater);
    });
  });

  group('palette selection', () {
    test('summer + day resolves to the summer day palette', () {
      final palette = SeasonalPalettes.resolve(
        season: Season.summer,
        daylight: 1,
      );

      expect(palette, same(SummerPalettes.day));
      expect(palette.name, 'Summer Day');
    });

    test('summer + night resolves to the summer night palette', () {
      final palette = SeasonalPalettes.resolve(
        season: Season.summer,
        daylight: 0,
      );

      expect(palette, same(SummerPalettes.night));
      expect(palette.name, 'Summer Night');
    });

    test('a provisional season resolves independently of summer', () {
      expect(
        SeasonalPalettes.resolve(season: Season.winter, daylight: 1),
        same(WinterPalettes.day),
      );
      expect(
        SeasonalPalettes.resolve(season: Season.winter, daylight: 0),
        same(WinterPalettes.night),
      );
      expect(
        SeasonalPalettes.resolve(season: Season.spring, daylight: 1),
        same(SpringPalettes.day),
      );
      expect(
        SeasonalPalettes.resolve(season: Season.autumn, daylight: 0),
        same(AutumnPalettes.night),
      );
    });

    test('every season maps to its own pair of palettes', () {
      for (final season in Season.values) {
        final set = SeasonalPalettes.forSeason(season);

        expect(set.day.brightness, Brightness.light);
        expect(set.night.brightness, Brightness.dark);
        expect(set.day.name, startsWith(season.label));
        expect(set.night.name, startsWith(season.label));
      }
    });

    test('out-of-range daylight is clamped rather than throwing', () {
      expect(
        SeasonalPalettes.resolve(season: Season.autumn, daylight: 5),
        same(AutumnPalettes.day),
      );
      expect(
        SeasonalPalettes.resolve(season: Season.autumn, daylight: -2),
        same(AutumnPalettes.night),
      );
    });
  });

  group('twilight blending', () {
    test('mid-transition sits between the two designed palettes', () {
      final blended = SeasonalPalettes.resolve(
        season: Season.summer,
        daylight: 0.5,
      );

      expect(blended.background, isNot(SummerPalettes.day.background));
      expect(blended.background, isNot(SummerPalettes.night.background));

      final expected = Color.lerp(
        SummerPalettes.night.background,
        SummerPalettes.day.background,
        0.5,
      );
      expect(blended.background, expected);
    });

    test('brightness switches at the halfway point rather than blending', () {
      expect(
        SeasonalPalettes.resolve(
          season: Season.summer,
          daylight: 0.2,
        ).brightness,
        Brightness.dark,
      );
      expect(
        SeasonalPalettes.resolve(
          season: Season.summer,
          daylight: 0.8,
        ).brightness,
        Brightness.light,
      );
    });
  });
}
