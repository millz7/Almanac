import 'package:flutter/material.dart';

import 'app_spacing.dart';
import 'app_typography.dart';
import 'seasonal_palettes.dart';

export 'app_spacing.dart';
export 'app_typography.dart';
export 'chakra_accents.dart';
export 'seasonal_palettes.dart';

/// Reaches the active seasonal palette from any widget.
///
/// Use this for the tokens Material's [ColorScheme] has no equivalent for
/// (`water`, `earth`, `surfaceElevated`); for everything else,
/// `Theme.of(context).colorScheme` and `textTheme` already carry the
/// season's colours.
extension SeasonalPaletteContext on BuildContext {
  SeasonalPalette get palette {
    final palette = Theme.of(this).extension<SeasonalPalette>();
    assert(
      palette != null,
      'No SeasonalPalette found in the theme. Build ThemeData with '
      'AppTheme.fromPalette() so the whole app inherits the season.',
    );
    return palette ?? SeasonalPalettes.fallback;
  }
}

/// Builds the app's [ThemeData] for a given seasonal palette.
///
/// Everything that varies with the season or the time of day comes from
/// [palette]; everything structural — typography, spacing, shape, motion —
/// is fixed, so the app stays recognisably itself all year round.
abstract final class AppTheme {
  static ThemeData fromPalette(SeasonalPalette palette) {
    final colorScheme = _colorSchemeFrom(palette);
    final textTheme = AppTypography.textTheme(
      palette.textPrimary,
      palette.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      // The palette travels with the theme so widgets can read tokens that
      // ColorScheme cannot express, and so Flutter animates between
      // seasons and day/night for us.
      extensions: [palette],
      iconTheme: IconThemeData(color: palette.icon, size: AppIconSize.md),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.none,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.none,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceElevated,
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        side: BorderSide.none,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          disabledBackgroundColor: palette.disabled,
          disabledForegroundColor: palette.onDisabled,
          minimumSize: const Size.fromHeight(AppDimens.buttonHeight),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          elevation: AppElevation.none,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          disabledForegroundColor: palette.onDisabled,
          minimumSize: const Size.fromHeight(AppDimens.buttonHeight),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          disabledForegroundColor: palette.onDisabled,
          textStyle: textTheme.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: palette.primarySoft,
        height: AppDimens.navBarHeight,
        elevation: AppElevation.none,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? palette.onPrimarySoft : palette.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? palette.onPrimarySoft : palette.textSecondary,
            size: AppIconSize.md,
          );
        }),
      ),
      // Dividers want to be quieter than a functional outline, so the
      // border token is used at reduced strength rather than as-is.
      dividerTheme: DividerThemeData(
        color: palette.border.withValues(alpha: 0.4),
        space: AppSpacing.lg,
      ),
      visualDensity: VisualDensity.standard,
    );
  }

  /// Maps the app's semantic tokens onto Material's colour roles, so every
  /// stock Material widget picks up the season without any extra work.
  static ColorScheme _colorSchemeFrom(SeasonalPalette palette) => ColorScheme(
    brightness: palette.brightness,
    primary: palette.primary,
    onPrimary: palette.onPrimary,
    primaryContainer: palette.primarySoft,
    onPrimaryContainer: palette.onPrimarySoft,
    secondary: palette.secondary,
    onSecondary: palette.onSecondary,
    secondaryContainer: palette.surfaceElevated,
    onSecondaryContainer: palette.textPrimary,
    tertiary: palette.accent,
    onTertiary: palette.onAccent,
    tertiaryContainer: palette.accent,
    onTertiaryContainer: palette.onAccent,
    error: palette.error,
    onError: palette.onError,
    surface: palette.background,
    onSurface: palette.textPrimary,
    surfaceContainerLowest: palette.background,
    surfaceContainerLow: palette.background,
    surfaceContainer: palette.surface,
    surfaceContainerHigh: palette.surfaceElevated,
    surfaceContainerHighest: palette.surfaceElevated,
    onSurfaceVariant: palette.textSecondary,
    outline: palette.border,
    outlineVariant: palette.border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: palette.textPrimary,
    onInverseSurface: palette.background,
    inversePrimary: palette.primarySoft,
  );
}
