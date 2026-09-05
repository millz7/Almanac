import 'package:almanac/app/app.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/settings/settings_store.dart';
import 'package:almanac/core/settings/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// Onboarding has to survive a large text setting, because someone who
/// needs one has to get through it before they can use anything.
void main() {
  setUpAll(useTimeZoneDatabase);

  /// The four questions, each identified by the settings that stop
  /// setup at it.
  final stages = <String, UserSettings>{
    'the name question': const UserSettings(),
    'the hemisphere question': const UserSettings(nameAsked: true),
    'the location explanation': const UserSettings(
      nameAsked: true,
      hemisphere: Hemisphere.northern,
    ),
    'the Almanac question': const UserSettings(
      nameAsked: true,
      hemisphere: Hemisphere.northern,
      locationIntroSeen: true,
    ),
  };

  /// A phone-sized viewport, deliberately not a tall test surface: the
  /// point is that the screens scroll rather than overflow.
  Future<void> pumpStage(
    WidgetTester tester,
    UserSettings settings, {
    required double textScale,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: environmentOverrides(
          settingsStore: InMemorySettingsStore(settings),
        ),
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  stages.forEach((label, settings) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('$label survives ${scale}x text', (tester) async {
        await pumpStage(tester, settings, textScale: scale);

        // An overflow is reported as an exception during layout, so this
        // is the assertion: nothing is cut off and nothing has run out of
        // its box.
        expect(tester.takeException(), isNull);
        // And it is scrollable, so anything past the fold is reachable.
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    }

    testWidgets('$label has a heading a screen reader can find', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpStage(tester, settings, textScale: 1);

      final headings = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((semantics) => semantics.properties.header ?? false);
      expect(headings, isNotEmpty, reason: '$label needs a marked heading');

      handle.dispose();
    });
  });
}
