import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/app/theme/colour_contrast.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the paper a detail page is written on', () {
    test('is legible in every palette, day and night', () {
      for (final palette in SeasonalPalettes.all) {
        final paper = AlmanacPaperSurface.toneOf(palette);

        expect(
          contrastRatio(palette.textPrimary, paper),
          greaterThanOrEqualTo(kBodyTextContrast),
          reason: '${palette.name}: body text on paper',
        );
        expect(
          contrastRatio(palette.textSecondary, paper),
          greaterThanOrEqualTo(kBodyTextContrast),
          reason: '${palette.name}: secondary text on paper',
        );
        expect(
          contrastRatio(palette.primary, paper),
          greaterThanOrEqualTo(kGraphicalContrast),
          reason: '${palette.name}: accent on paper',
        );
      }
    });

    test('is the palette warmed, not a fixed cream', () {
      // A hard cream would be a white sheet held up in a dark room. The
      // paper is the palette's own ground, so a night palette stays a
      // night palette.
      for (final palette in SeasonalPalettes.all) {
        final paper = AlmanacPaperSurface.toneOf(palette);

        expect(
          contrastRatio(paper, palette.background),
          lessThan(1.4),
          reason: '${palette.name}: paper drifted off its own ground',
        );
      }
    });

    test('and it is not simply the background either', () {
      // If it were, the primitive would be doing nothing.
      final drifted = SeasonalPalettes.all.where(
        (palette) => AlmanacPaperSurface.toneOf(palette) != palette.background,
      );
      expect(drifted, hasLength(SeasonalPalettes.all.length));
    });
  });
}
