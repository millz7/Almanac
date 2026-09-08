import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/app/theme/colour_contrast.dart';
import 'package:almanac/core/widgets/widgets.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the paper an inner page is written on', () {
    test('is one warm cream, identical in all eight palettes', () {
      // The rule: the Environment changes with the world outside, the
      // pages inside the Almanac remain paper. Every palette — every
      // season, day and night — prints on the same sheet.
      for (final palette in SeasonalPalettes.all) {
        expect(
          AlmanacPaper.reprint(palette).background,
          AlmanacPaper.ground,
          reason: palette.name,
        );
        expect(
          AlmanacPaper.reprint(palette).surface,
          AlmanacPaper.ground,
          reason: palette.name,
        );
      }
      expect(AlmanacPaperSurface.ground, AlmanacPaper.ground);
    });

    test('and the ground does not depend on a palette at all', () {
      // A single set of grounds across eight palettes, not eight
      // grounds that happen to be close.
      expect(
        SeasonalPalettes.all
            .map((p) => AlmanacPaper.reprint(p).background)
            .toSet(),
        hasLength(1),
      );
    });

    test('day and night are the same paper', () {
      final pairs = [
        (SpringPalettes.day, SpringPalettes.night),
        (SummerPalettes.day, SummerPalettes.night),
        (AutumnPalettes.day, AutumnPalettes.night),
        (WinterPalettes.day, WinterPalettes.night),
      ];

      for (final (day, night) in pairs) {
        expect(
          AlmanacPaper.reprint(night).background,
          AlmanacPaper.reprint(day).background,
          reason: '${day.name} vs ${night.name}',
        );
        expect(
          AlmanacPaper.reprint(night).textPrimary,
          AlmanacPaper.reprint(day).textPrimary,
          reason: '${day.name} vs ${night.name}',
        );
      }
    });

    test('and the season does not change it either', () {
      final seasons = [
        SpringPalettes.day,
        SummerPalettes.day,
        AutumnPalettes.day,
        WinterPalettes.day,
      ];

      expect(
        seasons.map((p) => AlmanacPaper.reprint(p).background).toSet(),
        hasLength(1),
      );
    });

    test('it is never interpolated toward a night background', () {
      for (final palette in SeasonalPalettes.all) {
        final paper = AlmanacPaper.reprint(palette).background;

        // Light, warm and unmistakably paper, whatever palette it came
        // from. A night ground would fail all three.
        expect(
          paper.computeLuminance(),
          greaterThan(0.8),
          reason: palette.name,
        );
        expect(paper, isNot(palette.background), reason: palette.name);
        expect(
          AlmanacPaper.reprint(palette).brightness,
          Brightness.light,
          reason: palette.name,
        );
      }
    });
  });

  group('paper is legible', () {
    test('body and secondary ink clear the text floor', () {
      for (final palette in SeasonalPalettes.all) {
        final paper = AlmanacPaper.reprint(palette);

        expect(
          contrastRatio(paper.textPrimary, paper.background),
          greaterThanOrEqualTo(kBodyTextContrast),
          reason: '${palette.name}: body text on paper',
        );
        expect(
          contrastRatio(paper.textSecondary, paper.background),
          greaterThanOrEqualTo(kBodyTextContrast),
          reason: '${palette.name}: secondary text on paper',
        );
      }
    });

    test('and every accent a page can use stays legible on it', () {
      for (final palette in SeasonalPalettes.all) {
        final paper = AlmanacPaper.reprint(palette);

        // The colours a detail page is allowed to take from the season:
        // accent lines, small selected states, illustration detail.
        for (final (name, colour) in [
          ('primary', paper.primary),
          ('secondary', paper.secondary),
          ('accent', paper.accent),
          ('icon', paper.icon),
          ('water', paper.water),
          ('earth', paper.earth),
          ('error', paper.error),
        ]) {
          expect(
            contrastRatio(colour, paper.background),
            greaterThanOrEqualTo(kGraphicalContrast),
            reason: '${palette.name}: $name on paper',
          );
        }
      }
    });

    test('a night palette accent is re-based rather than used as it was', () {
      // The season is still present, but a winter night's primary was
      // chosen to sit on a dark ground and would be a pale smudge here.
      final night = WinterPalettes.night;
      expect(
        contrastRatio(night.primary, AlmanacPaper.ground),
        lessThan(kGraphicalContrast),
      );
      expect(
        contrastRatio(
          AlmanacPaper.accentOn(night.primary),
          AlmanacPaper.ground,
        ),
        greaterThanOrEqualTo(kGraphicalContrast),
      );
    });

    test('and a colour already legible on paper is left alone', () {
      // It gives up as little of the hue as the paper demands, so a
      // day palette's accent survives essentially unchanged.
      final day = AutumnPalettes.day;
      expect(
        contrastRatio(AlmanacPaper.accentOn(day.primary), AlmanacPaper.ground),
        greaterThanOrEqualTo(kGraphicalContrast),
      );
      expect(AlmanacPaper.accentOn(day.primary), day.primary);
    });
  });

  group('the paper colour lives in one place', () {
    test('and nothing outside the token file writes it down', () {
      // One token in the theme layer, not a cream scattered through
      // widgets. The value is spelled out here so a copy anywhere else
      // is a failing test rather than a thing somebody notices later.
      expect(AlmanacPaper.ground, const Color(0xFFF7F1E3));

      final elsewhere = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !file.path.endsWith('almanac_paper.dart'))
          .where((file) => file.readAsStringSync().contains('0xFFF7F1E3'));

      expect(
        elsewhere.map((file) => file.path),
        isEmpty,
        reason: 'the paper colour is written down outside its token',
      );
    });
  });
}
