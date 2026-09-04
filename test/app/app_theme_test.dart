import 'package:flutter_test/flutter_test.dart';

import 'package:almanac/app/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme.light', () {
    final theme = AppTheme.light;

    test(
      'uses the cream/moss natural palette rather than Material defaults',
      () {
        expect(theme.colorScheme.surface, AppColors.cream);
        expect(theme.colorScheme.primary, AppColors.moss);
        expect(theme.colorScheme.tertiary, AppColors.ocean);
      },
    );

    test(
      'text theme is fully populated so every widget has a defined style',
      () {
        final textTheme = theme.textTheme;
        for (final style in [
          textTheme.displayLarge,
          textTheme.headlineMedium,
          textTheme.titleLarge,
          textTheme.bodyLarge,
          textTheme.bodyMedium,
          textTheme.labelLarge,
        ]) {
          expect(style, isNotNull);
          expect(style!.fontSize, isNotNull);
        }
      },
    );

    test('minimum touch target meets accessibility guidance', () {
      expect(AppDimens.minTouchTarget, greaterThanOrEqualTo(48));
    });
  });
}
