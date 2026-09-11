import 'package:almanac/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme.fromPalette', () {
    test('carries the palette so any widget can read its tokens', () {
      final theme = AppTheme.fromPalette(SummerPalettes.night);

      expect(theme.extension<SeasonalPalette>(), same(SummerPalettes.night));
    });

    test('maps semantic tokens onto Material colour roles', () {
      const palette = SummerPalettes.day;
      final theme = AppTheme.fromPalette(palette);

      expect(theme.scaffoldBackgroundColor, palette.background);
      expect(theme.colorScheme.surface, palette.background);
      expect(theme.colorScheme.onSurface, palette.textPrimary);
      expect(theme.colorScheme.primary, palette.primary);
      expect(theme.colorScheme.onPrimary, palette.onPrimary);
      expect(theme.colorScheme.secondary, palette.secondary);
      expect(theme.colorScheme.tertiary, palette.accent);
      expect(theme.colorScheme.outline, palette.border);
      // A card is a passage tinted *into* the page, not a sheet laid on
      // top of it — so it takes the inset surface, and carries no
      // shadow and no surface tint of its own.
      expect(theme.cardTheme.color, palette.surfaceElevated);
      expect(theme.cardTheme.elevation, AppElevation.none);
      expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
    });

    test('brightness follows the palette, so system UI adapts', () {
      expect(
        AppTheme.fromPalette(SummerPalettes.day).brightness,
        Brightness.light,
      );
      expect(
        AppTheme.fromPalette(SummerPalettes.night).brightness,
        Brightness.dark,
      );
    });

    test('text colours come from the palette', () {
      const palette = WinterPalettes.night;
      final theme = AppTheme.fromPalette(palette);

      expect(theme.textTheme.bodyLarge?.color, palette.textPrimary);
      expect(theme.textTheme.bodySmall?.color, palette.textSecondary);
    });

    test('typography metrics are identical across every season and phase', () {
      // The app must read as the same publication all year: only colour
      // changes with the season, never the type.
      final reference = AppTheme.fromPalette(SeasonalPalettes.all.first)
          .textTheme;

      for (final palette in SeasonalPalettes.all.skip(1)) {
        final textTheme = AppTheme.fromPalette(palette).textTheme;

        for (final pair in [
          (reference.displayLarge, textTheme.displayLarge),
          (reference.headlineMedium, textTheme.headlineMedium),
          (reference.titleLarge, textTheme.titleLarge),
          (reference.bodyLarge, textTheme.bodyLarge),
          (reference.labelSmall, textTheme.labelSmall),
        ]) {
          expect(pair.$2?.fontSize, pair.$1?.fontSize);
          expect(pair.$2?.fontWeight, pair.$1?.fontWeight);
          expect(pair.$2?.height, pair.$1?.height);
          expect(pair.$2?.fontFamily, pair.$1?.fontFamily);
          expect(pair.$2?.letterSpacing, pair.$1?.letterSpacing);
        }
      }
    });

    test('structural tokens do not vary with the season', () {
      for (final palette in SeasonalPalettes.all) {
        final theme = AppTheme.fromPalette(palette);

        expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
        expect(theme.navigationBarTheme.height, AppDimens.navBarHeight);
        expect(theme.appBarTheme.elevation, AppElevation.none);
      }
    });
  });

  group('context.palette', () {
    testWidgets('resolves the palette installed in the theme', (tester) async {
      SeasonalPalette? seen;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.fromPalette(AutumnPalettes.night),
          home: Builder(
            builder: (context) {
              seen = context.palette;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(seen, same(AutumnPalettes.night));
    });
  });

  group('accessibility of the assembled theme', () {
    test('minimum touch target meets accessibility guidance', () {
      expect(AppDimens.minTouchTarget, greaterThanOrEqualTo(48));
    });

    test('buttons are at least as tall as the minimum touch target', () {
      expect(
        AppDimens.buttonHeight,
        greaterThanOrEqualTo(AppDimens.minTouchTarget),
      );
    });
  });
}
