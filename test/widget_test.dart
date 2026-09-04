import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:almanac/app/app.dart';

void main() {
  testWidgets('app launches on Today and can navigate to other tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: AlmanacApp()));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Wellbeing'), findsOneWidget);
    expect(find.text('Rhythms'), findsOneWidget);
    expect(find.text('Nature'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);

    await tester.tap(find.text('Nature'));
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets(
    'bottom navigation exposes all five destinations to screen readers',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: AlmanacApp()));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, 5);
    },
  );
}
