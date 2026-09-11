import 'dart:io';

import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/app/theme/colour_contrast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Structural rules about the visual system, not pixels.
///
/// A golden file would fail on every deliberate change and tell nobody
/// why. These assert the rules the system is actually made of: the ink
/// clears its contrast floor, the paper is one colour, a page is built
/// from the shared scaffold, nothing names a font, and nothing fetches
/// one.
void main() {
  group('the paper tokens', () {
    test('body ink is readable on the paper', () {
      // 4.5:1 is the floor for text a person reads.
      for (final (name, ink) in [
        ('ink', AlmanacPaper.ink),
        ('inkMuted', AlmanacPaper.inkMuted),
        ('inkFaint', AlmanacPaper.inkFaint),
      ]) {
        expect(
          contrastRatio(ink, AlmanacPaper.ground),
          greaterThanOrEqualTo(kBodyTextContrast),
          reason: '$name on the paper',
        );
      }
    });

    test('and on the inset ground too', () {
      // An inset passage is still a passage somebody reads.
      for (final (name, ink) in [
        ('ink', AlmanacPaper.ink),
        ('inkMuted', AlmanacPaper.inkMuted),
        ('inkFaint', AlmanacPaper.inkFaint),
      ]) {
        expect(
          contrastRatio(ink, AlmanacPaper.groundInset),
          greaterThanOrEqualTo(kBodyTextContrast),
          reason: '$name on the inset ground',
        );
      }
    });

    test('rules are visible without being borders', () {
      // A rule that must be seen clears the graphical floor; the soft
      // rule is explicitly the one that does not have to.
      expect(
        contrastRatio(AlmanacPaper.rule, AlmanacPaper.ground),
        greaterThanOrEqualTo(kGraphicalContrast),
      );
      expect(
        contrastRatio(AlmanacPaper.softRule, AlmanacPaper.ground),
        lessThan(kGraphicalContrast),
      );
    });

    test('the inset ground is darker than the paper, never lighter', () {
      // A lighter patch reads as a card floating above the page.
      double luminance(Color c) => c.computeLuminance();
      expect(
        luminance(AlmanacPaper.groundInset),
        lessThan(luminance(AlmanacPaper.ground)),
      );
      expect(
        luminance(AlmanacPaper.selection),
        lessThan(luminance(AlmanacPaper.ground)),
      );
    });

    test('and no ink is pure black', () {
      for (final ink in [
        AlmanacPaper.ink,
        AlmanacPaper.inkMuted,
        AlmanacPaper.inkFaint,
        AlmanacPaper.inkDisabled,
      ]) {
        expect(ink, isNot(const Color(0xFF000000)));
      }
    });

    test('there are two grounds, not five', () {
      // Every extra cream is a decision somebody has to make on every
      // page. If a third appears, it should be because a role needed it.
      final grounds = {AlmanacPaper.ground, AlmanacPaper.groundInset};
      expect(grounds, hasLength(2));
    });
  });

  group('fonts are bundled or nothing', () {
    /// Comments stripped. Both the pubspec and `almanac_fonts.dart`
    /// explain in prose why the package is gone, and a test that could
    /// not tell an explanation from a dependency would be useless.
    String codeOf(File file, String commentMarker) => file
        .readAsLinesSync()
        .where((line) => !line.trimLeft().startsWith(commentMarker))
        .join('\n');

    test('the app declares no font package', () {
      // `google_fonts` resolves a face by downloading it from
      // fonts.gstatic.com unless the files are also bundled and runtime
      // fetching is switched off. This app makes no network requests at
      // all, so the dependency cannot come back.
      final pubspec = codeOf(File('pubspec.yaml'), '#');
      expect(pubspec.contains('google_fonts'), isFalse);
    });

    test('and no source file reaches for one', () {
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) {
            final code = codeOf(file, '//');
            return code.contains('GoogleFonts') ||
                code.contains('package:google_fonts');
          })
          .map((file) => file.path);

      expect(offenders, isEmpty);
    });

    test('only one file names a typeface', () {
      final namers =
          Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))
              .where((file) => codeOf(file, '//').contains('fontFamily'))
              .map((file) => file.path)
              .toList()
            ..sort();

      // Exactly one file sets a font family, and it sets it from the
      // slot in `almanac_fonts.dart` rather than from a literal. That is
      // what lets a bundled face be swapped in by changing one constant
      // and touching no screen.
      expect(namers, ['lib/app/theme/app_typography.dart']);
      expect(
        File('lib/app/theme/app_typography.dart').readAsStringSync(),
        contains('AlmanacFonts.display'),
      );
    });

    test('the display slot is a real slot', () {
      // Null today — the platform serif stack — with a fallback that
      // ends in the generic family every engine understands.
      expect(AlmanacFonts.display, AlmanacFonts.bundledDisplay);
      expect(AlmanacFonts.displayFallback.last, 'serif');
    });
  });

  group('the typography roles', () {
    final textTheme = AppTheme.fromPalette(
      AlmanacPaper.reprint(SeasonalPalettes.fallback),
    ).textTheme;

    test('every role resolves to a style', () {
      final roles = <String, TextStyle?>{
        'pageTitle': textTheme.pageTitle,
        'chapterTitle': textTheme.chapterTitle,
        'eyebrow': textTheme.eyebrow,
        'sectionLabel': textTheme.sectionLabel,
        'journalLabel': textTheme.journalLabel,
        'journalNote': textTheme.journalNote,
        'bodyText': textTheme.bodyText,
        'bodyQuiet': textTheme.bodyQuiet,
        'annotation': textTheme.annotation,
        'valueText': textTheme.valueText,
        'valueLabel': textTheme.valueLabel,
        'controlLabel': textTheme.controlLabel,
        'navigationLabel': textTheme.navigationLabel,
      };

      for (final entry in roles.entries) {
        expect(entry.value, isNotNull, reason: entry.key);
        expect(entry.value!.fontSize, isNotNull, reason: entry.key);
      }
    });

    test('body copy is never smaller than the reading floor', () {
      expect(textTheme.bodyText!.fontSize, greaterThanOrEqualTo(15));
      expect(textTheme.bodyQuiet!.fontSize, greaterThanOrEqualTo(15));
    });

    test('navigation is not set in fine print', () {
      // 10pt navigation text is the thing the short labels exist to
      // avoid, so the role itself holds the floor.
      expect(textTheme.navigationLabel!.fontSize, greaterThanOrEqualTo(13));
    });

    test('a title outranks a chapter outranks a label', () {
      expect(
        textTheme.pageTitle!.fontSize,
        greaterThan(textTheme.chapterTitle!.fontSize!),
      );
      expect(
        textTheme.chapterTitle!.fontSize,
        greaterThan(textTheme.sectionLabel!.fontSize!),
      );
    });

    test('values are set in the text face, not the display face', () {
      // A number should be read, not admired.
      expect(
        textTheme.valueText!.fontFamilyFallback,
        AppTypography.textStyle.fontFamilyFallback,
      );
      expect(
        textTheme.journalNote!.fontFamilyFallback,
        AppTypography.displayStyle.fontFamilyFallback,
      );
    });

    test('and the scale does not move with the season', () {
      double? sizeIn(SeasonalPalette palette) =>
          AppTheme.fromPalette(palette).textTheme.pageTitle?.fontSize;

      final sizes = {
        for (final palette in SeasonalPalettes.all) sizeIn(palette),
      };
      expect(sizes, hasLength(1));
    });
  });

  group('the action language', () {
    final theme = AppTheme.fromPalette(SeasonalPalettes.fallback);

    ButtonStyle? styleOf(ButtonStyle? style) => style;

    test('buttons size to their content, not to the page', () {
      // `Size.fromHeight` is `Size(infinity, h)` — which is what made
      // every action in the app a full-width Material pill.
      final minimum = styleOf(theme.elevatedButtonTheme.style)?.minimumSize
          ?.resolve({});
      expect(minimum?.width, 0);
    });

    test('and still clear the minimum touch target', () {
      for (final style in [
        theme.elevatedButtonTheme.style,
        theme.outlinedButtonTheme.style,
        theme.textButtonTheme.style,
      ]) {
        expect(
          styleOf(style)?.minimumSize?.resolve({})?.height,
          greaterThanOrEqualTo(AppDimens.minTouchTarget),
        );
      }
    });

    test('nothing is raised off the page', () {
      expect(theme.cardTheme.elevation, AppElevation.none);
      expect(
        styleOf(theme.elevatedButtonTheme.style)?.elevation?.resolve({}),
        AppElevation.none,
      );
    });
  });

  group('one section language', () {
    test('the old SectionHeader is gone, not duplicated', () {
      // Two implementations of "a small heading" is how two features
      // end up with two different ones.
      expect(
        File('lib/core/widgets/section_header.dart').existsSync(),
        isFalse,
      );

      final users = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => file.readAsStringSync().contains('SectionHeader'))
          .map((file) => file.path);

      expect(users, isEmpty);
    });
  });
}
