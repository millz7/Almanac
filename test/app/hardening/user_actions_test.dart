import 'package:almanac/app/app.dart';
import 'package:almanac/app/router.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:almanac/features/cookbook/application/own_recipes_providers.dart';
import 'package:almanac/features/cookbook/presentation/cookbook_text.dart';
import 'package:almanac/features/cycle/application/cycle_providers.dart';
import 'package:almanac/features/cycle/presentation/cycle_text.dart';
import 'package:almanac/features/garden/application/garden_providers.dart';
import 'package:almanac/features/garden/presentation/garden_text.dart';
import 'package:almanac/features/nature_log/application/nature_log_providers.dart';
import 'package:almanac/features/nature_log/presentation/nature_log_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// A store that can be made to refuse writes, the way a full or broken
/// device would — for proving a failed save is never reported as a
/// success, never loses what was there, and can simply be tried again.
mixin _Failing {
  bool failing = false;
  int writes = 0;

  void _maybeFail() {
    writes++;
    if (failing) throw StateError('disk full');
  }
}

class _FailingRecipes extends InMemoryOwnRecipeStore with _Failing {
  _FailingRecipes([super.recipes]);
  @override
  Future<void> write(OwnRecipes recipes) async {
    _maybeFail();
    await super.write(recipes);
  }
}

class _FailingNature extends InMemoryNatureLogStore with _Failing {
  @override
  Future<void> write(NatureLog log) async {
    _maybeFail();
    await super.write(log);
  }
}

class _FailingGarden extends InMemoryGardenStore with _Failing {
  @override
  Future<void> write(MyGarden garden) async {
    _maybeFail();
    await super.write(garden);
  }
}

class _FailingCycle extends InMemoryCycleStore with _Failing {
  _FailingCycle([super.data]);
  @override
  Future<void> write(CycleData data) async {
    _maybeFail();
    await super.write(data);
  }
}

void main() {
  setUpAll(useTimeZoneDatabase);

  final now = DateTime.utc(2026, 9, 10, 12);
  const sep8 = CalendarDate(2026, 9, 8);
  late ProviderContainer container;

  Future<void> open(
    WidgetTester tester, {
    required FeatureId feature,
    OwnRecipeStore? recipes,
    NatureLogStore? nature,
    GardenStore? garden,
    CycleStore? cycle,
  }) async {
    tester.view.physicalSize = const Size(430, 2600) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    container = ProviderContainer(
      overrides: environmentOverrides(
        now: now,
        features: {feature},
        ownRecipeStore: recipes,
        natureLogStore: nature,
        gardenStore: garden,
        cycleStore: cycle,
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
    container.read(routerProvider).go(FeatureRegistry.byId(feature).route);
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target.first);
    await tester.pumpAndSettle();
    await tester.tap(target.first);
    await tester.pumpAndSettle();
  }

  /// Two taps with no frame in between — as fast as a finger bounces.
  Future<void> doubleTap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target.first);
    await tester.pumpAndSettle();
    await tester.tap(target.first);
    await tester.tap(target.first, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);
  Finder dialogButton(String label) => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(TextButton, label),
  );

  String location() => container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .toString();

  group('a failed save is never reported as a success', () {
    testWidgets('Cookbook: the words stay, nothing is shown as saved, and '
        'Save works once the device does', (tester) async {
      final store = _FailingRecipes()..failing = true;
      await open(tester, feature: FeatureId.cookbook, recipes: store);
      await press(tester, find.text(CookbookText.addRecipe));
      await tester.enterText(field(CookbookText.titleLabel), 'Flapjack');
      await press(tester, find.text(CookbookText.saveRecipe));

      expect(find.text(CookbookText.saveFailed), findsOneWidget);
      expect(find.text(CookbookText.saved), findsNothing);
      expect(find.text('Flapjack'), findsOneWidget);
      expect((await store.read()).isEmpty, isTrue);

      store.failing = false;
      await press(tester, find.text(CookbookText.saveRecipe));
      expect(find.text(CookbookText.saved), findsOneWidget);
      expect((await store.read()).length, 1);
    });

    testWidgets('Nature Log: the form stays filled in, and Save can be '
        'tried again', (tester) async {
      final store = _FailingNature()..failing = true;
      await open(tester, feature: FeatureId.natureLog, nature: store);
      await press(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.recordSomething),
      );
      await press(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.writeYourOwn),
      );
      await tester.enterText(field(NatureLogText.nameLabel), 'A heron');
      await press(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.saveObservation),
      );

      expect(find.text(NatureLogText.saveFailed), findsOneWidget);
      expect(find.text(NatureLogText.added), findsNothing);
      expect(find.text('A heron'), findsOneWidget);
      expect((await store.read()).isEmpty, isTrue);

      store.failing = false;
      await press(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.saveObservation),
      );
      expect(find.text(NatureLogText.added), findsOneWidget);
      expect((await store.read()).length, 1);
    });

    testWidgets('Garden: no "Added", and what was there before stays', (
      tester,
    ) async {
      final store = _FailingGarden();
      await store.write(
        MyGarden([
          GardenPlant(
            instanceId: 'apple',
            plantId: 'apple',
            addedOn: const CalendarDate(2026, 1, 1),
            state: EstablishmentState.established,
          ),
        ]),
      );
      store.failing = true;
      await open(tester, feature: FeatureId.garden, garden: store);
      await press(tester, find.bySemanticsLabel(RegExp('^My Garden\\.')));
      await press(
        tester,
        find.widgetWithText(ElevatedButton, GardenText.addExisting),
      );
      await press(tester, find.bySemanticsLabel(RegExp('^Mint\\.')));
      await press(
        tester,
        find.widgetWithText(ElevatedButton, GardenText.addToMyGarden),
      );
      await press(tester, find.text(EstablishmentState.established.question));

      expect(find.text(GardenText.saveFailed), findsOneWidget);
      expect(find.text(GardenText.added), findsNothing);
      final kept = await store.read();
      expect(kept.contains('apple'), isTrue);
      expect(kept.contains('mint'), isFalse);
    });

    testWidgets('Cycle: a day that could not be saved is not shown as '
        'recorded, and earlier days stay', (tester) async {
      final store = _FailingCycle(
        CycleData(
          records: [
            CycleDayRecord(
              date: sep8,
              level: BleedingLevel.bleeding,
              isPeriodStart: true,
            ),
          ],
        ),
      )..failing = true;
      await open(tester, feature: FeatureId.cycle, cycle: store);
      await press(tester, find.text(CycleText.calendar));
      await press(tester, find.bySemanticsLabel(RegExp('^9 September')));
      await press(tester, find.byKey(const ValueKey('level-heavy')));
      await press(tester, find.widgetWithText(ElevatedButton, CycleText.save));

      expect(find.text(CycleText.saveFailed), findsOneWidget);
      final data = container.read(cycleDataProvider).value!;
      expect(data.recordOn(const CalendarDate(2026, 9, 9)), isNull);
      expect(data.isPeriodStart(sep8), isTrue);
    });
  });

  group('a quick double tap does one thing, once', () {
    testWidgets('Save recipe: one recipe', (tester) async {
      final store = _FailingRecipes();
      await open(tester, feature: FeatureId.cookbook, recipes: store);
      await press(tester, find.text(CookbookText.addRecipe));
      await tester.enterText(field(CookbookText.titleLabel), 'Flapjack');
      await tester.pumpAndSettle();
      await doubleTap(tester, find.text(CookbookText.saveRecipe));

      expect((await store.read()).length, 1);
      expect(store.writes, 1);
    });

    testWidgets('Save observation: one observation', (tester) async {
      final store = _FailingNature();
      await open(tester, feature: FeatureId.natureLog, nature: store);
      await press(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.recordSomething),
      );
      await press(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.writeYourOwn),
      );
      await tester.enterText(field(NatureLogText.nameLabel), 'A heron');
      await tester.pumpAndSettle();
      await doubleTap(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.saveObservation),
      );

      expect((await store.read()).length, 1);
    });

    testWidgets('Add to My Garden: one question, one plant', (tester) async {
      final store = _FailingGarden();
      await open(tester, feature: FeatureId.garden, garden: store);
      await press(tester, find.bySemanticsLabel(RegExp('^My Garden\\.')));
      await press(
        tester,
        find.widgetWithText(ElevatedButton, GardenText.addExisting),
      );
      await press(tester, find.bySemanticsLabel(RegExp('^Mint\\.')));
      await doubleTap(
        tester,
        find.widgetWithText(ElevatedButton, GardenText.addToMyGarden),
      );
      expect(find.byType(SimpleDialog), findsOneWidget);
      await doubleTap(
        tester,
        find.text(EstablishmentState.established.question),
      );

      expect(find.byType(SimpleDialog), findsNothing);
      expect((await store.read()).plants, hasLength(1));
      expect(location(), FeatureRegistry.byId(FeatureId.garden).route);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a Cycle day: one sheet, one record', (tester) async {
      final store = _FailingCycle();
      await open(tester, feature: FeatureId.cycle, cycle: store);
      await press(tester, find.text(CycleText.calendar));
      await doubleTap(tester, find.bySemanticsLabel(RegExp('^9 September')));
      expect(find.byKey(const ValueKey('level-heavy')), findsOneWidget);
      await press(tester, find.byKey(const ValueKey('level-heavy')));
      await doubleTap(
        tester,
        find.widgetWithText(ElevatedButton, CycleText.save),
      );

      expect(tester.takeException(), isNull);
      // Still on the Calendar: the second tap did not pop the page.
      expect(find.text(CycleText.back), findsOneWidget);
      expect((await store.read()).records, hasLength(1));
    });
  });

  group('delete confirmations', () {
    const flapjack = OwnRecipe(id: 'own-0', order: 0, title: 'Flapjack');

    Future<_FailingRecipes> onRecipe(WidgetTester tester) async {
      final store = _FailingRecipes(const OwnRecipes([flapjack]));
      await open(tester, feature: FeatureId.cookbook, recipes: store);
      await press(tester, find.text('Flapjack'));
      await press(tester, find.text(CookbookText.deleteRecipe));
      expect(find.text(CookbookText.deleteTitle), findsOneWidget);
      return store;
    }

    testWidgets('Keep keeps it', (tester) async {
      final store = await onRecipe(tester);
      await press(tester, dialogButton(CookbookText.keep));
      expect((await store.read()).recipes, [flapjack]);
    });

    testWidgets('tapping outside keeps it', (tester) async {
      final store = await onRecipe(tester);
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect((await store.read()).recipes, [flapjack]);
    });

    testWidgets('system Back keeps it, and leaves the recipe open', (
      tester,
    ) async {
      final store = await onRecipe(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text(CookbookText.editRecipe), findsOneWidget);
      expect((await store.read()).recipes, [flapjack]);
    });

    testWidgets('Delete, tapped twice: deleted once, and the page is still '
        'there', (tester) async {
      final store = await onRecipe(tester);
      await doubleTap(tester, dialogButton(CookbookText.delete));
      expect(tester.takeException(), isNull);
      expect((await store.read()).isEmpty, isTrue);
      expect(store.writes, 1);
      expect(location(), FeatureRegistry.byId(FeatureId.cookbook).route);
      expect(find.text(CookbookText.yourRecipes), findsOneWidget);
    });

    testWidgets('Garden: clearing, then Keep, keeps everything', (
      tester,
    ) async {
      final store = _FailingGarden();
      await store.write(
        MyGarden([
          GardenPlant(
            instanceId: 'apple',
            plantId: 'apple',
            addedOn: const CalendarDate(2026, 1, 1),
            state: EstablishmentState.established,
          ),
        ]),
      );
      await open(tester, feature: FeatureId.garden, garden: store);
      await press(tester, find.bySemanticsLabel(RegExp('^My Garden\\.')));
      await press(tester, find.widgetWithText(TextButton, GardenText.clearAll));
      await press(tester, dialogButton(GardenText.keep));
      expect((await store.read()).contains('apple'), isTrue);
    });

    testWidgets('Nature Log: clearing, then Back, keeps everything', (
      tester,
    ) async {
      final store = _FailingNature();
      await open(tester, feature: FeatureId.natureLog, nature: store);
      await container
          .read(natureLogProvider.notifier)
          .recordCustom(name: 'A heron', category: NatureCategory.bird);
      await press(
        tester,
        find.bySemanticsLabel(RegExp('^${NatureLogText.myObservations}\\.')),
      );
      await press(
        tester,
        find.widgetWithText(TextButton, NatureLogText.clearAll),
      );
      expect(find.text(NatureLogText.clearTitle), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect((await store.read()).length, 1);
    });

    testWidgets('Cycle: delete-all asks; Keep keeps, Delete deletes', (
      tester,
    ) async {
      final store = _FailingCycle(
        CycleData(
          records: [
            CycleDayRecord(
              date: sep8,
              level: BleedingLevel.bleeding,
              isPeriodStart: true,
            ),
          ],
        ),
      );
      await open(tester, feature: FeatureId.cycle, cycle: store);
      await press(
        tester,
        find.bySemanticsLabel(RegExp('^${CycleText.adjust}')),
      );
      await press(tester, find.text(CycleText.deleteAll));
      await press(tester, dialogButton(CycleText.keep));
      expect((await store.read()).records, hasLength(1));

      await press(tester, find.text(CycleText.deleteAll));
      await doubleTap(tester, dialogButton(CycleText.delete));
      expect(tester.takeException(), isNull);
      expect((await store.read()).records, isEmpty);
    });

    testWidgets('only one question at a time, however fast the taps', (
      tester,
    ) async {
      await onRecipe(tester);
      // Asking again while the dialog is up answers "no" at once.
      final answer = await Confirm.ask(
        tester.element(find.byType(AlertDialog)),
        title: 'Again?',
        body: '',
        yes: 'Yes',
        no: 'No',
      );
      expect(answer, isFalse);
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
