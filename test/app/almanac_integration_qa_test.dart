import 'package:almanac/app/almanac_button.dart';
import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/app/router.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/solar_service.dart';
import 'package:almanac/core/environment/tide.dart';
import 'package:almanac/core/environment/tide_extrema.dart';
import 'package:almanac/core/environment/tide_service.dart';
import 'package:almanac/core/environment/weather.dart';
import 'package:almanac/core/environment/weather_service.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/features/environment/presentation/weather_narrative.dart';
import 'package:almanac/features/meditation/presentation/meditation_screen.dart';
import 'package:almanac/features/meditation/presentation/widgets/moon_context_card.dart';
import 'package:almanac/features/nature_log/domain/tide_nature_note.dart';
import 'package:almanac/features/nature_log/domain/weather_nature_note.dart';
import 'package:almanac/features/nature_log/presentation/nature_log_text.dart';
import 'package:almanac/features/wheel/presentation/festival_detail_page.dart';
import 'package:almanac/features/yoga/domain/festival_yoga.dart';
import 'package:almanac/features/yoga/domain/weather_yoga.dart';
import 'package:almanac/features/yoga/presentation/widgets/cycle_context_card.dart';
import 'package:almanac/features/yoga/presentation/yoga_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_environment_services.dart';
import '../support/test_overrides.dart';

/// Integration QA: every shared context the Almanac now carries —
/// weather, tides, the moon, the season, a festival, a cycle phase —
/// read together, across the whole app, to prove they coexist without
/// repeating, contradicting or crowding one another.
///
/// Four days before Beltane in the north (a fixed 1 May), at 13:00 in
/// London: the busiest ordinary day the app has, with a festival
/// approaching on top of everything else.
final _beltaneEve = DateTime.utc(2026, 4, 27, 12);

final _everything = FeatureRegistry.optional.map((f) => f.id).toSet();

/// Every optional feature except the Wheel of the Year.
final _allButWheel = {..._everything}..remove(FeatureId.wheel);

WeatherSnapshot _weather({
  required GeoLocation location,
  required DateTime obtainedAt,
  WeatherCondition condition = WeatherCondition.clear,
  double temperatureC = 15,
  double windKmh = 8,
  double precipitationMm = 0,
}) => WeatherSnapshot(
  location: location,
  obtainedAt: obtainedAt,
  current: CurrentWeather(
    temperatureC: temperatureC,
    apparentTemperatureC: temperatureC,
    condition: condition,
    precipitationMm: precipitationMm,
    cloudCoverPercent: condition == WeatherCondition.clear ? 5 : 90,
    windSpeedKmh: windKmh,
  ),
  today: const DailySummary(
    highC: 18,
    lowC: 9,
    precipitationProbabilityPercent: 10,
  ),
  hourly: const [],
);

FakeWeatherService _weatherService({
  WeatherCondition condition = WeatherCondition.clear,
  double temperatureC = 15,
  double windKmh = 8,
  double precipitationMm = 0,
}) => FakeWeatherService(
  result: ({required location, required timeZone, required now}) => _weather(
    location: location,
    obtainedAt: now,
    condition: condition,
    temperatureC: temperatureC,
    windKmh: windKmh,
    precipitationMm: precipitationMm,
  ),
);

/// A tide curve that is falling at the pinned instant — thirty hours of
/// history puts "now" a couple of hours past high water — so the Nature
/// Log has a tide note to show beside its weather note.
FakeTideService _fallingTide() => FakeTideService(
  result: ({required location, required timeZone, required now}) {
    final samples = testTideCurve(obtainedAt: now, pastHours: 30);
    return TideFetchData(
      TideSnapshot(
        location: location,
        obtainedAt: now,
        samples: samples,
        extrema: extractTideExtrema(samples),
      ),
    );
  },
);

/// The page's own vertical column — not the navigation strip, which
/// also scrolls on a narrow phone.
final _page = find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

const _phone = Size(390, 844);
const _tablet = Size(834, 1194);

void main() {
  setUpAll(useTimeZoneDatabase);

  Future<ProviderContainer> open(
    WidgetTester tester, {
    Set<FeatureId>? features,
    DateTime? now,
    bool located = true,
    WeatherService? weather,
    TideService? tides,
    Size surface = const Size(430, 2400),
    double textScale = 1,
    List<Override>? overrides,
  }) async {
    tester.view.physicalSize = surface * 2;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final container = ProviderContainer(
      overrides:
          overrides ??
          environmentOverrides(
            now: now ?? _beltaneEve,
            features: features ?? _everything,
            locationState: located
                ? const LocationAvailable(TestLocations.london)
                : null,
            // With no position there are no sun times either — the
            // state in which the Environment offers location.
            solarService: located ? null : FakeSolarService(),
            // Never the network: a located test with no forecast of its
            // own gets a failing service, which the app treats exactly
            // like no signal.
            weatherService:
                weather ??
                FakeWeatherService(failWith: Exception('offline in test')),
            tideService:
                tides ??
                FakeTideService(failWith: Exception('offline in test')),
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
    return container;
  }

  Future<void> go(
    WidgetTester tester,
    ProviderContainer container,
    String route,
  ) async {
    container.read(routerProvider).go(route);
    await tester.pumpAndSettle();
  }

  String routeOf(FeatureId id) => FeatureRegistry.byId(id).route;

  double topOf(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder.first).dy;

  /// Every visible line of text at or below [label], in reading order —
  /// the TODAY section and nothing above it.
  List<String> linesBelow(WidgetTester tester, Finder label) {
    final top = topOf(tester, label);
    final bar = topOf(tester, find.byType(AlmanacNavigationBar));
    return [
      for (final element in find.byType(Text).evaluate())
        if (tester.getTopLeft(find.byWidget(element.widget)).dy >= top &&
            tester.getTopLeft(find.byWidget(element.widget)).dy < bar)
          (element.widget as Text).data ??
              (element.widget as Text).textSpan?.toPlainText() ??
              '',
    ];
  }

  group('TODAY across combinations of context', () {
    final weatherSentence = describeWeather(
      weather: _weather(
        location: TestLocations.london,
        obtainedAt: _beltaneEve,
      ),
      localNow: TestTimeZones.london.wallTimeAt(_beltaneEve),
    );

    testWidgets('weather + festival: weather, then season, then festival, '
        'each once', (tester) async {
      await open(tester, weather: _weatherService(), tides: _fallingTide());

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text(weatherSentence), findsOneWidget);
      expect(find.textContaining('arrives'), findsOneWidget);
      expect(find.text('Beltane is approaching · 4 days'), findsOneWidget);
      expect(find.text('See Beltane'), findsOneWidget);

      final weatherTop = topOf(tester, find.text(weatherSentence));
      final seasonTop = topOf(tester, find.textContaining('arrives'));
      final festivalTop = topOf(
        tester,
        find.text('Beltane is approaching · 4 days'),
      );
      expect(topOf(tester, find.text('TODAY')), lessThan(weatherTop));
      expect(weatherTop, lessThan(seasonTop));
      expect(seasonTop, lessThan(festivalTop));
    });

    testWidgets('TODAY never repeats the moon or the tide from the strip', (
      tester,
    ) async {
      await open(tester, weather: _weatherService(), tides: _fallingTide());

      // Both facts are on the page, once, in the strip above TODAY.
      expect(find.text('Moon'), findsOneWidget);
      expect(find.text('Tides'), findsOneWidget);
      expect(
        topOf(tester, find.text('Tides')),
        lessThan(topOf(tester, find.text('TODAY'))),
      );

      for (final line in linesBelow(tester, find.text('TODAY'))) {
        final lower = line.toLowerCase();
        expect(lower, isNot(contains('tide')), reason: line);
        expect(lower, isNot(contains('moon')), reason: line);
        expect(lower, isNot(contains('high water')), reason: line);
      }
    });

    testWidgets('weather only: no festival line when the Wheel is off', (
      tester,
    ) async {
      await open(tester, features: _allButWheel, weather: _weatherService());

      expect(find.text(weatherSentence), findsOneWidget);
      expect(find.textContaining('arrives'), findsOneWidget);
      expect(find.textContaining('Beltane'), findsNothing);
    });

    testWidgets('weather unavailable: season and festival stand on their '
        'own, with no apology', (tester) async {
      await open(tester);

      for (final part in ['morning', 'afternoon', 'evening', 'tonight']) {
        expect(find.textContaining(part), findsNothing);
      }
      expect(find.textContaining('arrives'), findsOneWidget);
      expect(find.text('Beltane is approaching · 4 days'), findsOneWidget);
      expect(find.textContaining('unavailable'), findsNothing);
      expect(find.textContaining('error'), findsNothing);
    });

    testWidgets('festival only, no location: one invitation, after TODAY', (
      tester,
    ) async {
      await open(tester, located: false);

      expect(find.text('Beltane is approaching · 4 days'), findsOneWidget);
      final invitation = find.text(
        'Connect location to see sunrise, sunset, weather and tides where '
        'you are.',
      );
      expect(invitation, findsOneWidget);
      expect(
        topOf(tester, find.text('TODAY')),
        lessThan(topOf(tester, invitation)),
      );
      // The tide fact says plainly why it is quiet, without a second
      // invitation of its own.
      expect(find.textContaining('Connect location'), findsOneWidget);
    });

    testWidgets('polar day with weather: the sun is said once, and the '
        'weather sentence still reads', (tester) async {
      final midsummer = DateTime.utc(2026, 6, 21, 10);
      await open(
        tester,
        overrides: environmentOverrides(
          now: midsummer,
          features: _everything,
          timeZone: TestTimeZones.tromso,
          solarService: FakeSolarService(kind: SolarDayKind.sunNeverSets),
          locationState: const LocationAvailable(TestLocations.tromso),
          weatherService: _weatherService(),
          tideService: FakeTideService(failWith: Exception('offline')),
        ),
      );

      expect(
        find.text('The sun stays above the horizon all day where you are.'),
        findsOneWidget,
      );
      expect(find.text('Sunrise'), findsNothing);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.textContaining('arrives'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final (name, instant) in [
      // London is on British Summer Time in April: UTC+1.
      ('morning', DateTime.utc(2026, 4, 27, 7)),
      ('afternoon', DateTime.utc(2026, 4, 27, 13)),
      ('evening', DateTime.utc(2026, 4, 27, 18)),
      ('night', DateTime.utc(2026, 4, 27, 22, 30)),
    ]) {
      testWidgets('$name: one weather sentence, in the page\'s own voice', (
        tester,
      ) async {
        await open(tester, now: instant, weather: _weatherService());

        final sentence = describeWeather(
          weather: _weather(
            location: TestLocations.london,
            obtainedAt: instant,
          ),
          localNow: TestTimeZones.london.wallTimeAt(instant),
        );
        expect(find.text(sentence), findsOneWidget);
        final lower = sentence.toLowerCase();
        for (final foreign in ['tide', 'moon', 'beltane', 'cycle', 'phase']) {
          expect(lower, isNot(contains(foreign)), reason: sentence);
        }
      });
    }
  });

  group('weather and tides stay separate', () {
    testWidgets('the Nature Log gives each its own line, under one label', (
      tester,
    ) async {
      // Rain earlier, sky now clear: an "after rain" weather cue.
      final container = await open(
        tester,
        weather: _weatherService(precipitationMm: 1.2),
        tides: _fallingTide(),
      );
      await go(tester, container, routeOf(FeatureId.natureLog));

      final weatherNote = WeatherNatureNotes.noteFor(
        NatureWeatherCue.afterRain,
      );
      final tideNote = TideNatureNotes.noteFor(TideNatureCue.fallingShoreline);
      await tester.scrollUntilVisible(
        find.text(tideNote),
        200,
        scrollable: _page,
      );

      expect(find.text(NatureLogText.outsideToday), findsOneWidget);
      expect(find.text(weatherNote), findsOneWidget);
      expect(find.text(tideNote), findsOneWidget);
      // Two lines, not one merged sentence, weather first.
      expect(
        topOf(tester, find.text(weatherNote)),
        lessThan(topOf(tester, find.text(tideNote))),
      );
      expect(weatherNote.toLowerCase(), isNot(contains('tide')));
      for (final word in ['rain', 'wind', 'sun', 'weather']) {
        expect(tideNote.toLowerCase(), isNot(contains(word)));
      }
    });

    testWidgets('with neither, the Nature Log adds no empty label', (
      tester,
    ) async {
      final container = await open(tester);
      await go(tester, container, routeOf(FeatureId.natureLog));

      expect(find.text(NatureLogText.outsideToday), findsNothing);
    });
  });

  group('no suggestion is made twice on one page', () {
    List<String> headingsOf<T extends Widget>(
      WidgetTester tester,
      String Function(T) heading,
    ) => [
      for (final card in tester.widgetList<T>(find.byType(T))) heading(card),
    ];

    testWidgets('Meditation: wind and Beltane both suggest Balance, so the '
        'weather yields', (tester) async {
      final container = await open(
        tester,
        weather: _weatherService(windKmh: 30),
      );
      await go(tester, container, routeOf(FeatureId.meditation));

      final cards = tester
          .widgetList<MoonContextCard>(find.byType(MoonContextCard))
          .toList();
      expect(cards.length, lessThanOrEqualTo(kMaxMeditationContexts));
      expect(find.text('Wind today'), findsNothing);
      expect(find.text('For today'), findsOneWidget);
      expect(find.text('Beltane'), findsOneWidget);
    });

    for (final (name, service) in [
      ('rain', () => _weatherService(condition: WeatherCondition.rain)),
      ('wind', () => _weatherService(windKmh: 30)),
      ('clear skies', () => _weatherService()),
      ('cloud', () => _weatherService(condition: WeatherCondition.cloudy)),
    ]) {
      testWidgets('Meditation with $name: at most three suggestions, and '
          'the weather never repeats one already made', (tester) async {
        final container = await open(tester, weather: service());
        await go(tester, container, routeOf(FeatureId.meditation));

        final cards = tester
            .widgetList<MoonContextCard>(find.byType(MoonContextCard))
            .toList();
        expect(cards.length, lessThanOrEqualTo(kMaxMeditationContexts));
        const weatherHeadings = {'Rain today', 'Wind today', 'Settled weather'};
        final others = [
          for (final c in cards)
            if (!weatherHeadings.contains(c.heading)) c.technique.id,
        ];
        for (final c in cards) {
          if (weatherHeadings.contains(c.heading)) {
            expect(others, isNot(contains(c.technique.id)));
          }
        }
        expect(find.text('For today'), findsOneWidget);
      });
    }

    testWidgets('Yoga: settled weather would repeat Beltane\'s practice, so '
        'it yields', (tester) async {
      final container = await open(tester, weather: _weatherService());
      await go(tester, container, routeOf(FeatureId.yoga));

      expect(
        WeatherYoga.practiceFor(WeatherYogaCue.settled),
        FestivalYoga.practiceFor(FestivalId.beltane).id,
      );
      final headings = headingsOf<CycleContextCard>(tester, (c) => c.heading);
      expect(headings, ['Beltane']);
      expect(find.text(YogaText.forToday), findsOneWidget);
      expect(find.text('Weather today'), findsNothing);
    });

    testWidgets('Yoga: rain adds a different practice, under its own '
        'heading, and "For today" is still said once', (tester) async {
      final container = await open(
        tester,
        weather: _weatherService(condition: WeatherCondition.rain),
      );
      await go(tester, container, routeOf(FeatureId.yoga));

      final cards = tester
          .widgetList<CycleContextCard>(find.byType(CycleContextCard))
          .toList();
      expect([for (final c in cards) c.heading], ['Beltane', 'Weather today']);
      final ids = [for (final c in cards) c.practice.id];
      expect(ids.toSet().length, ids.length);
      expect(cards.length, lessThanOrEqualTo(kMaxYogaContexts));
      expect(find.text(YogaText.forToday), findsOneWidget);
      // The three practices are still all there, under the context.
      for (final name in ['Morning', 'Ground', 'Unwind']) {
        expect(find.textContaining(name), findsWidgets);
      }
    });

    testWidgets('Yoga with nothing to say shows no "For today" at all', (
      tester,
    ) async {
      final container = await open(tester, features: _allButWheel);
      await go(tester, container, routeOf(FeatureId.yoga));

      expect(find.byType(CycleContextCard), findsNothing);
      expect(find.text(YogaText.forToday), findsNothing);
    });

    testWidgets('Cookbook: the seasonal collection first, the festival once, '
        'after it', (tester) async {
      final container = await open(tester, weather: _weatherService());
      await go(tester, container, routeOf(FeatureId.cookbook));

      final festival = find.text('Beltane is approaching');
      await tester.scrollUntilVisible(festival, 300, scrollable: _page);
      expect(festival, findsOneWidget);
      expect(find.textContaining('Beltane'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Your season'),
        -300,
        scrollable: _page,
      );
      expect(find.text('Your season'), findsOneWidget);
    });
  });

  group('a feature switched off leaves nothing behind', () {
    testWidgets('no Beltane anywhere in the app when the Wheel is off', (
      tester,
    ) async {
      final container = await open(
        tester,
        features: _allButWheel,
        weather: _weatherService(),
        tides: _fallingTide(),
      );

      for (final feature in FeatureRegistry.all) {
        if (feature.id == FeatureId.wheel) continue;
        await go(tester, container, feature.route);
        expect(
          find.textContaining('Beltane'),
          findsNothing,
          reason: '${feature.name} mentioned a festival',
        );
        expect(find.textContaining('Wheel of the Year'), findsNothing);
      }
      expect(
        tester
            .widget<AlmanacNavigationBar>(find.byType(AlmanacNavigationBar))
            .destinations
            .map((f) => f.id),
        isNot(contains(FeatureId.wheel)),
      );
    });

    testWidgets('with nothing chosen, the Environment stands alone and '
        'offers no doorway into a missing feature', (tester) async {
      await open(tester, features: const {}, weather: _weatherService());

      expect(
        tester
            .widget<AlmanacNavigationBar>(find.byType(AlmanacNavigationBar))
            .destinations
            .length,
        1,
      );
      expect(find.textContaining('Beltane'), findsNothing);
      expect(find.textContaining('See '), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('navigation holds ten categories', () {
    for (final size in [_phone, _tablet]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets('${size.width.toInt()}×${size.height.toInt()} at '
            '${scale}x: ten, named, tappable, never truncated', (tester) async {
          final handle = tester.ensureSemantics();
          await open(tester, surface: size, textScale: scale);

          final bar = tester.widget<AlmanacNavigationBar>(
            find.byType(AlmanacNavigationBar),
          );
          expect(bar.destinations.map((f) => f.name), [
            for (final f in FeatureRegistry.all) f.name,
          ]);
          expect(find.text('More'), findsNothing);
          expect(find.textContaining('…'), findsNothing);
          expect(find.textContaining('...'), findsNothing);

          final strip = find.descendant(
            of: find.byType(AlmanacNavigationBar),
            matching: find.byType(Scrollable),
          );
          for (final feature in FeatureRegistry.all) {
            final item = find.descendant(
              of: find.byType(AlmanacNavigationBar),
              matching: find.bySemanticsLabel(feature.name),
            );
            if (strip.evaluate().isNotEmpty) {
              await tester.scrollUntilVisible(item, 80, scrollable: strip);
            }
            expect(item, findsOneWidget, reason: feature.name);
            final itemSize = tester.getSize(item);
            expect(itemSize.width, greaterThanOrEqualTo(48));
            expect(itemSize.height, greaterThanOrEqualTo(48));
          }
          // The Wheel's tab, now scrolled into view, reads as a holiday
          // — never an abbreviation of its full name.
          expect(
            find.descendant(
              of: find.byType(AlmanacNavigationBar),
              matching: find.byWidgetPredicate(
                (w) => w is Text && (w.data == 'Hols' || w.data == 'Holidays'),
              ),
            ),
            findsOneWidget,
          );
          // And the Journal's reads as "Journal", or its agreed "Jour",
          // announced in full either way.
          expect(
            find.descendant(
              of: find.byType(AlmanacNavigationBar),
              matching: find.byWidgetPredicate(
                (w) => w is Text && (w.data == 'Jour' || w.data == 'Journal'),
              ),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(AlmanacNavigationBar),
              matching: find.bySemanticsLabel('Journal'),
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          handle.dispose();
        });
      }
    }
  });

  group('responsive QA: every surface at phone and tablet, 1x to 2x', () {
    /// Scrolls the page's main column to its end, a screen at a time, so
    /// a lazily built list lays out every section — an overflow anywhere
    /// is reported as an exception on the way.
    Future<void> readToTheEnd(WidgetTester tester, String where) async {
      final column = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      if (column.evaluate().isEmpty) return;
      for (var i = 0; i < 12; i++) {
        await tester.drag(column.first, const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: where);
      }
    }

    for (final size in [_phone, _tablet]) {
      for (final (stage, settings) in [
        ('name', (nameAsked: false, hemisphere: false, intro: false)),
        ('hemisphere', (nameAsked: true, hemisphere: false, intro: false)),
        ('location', (nameAsked: true, hemisphere: true, intro: false)),
        ('categories', (nameAsked: true, hemisphere: true, intro: true)),
      ]) {
        testWidgets('onboarding, $stage, ${size.width.toInt()}×'
            '${size.height.toInt()} at 2x', (tester) async {
          await open(
            tester,
            surface: size,
            textScale: 2,
            overrides: environmentOverrides(
              onboardingCompleted: false,
              nameAsked: settings.nameAsked,
              hemisphere: settings.hemisphere ? Hemisphere.northern : null,
              locationIntroSeen: settings.intro,
            ),
          );
          expect(tester.takeException(), isNull, reason: stage);
          await readToTheEnd(tester, stage);
        });
      }
    }

    for (final size in [_phone, _tablet]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets('${size.width.toInt()}×${size.height.toInt()} at '
            '${scale}x', (tester) async {
          final container = await open(
            tester,
            surface: size,
            textScale: scale,
            weather: _weatherService(condition: WeatherCondition.rain),
            tides: _fallingTide(),
          );
          expect(tester.takeException(), isNull, reason: 'Environment');
          await readToTheEnd(tester, 'Environment');

          await go(tester, container, routeOf(FeatureId.wheel));
          expect(tester.takeException(), isNull, reason: 'Wheel');
          await readToTheEnd(tester, 'Wheel');

          // A festival detail page, reached the way a person would: the
          // doorway under TODAY.
          await go(tester, container, kEnvironmentRoute);
          final doorway = find.text('See Beltane');
          await tester.scrollUntilVisible(doorway, 300, scrollable: _page);
          await tester.tap(doorway);
          await tester.pumpAndSettle();
          expect(find.byType(FestivalDetailPage), findsOneWidget);
          expect(tester.takeException(), isNull, reason: 'Festival detail');
          await readToTheEnd(tester, 'Festival detail');

          for (final id in [
            FeatureId.meditation,
            FeatureId.yoga,
            FeatureId.cookbook,
            FeatureId.garden,
            FeatureId.natureLog,
            FeatureId.cycle,
            FeatureId.chakras,
          ]) {
            await go(tester, container, routeOf(id));
            expect(tester.takeException(), isNull, reason: id.name);
            await readToTheEnd(tester, id.name);
          }

          // And the drawer, over the Environment.
          await go(tester, container, kEnvironmentRoute);
          // Back to the masthead, which the reading above scrolled past.
          await tester.scrollUntilVisible(
            find.byType(AlmanacButton),
            -500,
            scrollable: _page,
          );
          await tester.tap(find.byType(AlmanacButton).first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Drawer');
          await readToTheEnd(tester, 'Drawer');
        });
      }
    }
  });
}
