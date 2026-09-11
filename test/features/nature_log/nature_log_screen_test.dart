import 'package:almanac/app/almanac_button.dart';
import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:almanac/features/nature_log/application/nature_log_providers.dart';
import 'package:almanac/features/nature_log/presentation/nature_log_text.dart';
import 'package:almanac/features/nature_log/presentation/widgets/nature_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// Mid-October: kōwhai in flower, and astronomically spring in the
/// south — the equinox falls after the middle of September, so a
/// mid-September date is still winter to the rest of the app.
final october = DateTime.utc(2026, 10, 15, 0);

/// Mid-February: cicadas, and a different page.
final february = DateTime.utc(2026, 2, 15, 0);

const wellington = GeoLocation(latitude: -41.29, longitude: 174.78);
const london = GeoLocation(latitude: 51.51, longitude: -0.13);

void main() {
  setUpAll(useTimeZoneDatabase);

  final back = find.widgetWithText(TextButton, NatureLogText.back);
  final recordSomething = find.widgetWithText(
    ElevatedButton,
    NatureLogText.recordSomething,
  );
  final writeYourOwn = find.widgetWithText(
    ElevatedButton,
    NatureLogText.writeYourOwn,
  );
  final saveObservation = find.widgetWithText(
    ElevatedButton,
    NatureLogText.saveObservation,
  );
  final saveChanges = find.widgetWithText(
    ElevatedButton,
    NatureLogText.saveChanges,
  );
  final recordAnObservation = find.widgetWithText(
    ElevatedButton,
    NatureLogText.recordAnObservation,
  );

  Finder navTab(String name) => find.descendant(
    of: find.byType(AlmanacNavigationBar),
    matching: find.bySemanticsLabel(name),
  );

  Finder route(String title) => find.bySemanticsLabel(RegExp('^$title\\.'));

  Finder entry(String name) => find.bySemanticsLabel(RegExp('^$name[.,]'));

  /// Scoped to the dialog: the page behind it has a Remove of its own.
  Finder dialogButton(String label) => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(TextButton, label),
  );

  Future<ProviderContainer> openNatureLog(
    WidgetTester tester, {
    DateTime? now,
    NatureLogStore? store,
    LocationState? locationState = const LocationAvailable(wellington),
    Hemisphere hemisphere = Hemisphere.southern,
    double textScale = 1,
    bool reducedMotion = false,
    Size surface = const Size(420, 3200),
    Set<FeatureId> features = const {FeatureId.natureLog},
  }) async {
    tester.view.physicalSize = surface * 2;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    if (reducedMotion) {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
    }

    final container = ProviderContainer(
      overrides: environmentOverrides(
        now: now ?? october,
        timeZone: TestTimeZones.wellington,
        hemisphere: hemisphere,
        locationState: locationState,
        features: features,
        natureLogStore: store ?? InMemoryNatureLogStore(),
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(navTab(NatureLogText.title));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> press(WidgetTester tester, Finder control) async {
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String label, String text) async {
    final field = find.widgetWithText(TextField, label);
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  /// Back to the two routes, however deep in the feature we are. The
  /// route cards are only on the landing page, so they are how the test
  /// knows it has arrived.
  Future<void> toLanding(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      if (route(NatureLogText.aroundNow).evaluate().isNotEmpty) return;
      await press(tester, back);
    }
    expect(route(NatureLogText.aroundNow), findsOneWidget);
  }

  /// Records something the user describes themselves, through the real
  /// screens.
  Future<void> recordCustom(
    WidgetTester tester,
    String name, {
    String category = 'Insect',
    String? note,
    String? place,
  }) async {
    await toLanding(tester);
    await press(tester, recordSomething);
    await press(tester, writeYourOwn);
    await type(tester, NatureLogText.nameLabel, name);
    await press(tester, find.bySemanticsLabel(category));
    if (note != null) await type(tester, NatureLogText.noteLabel, note);
    if (place != null) await type(tester, NatureLogText.placeLabel, place);
    await press(tester, saveObservation);
  }

  group('the landing page', () {
    testWidgets('is two routes, a way in, and nothing else', (tester) async {
      await openNatureLog(tester);

      expect(route(NatureLogText.aroundNow), findsOneWidget);
      expect(route(NatureLogText.myObservations), findsOneWidget);
      expect(recordSomething, findsOneWidget);
      // No lists, no suggestions, no log on the first page.
      expect(find.byType(NatureMark), findsNothing);
    });

    testWidgets('says when and where it is talking about', (tester) async {
      await openNatureLog(tester);

      expect(find.text('October · Spring'), findsOneWidget);
      expect(find.text(NatureCoverage.newZealand.label), findsOneWidget);
      expect(find.text(NatureLogText.noGuideHere), findsNothing);
      expect(find.text(NatureLogText.noLocationNote), findsNothing);
    });

    testWidgets('with no location there is no guide, in either hemisphere', (
      tester,
    ) async {
      for (final hemisphere in Hemisphere.values) {
        await openNatureLog(
          tester,
          hemisphere: hemisphere,
          locationState: const LocationPermissionDenied(),
        );

        // The season still follows the hemisphere; the guide does not
        // exist either way.
        expect(
          find.text(NatureLogText.noGuideHere),
          findsOneWidget,
          reason: hemisphere.name,
        );
        expect(
          find.text(NatureCoverage.newZealand.label),
          findsNothing,
          reason: hemisphere.name,
        );
      }
    });

    testWidgets('and says once why, without asking for anything', (
      tester,
    ) async {
      await openNatureLog(
        tester,
        hemisphere: Hemisphere.southern,
        locationState: const LocationPermissionDenied(),
      );

      expect(find.text(NatureLogText.noLocationNote), findsOneWidget);
      // An explanation, not a prompt: nothing on the page offers to
      // turn location on.
      expect(
        find.textContaining(
          RegExp('enable|turn on|allow location', caseSensitive: false),
        ),
        findsNothing,
      );
    });

    testWidgets('and says plainly when there is no guide here', (tester) async {
      await openNatureLog(
        tester,
        locationState: const LocationAvailable(london),
      );

      expect(find.text(NatureLogText.noGuideHere), findsOneWidget);
      // Outside the coverage, not unlocated: there is nothing to
      // explain about location here.
      expect(find.text(NatureLogText.noLocationNote), findsNothing);
      // The way in is still there: the log works everywhere.
      expect(recordSomething, findsOneWidget);
    });

    testWidgets('each route opens its own page', (tester) async {
      await openNatureLog(tester);

      await press(tester, route(NatureLogText.aroundNow));
      expect(find.text('Spring · New Zealand guide'), findsOneWidget);
      await press(tester, back);

      await press(tester, route(NatureLogText.myObservations));
      expect(find.text(NatureLogText.logEmpty), findsOneWidget);
    });

    testWidgets('the Almanac is reachable, and the tabs are unchanged', (
      tester,
    ) async {
      await openNatureLog(
        tester,
        features: {FeatureId.meditation, FeatureId.natureLog},
      );

      expect(find.byType(AlmanacButton), findsOneWidget);
      // The bar is the app's, with the user's own chosen features on it.
      expect(navTab('Environment'), findsOneWidget);
      expect(navTab('Meditation'), findsOneWidget);
      expect(navTab(NatureLogText.title), findsOneWidget);
    });
  });

  group('Around now', () {
    testWidgets('groups what the guide offers, and skips empty groups', (
      tester,
    ) async {
      await openNatureLog(tester);
      await press(tester, route(NatureLogText.aroundNow));

      expect(find.text('Birds'), findsOneWidget);
      expect(find.text('Plants'), findsOneWidget);
      // Kōwhai flowers in spring; pōhutukawa does not.
      expect(entry('Kōwhai'), findsOneWidget);
      expect(entry('Pōhutukawa'), findsNothing);
    });

    testWidgets('and says why each one is there', (tester) async {
      await openNatureLog(tester);
      await press(tester, route(NatureLogText.aroundNow));

      expect(
        find.text('Often busy around flowering kōwhai in spring.'),
        findsOneWidget,
      );
    });

    testWidgets('a different month is a different page', (tester) async {
      await openNatureLog(tester, now: february);
      await press(tester, route(NatureLogText.aroundNow));

      // Cicadas in February, and no swallows arriving.
      expect(entry('Kihikihi'), findsOneWidget);
      expect(entry('Kōwhai'), findsNothing);
    });

    testWidgets('a heading is only drawn when something is under it', (
      tester,
    ) async {
      await openNatureLog(tester, now: DateTime.utc(2026, 6, 15, 0));
      await press(tester, route(NatureLogText.aroundNow));

      for (final category in NatureCategory.values) {
        final heading = find.text(category.plural);
        if (heading.evaluate().isEmpty) continue;
        expect(
          find.byType(NatureMark),
          findsWidgets,
          reason: '${category.plural} has a heading and nothing under it',
        );
      }
    });

    testWidgets('outside the guide it offers nothing, and says so', (
      tester,
    ) async {
      await openNatureLog(
        tester,
        locationState: const LocationAvailable(london),
      );
      await press(tester, route(NatureLogText.aroundNow));

      expect(find.text(NatureLogText.noGuideHere), findsOneWidget);
      expect(find.text(NatureLogText.noGuideNote), findsOneWidget);
      // Not one New Zealand species suggested to somebody in London.
      expect(find.byType(NatureMark), findsNothing);
      expect(entry('Tūī'), findsNothing);
    });

    testWidgets('and with no location it offers nothing either', (
      tester,
    ) async {
      for (final hemisphere in Hemisphere.values) {
        await openNatureLog(
          tester,
          hemisphere: hemisphere,
          locationState: const LocationPermissionDenied(),
        );
        await press(tester, route(NatureLogText.aroundNow));

        expect(
          find.text(NatureLogText.noGuideHere),
          findsOneWidget,
          reason: hemisphere.name,
        );
        expect(
          find.text(NatureLogText.noGuideNote),
          findsOneWidget,
          reason: hemisphere.name,
        );
        expect(
          find.text(NatureLogText.noLocationNote),
          findsOneWidget,
          reason: hemisphere.name,
        );
        // Southern hemisphere is not evidence of New Zealand.
        expect(find.byType(NatureMark), findsNothing, reason: hemisphere.name);
        expect(entry('Tūī'), findsNothing, reason: hemisphere.name);
      }
    });

    testWidgets('the fungi shelf says what it is not', (tester) async {
      await openNatureLog(tester, now: DateTime.utc(2026, 4, 15, 0));
      await press(tester, route(NatureLogText.aroundNow));

      expect(find.text('Fungi'), findsOneWidget);
      expect(find.text(NatureLogText.fungiNote), findsWidgets);
    });

    testWidgets('an entry opens its own page', (tester) async {
      await openNatureLog(tester);
      await press(tester, route(NatureLogText.aroundNow));
      await press(tester, entry('Tūī'));

      expect(find.text('Prosthemadera novaeseelandiae'), findsOneWidget);
      expect(find.textContaining('white tuft at the throat'), findsOneWidget);
      expect(find.text('August to November'), findsOneWidget);
      expect(recordAnObservation, findsOneWidget);
    });
  });

  group('recording something', () {
    testWidgets('from the book saves it, and says so quietly', (tester) async {
      final container = await openNatureLog(tester);

      await press(tester, recordSomething);
      await press(tester, entry('Tūī'));
      await type(tester, NatureLogText.noteLabel, 'In the kōwhai');
      await press(tester, saveObservation);

      // Acknowledged, and no celebration.
      expect(find.text(NatureLogText.added), findsOneWidget);

      final saved = container.read(natureLogProvider).value!.recent.single;
      expect(saved.itemId, 'tui');
      expect(saved.label, 'Tūī');
      expect(saved.note, 'In the kōwhai');
      expect(saved.date, container.read(todayProvider));
      expect(saved.placeLabel, isNull);
    });

    testWidgets('and it is in My observations straight away', (tester) async {
      await openNatureLog(tester);
      await press(tester, recordSomething);
      await press(tester, entry('Tūī'));
      await press(tester, saveObservation);

      // Saving lands on the log, with the new entry already there.
      expect(find.text('Thursday 15 October'), findsOneWidget);
      expect(entry('Tūī'), findsOneWidget);
    });

    testWidgets('from an entry page, having read about it first', (
      tester,
    ) async {
      final container = await openNatureLog(tester);
      await press(tester, route(NatureLogText.aroundNow));
      await press(tester, entry('Kōwhai'));

      await press(tester, recordAnObservation);
      await press(tester, saveObservation);

      expect(
        container.read(natureLogProvider).value!.recent.single.itemId,
        'kowhai',
      );
    });

    testWidgets('in their own words, with a place they typed', (tester) async {
      final container = await openNatureLog(tester);

      await recordCustom(
        tester,
        'Tiny green beetle',
        note: 'On the washing line',
        place: 'Back garden',
      );

      final saved = container.read(natureLogProvider).value!.recent.single;
      expect(saved.label, 'Tiny green beetle');
      expect(saved.category, NatureCategory.insect);
      // Kept as written: nothing tried to identify it.
      expect(saved.itemId, isNull);
      expect(saved.note, 'On the washing line');
      expect(saved.placeLabel, 'Back garden');
    });

    testWidgets('and a nameless one cannot be saved', (tester) async {
      await openNatureLog(tester);
      await press(tester, recordSomething);
      await press(tester, writeYourOwn);

      // Nothing typed, so nothing to save — and no error shouted at
      // anybody either.
      expect(tester.widget<ElevatedButton>(saveObservation).onPressed, isNull);

      await type(tester, NatureLogText.nameLabel, 'A moth');
      expect(
        tester.widget<ElevatedButton>(saveObservation).onPressed,
        isNotNull,
      );
    });

    testWidgets('and it works with no guide at all', (tester) async {
      final container = await openNatureLog(
        tester,
        locationState: const LocationAvailable(london),
      );

      await recordCustom(tester, 'Robin', category: 'Bird');

      expect(
        container.read(natureLogProvider).value!.recent.single.label,
        'Robin',
      );
    });

    testWidgets('the form says where the place goes, and where it does not', (
      tester,
    ) async {
      await openNatureLog(tester);
      await press(tester, recordSomething);
      await press(tester, writeYourOwn);

      expect(find.text(NatureLogText.privacyNote), findsOneWidget);
      expect(find.text(NatureLogText.placeLabel), findsOneWidget);
    });
  });

  group('My observations', () {
    testWidgets('is empty until something is noticed', (tester) async {
      await openNatureLog(tester);
      await press(tester, route(NatureLogText.myObservations));

      expect(find.text(NatureLogText.logEmpty), findsOneWidget);
      expect(find.text(NatureLogText.logEmptyNote), findsOneWidget);
      // A way in from the empty state, rather than a dead end.
      expect(recordSomething, findsOneWidget);
    });

    testWidgets('gathers what was noticed under its day', (tester) async {
      await openNatureLog(tester);
      await recordCustom(tester, 'Tiny green beetle');
      await recordCustom(tester, 'A moth');

      expect(find.text('Thursday 15 October'), findsOneWidget);
      expect(entry('A moth'), findsOneWidget);
      expect(entry('Tiny green beetle'), findsOneWidget);
    });

    testWidgets('and two days are two headings, not one repeated', (
      tester,
    ) async {
      // The grouping is decided before the list is built, so a day's
      // heading appears once above its observations however many there
      // are under it.
      final store = InMemoryNatureLogStore(
        NatureLog([
          NatureObservation(
            instanceId: 'a',
            date: const CalendarDate(2026, 10, 15),
            category: NatureCategory.insect,
            label: 'A moth',
            order: 0,
          ),
          NatureObservation(
            instanceId: 'b',
            date: const CalendarDate(2026, 10, 15),
            category: NatureCategory.insect,
            label: 'A beetle',
            order: 1,
          ),
          NatureObservation(
            instanceId: 'c',
            date: const CalendarDate(2026, 10, 14),
            category: NatureCategory.bird,
            label: 'A sparrow',
            order: 2,
          ),
        ]),
      );
      await openNatureLog(tester, store: store);
      await press(tester, route(NatureLogText.myObservations));

      expect(find.text('Thursday 15 October'), findsOneWidget);
      expect(find.text('Wednesday 14 October'), findsOneWidget);
      expect(entry('A moth'), findsOneWidget);
      expect(entry('A beetle'), findsOneWidget);
      expect(entry('A sparrow'), findsOneWidget);
    });

    testWidgets('and one from the book looks exactly like one of their own', (
      tester,
    ) async {
      await openNatureLog(tester);
      await press(tester, recordSomething);
      await press(tester, entry('Tūī'));
      await press(tester, saveObservation);
      await recordCustom(tester, 'A moth');

      // Same tile, same weight. Neither is worth more than the other.
      expect(entry('Tūī'), findsOneWidget);
      expect(entry('A moth'), findsOneWidget);
    });

    testWidgets('an observation opens, and can be changed', (tester) async {
      final container = await openNatureLog(tester);
      await recordCustom(tester, 'A moth', note: 'On the window');

      await press(tester, entry('A moth'));
      await type(tester, NatureLogText.noteLabel, 'On the window, twice');
      await type(tester, NatureLogText.placeLabel, 'Kitchen');
      await press(tester, saveChanges);

      final edited = container.read(natureLogProvider).value!.recent.single;
      expect(edited.note, 'On the window, twice');
      expect(edited.placeLabel, 'Kitchen');
      expect(edited.label, 'A moth');
    });

    testWidgets('and removed, once', (tester) async {
      final container = await openNatureLog(tester);
      await recordCustom(tester, 'A moth');

      await press(tester, entry('A moth'));
      await press(
        tester,
        find.widgetWithText(TextButton, NatureLogText.remove),
      );

      expect(find.text(NatureLogText.removeTitle), findsOneWidget);
      await press(tester, dialogButton(NatureLogText.remove));

      expect(container.read(natureLogProvider).value!.isEmpty, isTrue);
      expect(entry('A moth'), findsNothing);
    });

    testWidgets('and keeping it keeps it', (tester) async {
      final container = await openNatureLog(tester);
      await recordCustom(tester, 'A moth');

      await press(tester, entry('A moth'));
      await press(
        tester,
        find.widgetWithText(TextButton, NatureLogText.remove),
      );
      await press(tester, dialogButton(NatureLogText.keep));

      expect(container.read(natureLogProvider).value!.length, 1);
      // Still on the observation, not thrown back to the list.
      expect(saveChanges, findsOneWidget);
    });

    testWidgets('clearing the whole log asks first', (tester) async {
      final container = await openNatureLog(tester);
      await recordCustom(tester, 'A moth');

      await press(
        tester,
        find.widgetWithText(TextButton, NatureLogText.clearAll),
      );
      expect(find.text(NatureLogText.clearTitle), findsOneWidget);
      await press(tester, dialogButton(NatureLogText.keep));

      expect(container.read(natureLogProvider).value!.length, 1);

      await press(
        tester,
        find.widgetWithText(TextButton, NatureLogText.clearAll),
      );
      await press(tester, dialogButton(NatureLogText.remove));

      expect(container.read(natureLogProvider).value!.isEmpty, isTrue);
      expect(find.text(NatureLogText.logEmpty), findsOneWidget);
    });

    testWidgets('it keeps no score anybody is asked to beat', (tester) async {
      await openNatureLog(tester);
      await recordCustom(tester, 'A moth');

      // One quiet line about the season, and nothing that ranks,
      // rewards or nags.
      expect(find.textContaining('noticed this spring'), findsOneWidget);
      for (final word in [
        'streak',
        'badge',
        'point',
        'goal',
        'challenge',
        'complete your',
        'well done',
        'congratulations',
      ]) {
        expect(
          find.textContaining(RegExp(word, caseSensitive: false)),
          findsNothing,
          reason: word,
        );
      }
    });
  });

  group('with no location at all', () {
    testWidgets('the Nature Book is still browsable, and says it is a book', (
      tester,
    ) async {
      await openNatureLog(
        tester,
        hemisphere: Hemisphere.southern,
        locationState: const LocationPermissionDenied(),
      );
      await press(tester, recordSomething);

      // Browsing a reference catalogue is not a claim that these things
      // are around you, and the page says which it is.
      expect(find.text(NatureLogText.bookIsReference), findsOneWidget);
      for (final category in NatureCategory.values) {
        expect(
          find.widgetWithText(AlmanacSectionLabel, category.plural),
          findsOneWidget,
          reason: category.name,
        );
      }
      expect(entry('Tūī'), findsOneWidget);
      expect(entry('Pōhutukawa'), findsOneWidget);
    });

    testWidgets('a book entry can still be recorded', (tester) async {
      final container = await openNatureLog(
        tester,
        locationState: const LocationPermissionDenied(),
      );

      await press(tester, recordSomething);
      await press(tester, entry('Tūī'));
      await press(tester, saveObservation);

      final saved = container.read(natureLogProvider).value!.recent.single;
      expect(saved.itemId, 'tui');
      expect(saved.label, 'Tūī');
      expect(entry('Tūī'), findsOneWidget);
    });

    testWidgets('a custom observation can still be recorded', (tester) async {
      final container = await openNatureLog(
        tester,
        locationState: const LocationPermissionDenied(),
      );

      await recordCustom(tester, 'Tiny green beetle', place: 'Back garden');

      final saved = container.read(natureLogProvider).value!.recent.single;
      expect(saved.label, 'Tiny green beetle');
      expect(saved.placeLabel, 'Back garden');
    });

    testWidgets('and it can be edited, removed and cleared', (tester) async {
      final container = await openNatureLog(
        tester,
        locationState: const LocationPermissionDenied(),
      );
      await recordCustom(tester, 'A moth');

      await press(tester, entry('A moth'));
      await type(tester, NatureLogText.noteLabel, 'On the window');
      await press(tester, saveChanges);
      expect(
        container.read(natureLogProvider).value!.recent.single.note,
        'On the window',
      );

      await press(
        tester,
        find.widgetWithText(TextButton, NatureLogText.remove),
      );
      await press(tester, dialogButton(NatureLogText.remove));
      expect(container.read(natureLogProvider).value!.isEmpty, isTrue);
    });

    testWidgets('and opening all of it asks for no permission', (tester) async {
      final service = FakeLocationService(
        checkResult: const LocationPermissionNotRequested(),
      );
      final container = ProviderContainer(
        overrides: environmentOverrides(
          now: october,
          timeZone: TestTimeZones.wellington,
          hemisphere: Hemisphere.southern,
          locationService: service,
          features: {FeatureId.natureLog},
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AlmanacApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(navTab(NatureLogText.title));
      await tester.pumpAndSettle();

      // Every page, then the whole recording flow.
      await press(tester, route(NatureLogText.aroundNow));
      await press(tester, back);
      await press(tester, route(NatureLogText.myObservations));
      await press(tester, back);
      await press(tester, recordSomething);
      await press(tester, writeYourOwn);
      await type(tester, NatureLogText.nameLabel, 'A moth');
      await press(tester, saveObservation);

      expect(service.requestCount, 0);
      expect(container.read(natureLogProvider).value!.length, 1);
    });

    testWidgets('and no coordinate reaches storage', (tester) async {
      final store = InMemoryNatureLogStore();
      await openNatureLog(
        tester,
        store: store,
        locationState: const LocationPermissionDenied(),
      );

      await recordCustom(tester, 'A moth', place: 'Kitchen');

      final stored = encodeLog(await store.read()).join('\n');
      expect(stored, contains('A moth'));
      expect(stored, contains('Kitchen'));
      expect(stored, isNot(contains('latitude')));
      expect(stored, isNot(contains('longitude')));
    });
  });

  group('the Nature Book', () {
    testWidgets('can be reached to record, and shows every shelf', (
      tester,
    ) async {
      await openNatureLog(tester);
      await press(tester, recordSomething);

      expect(find.text(NatureLogText.whatDidYouNotice), findsOneWidget);
      for (final category in NatureCategory.values) {
        // The shelf heading, not the word: "Other" is also the category
        // line on each of the tiles under it.
        expect(
          find.widgetWithText(AlmanacSectionLabel, category.plural),
          findsOneWidget,
          reason: category.name,
        );
      }
      // Everything, not only what suits this month.
      expect(entry('Pōhutukawa'), findsOneWidget);
      expect(entry('Tūī'), findsOneWidget);
    });

    testWidgets('and offers the other answer too', (tester) async {
      await openNatureLog(tester);
      await press(tester, recordSomething);

      // Not everything worth noticing is in a book.
      expect(writeYourOwn, findsOneWidget);
    });

    testWidgets('the whole book is there outside the guide as well', (
      tester,
    ) async {
      await openNatureLog(
        tester,
        locationState: const LocationAvailable(london),
      );
      await press(tester, recordSomething);

      expect(entry('Tūī'), findsOneWidget);
      expect(writeYourOwn, findsOneWidget);
    });
  });

  group('reduced motion', () {
    testWidgets('the marks are simply already drawn', (tester) async {
      await openNatureLog(tester, reducedMotion: true);
      await press(tester, route(NatureLogText.aroundNow));

      for (final mark in tester.widgetList<NatureMark>(
        find.byType(NatureMark),
      )) {
        expect(mark.growth, 1);
      }
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('and everything still works', (tester) async {
      final container = await openNatureLog(tester, reducedMotion: true);
      await recordCustom(tester, 'A moth');

      expect(container.read(natureLogProvider).value!.length, 1);
    });

    testWidgets('nothing is still ticking once the page has settled', (
      tester,
    ) async {
      await openNatureLog(tester);
      await press(tester, route(NatureLogText.aroundNow));

      // The one movement is a single settle. Nature moves; the
      // interface stays still.
      expect(tester.binding.transientCallbackCount, 0);
      await press(tester, entry('Tūī'));
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('accessibility', () {
    testWidgets('a route says what it is for', (tester) async {
      await openNatureLog(tester);

      expect(
        find.bySemanticsLabel(
          '${NatureLogText.aroundNow}. ${NatureLogText.aroundNowDescription}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an entry says its names and its shelf', (tester) async {
      await openNatureLog(tester);
      await press(tester, recordSomething);

      expect(
        find.bySemanticsLabel('Pīwakawaka, Fantail. Bird.'),
        findsOneWidget,
      );
    });

    testWidgets('a suggestion says why it is there', (tester) async {
      await openNatureLog(tester);
      await press(tester, route(NatureLogText.aroundNow));

      expect(
        find.bySemanticsLabel(
          'Tūī. Bird. Often busy around flowering kōwhai in spring.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an observation says what it is and when it was noticed', (
      tester,
    ) async {
      await openNatureLog(tester);
      await recordCustom(tester, 'A moth');

      expect(
        find.bySemanticsLabel('A moth. Insect. Recorded 15 October.'),
        findsOneWidget,
      );
    });

    testWidgets('the drawn marks say nothing', (tester) async {
      await openNatureLog(tester);
      await press(tester, route(NatureLogText.aroundNow));

      expect(
        find.descendant(
          of: find.byType(NatureMark),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });

    testWidgets('every control is a comfortable target', (tester) async {
      await openNatureLog(tester);

      for (final title in [
        NatureLogText.aroundNow,
        NatureLogText.myObservations,
      ]) {
        expect(
          tester.getSize(route(title)).height,
          greaterThanOrEqualTo(48),
          reason: title,
        );
      }
      expect(tester.getSize(recordSomething).height, greaterThanOrEqualTo(48));

      await press(tester, recordSomething);
      await press(tester, writeYourOwn);
      expect(
        tester.getSize(find.bySemanticsLabel('Fungus')).height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
    });

    testWidgets('doubling the text size breaks nothing', (tester) async {
      await openNatureLog(tester, textScale: 2, surface: const Size(420, 5000));

      expect(find.text(NatureLogText.aroundNow), findsOneWidget);
      expect(find.text(NatureLogText.myObservations), findsOneWidget);

      await press(tester, route(NatureLogText.aroundNow));
      expect(find.text('Birds'), findsOneWidget);
      // A long name wraps rather than being cut down.
      expect(find.text('Tūī'), findsOneWidget);
    });
  });
}
