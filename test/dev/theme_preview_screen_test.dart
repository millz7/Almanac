import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/app/theme/theme_providers.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:almanac/dev/theme_preview.dart';
import 'package:almanac/dev/theme_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_overrides.dart';

void main() {
  ProviderContainer buildContainer() {
    final container = ProviderContainer(overrides: environmentOverrides());
    addTearDown(container.dispose);
    return container;
  }

  /// Mirrors how the real app builds its theme, so the preview screen is
  /// exercised through the same path.
  Widget wrap(ProviderContainer container) => UncontrolledProviderScope(
    container: container,
    child: Consumer(
      builder: (context, ref, _) => MaterialApp(
        theme: AppTheme.fromPalette(ref.watch(activePaletteProvider)),
        home: const ThemePreviewScreen(),
      ),
    ),
  );

  testWidgets('shows the season and time-of-day controls', (tester) async {
    await tester.pumpWidget(wrap(buildContainer()));
    await tester.pumpAndSettle();

    expect(find.text('Theme preview'), findsOneWidget);
    for (final label in ['Spring', 'Summer', 'Autumn', 'Winter']) {
      expect(find.widgetWithText(ChoiceChip, label), findsOneWidget);
    }
    expect(find.widgetWithText(ChoiceChip, 'Day'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Night'), findsOneWidget);
  });

  testWidgets('tapping a season repaints the screen in that palette', (
    tester,
  ) async {
    final container = buildContainer();
    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Summer Day'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Winter'));
    await tester.pumpAndSettle();

    expect(container.read(activePaletteProvider), same(WinterPalettes.day));
    expect(find.text('Winter Day'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Night'));
    await tester.pumpAndSettle();

    expect(container.read(activePaletteProvider), same(WinterPalettes.night));
    expect(find.text('Winter Night'), findsOneWidget);
  });

  testWidgets('reports the environment detected from the real world', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(buildContainer()));
    await tester.pumpAndSettle();

    expect(find.text('Detected environment'), findsOneWidget);
    // Mid-July, London, midday: the engine should have worked out summer,
    // daylight, northern hemisphere without any override.
    expect(find.text('northern'), findsOneWidget);
    expect(find.text('1.00'), findsOneWidget);
    expect(find.widgetWithText(AppCard, 'Summer'), findsOneWidget);
  });

  testWidgets('shows every semantic token as an inspectable swatch', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(buildContainer()));
    await tester.pumpAndSettle();

    // The swatches sit below the fold in a lazy list, so scroll each one
    // into view the way a developer would.
    for (final token in [
      'background',
      'surface',
      'primary',
      'accent',
      'water',
      'earth',
      'border',
      'error',
    ]) {
      await tester.scrollUntilVisible(
        find.text(token),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(
        find.text(token),
        findsWidgets,
        reason: '$token swatch should be visible for inspection',
      );
    }
  });

  testWidgets('handing control back clears the override', (tester) async {
    final container = buildContainer();
    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Autumn'));
    await tester.pumpAndSettle();
    expect(container.read(themePreviewProvider), isNotNull);

    await tester.tap(find.text('Use the real environment'));
    await tester.pumpAndSettle();

    expect(container.read(themePreviewProvider), isNull);
    expect(container.read(activePaletteProvider), same(SummerPalettes.day));
  });
}
