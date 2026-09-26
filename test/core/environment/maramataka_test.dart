import 'package:almanac/core/context/almanac_context.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/core/settings/settings_store.dart';
import 'package:almanac/core/settings/shared_preferences_settings_store.dart';
import 'package:almanac/core/settings/user_settings.dart';
import 'package:almanac/features/environment/presentation/maramataka_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/test_overrides.dart';

void main() {
  const each = Maramataka.synodicMonthDays / 30;

  group('the reference sequence', () {
    test('thirty nights, ordered 1 to 30, ids unique', () {
      expect(Maramataka.nights, hasLength(30));
      expect(
        Maramataka.nights.map((n) => n.order),
        List.generate(30, (i) => i + 1),
      );
      expect(Maramataka.nights.map((n) => n.id).toSet(), hasLength(30));
      expect(Maramataka.nights.map((n) => n.name).toSet(), hasLength(30));
    });

    test('Whiro is first and Mutuwhenua last', () {
      expect(Maramataka.nights.first.name, 'Whiro');
      expect(Maramataka.nights.last.name, 'Mutuwhenua');
    });

    test('macrons are kept exactly as published', () {
      String nameOf(String id) => Maramataka.tryById(id)!.name;
      expect(nameOf('ouenuku'), 'Ōuenuku');
      expect(nameOf('mawharu'), 'Māwharu');
      expect(nameOf('rakau-nui'), 'Rākau-nui');
      expect(nameOf('rakau-matohi'), 'Rākau-matohi');
      expect(nameOf('tangaroa-a-mua'), 'Tangaroa-ā-mua');
      expect(nameOf('tangaroa-a-roto'), 'Tangaroa-ā-roto');
      expect(nameOf('otane'), 'Ōtāne');
      expect(nameOf('orongonui'), 'Ōrongonui');
      expect(nameOf('omutu'), 'Ōmutu');
      // Ids are plain, stable ASCII — what a saved page records.
      for (final night in Maramataka.nights) {
        expect(night.id, matches(RegExp(r'^[a-z-]+$')), reason: night.name);
      }
    });

    test('one source for the whole sequence — never a hybrid', () {
      expect(Maramataka.nights.map((n) => n.source).toSet(), {
        MaramatakaSource.teAra,
      });
      expect(Maramataka.referenceId, 'te-ara-ngati-kahungunu');
    });

    test('every night has published content, and nothing is a placeholder '
        'or an invented story', () {
      final banned = RegExp(
        r'TODO|coming soon|story coming|invented|lorem|placeholder|TBD',
        caseSensitive: false,
      );
      for (final night in Maramataka.nights) {
        expect(night.about.trim(), isNotEmpty, reason: night.name);
        for (final text in [night.name, night.about, ...night.associations]) {
          expect(text, isNot(matches(banned)), reason: night.name);
        }
        // Associations are said as tradition, attributed — never advice.
        for (final association in night.associations) {
          expect(association, startsWith('Te Ara notes that'));
          expect(association, contains('traditionally'));
          expect(
            association,
            isNot(matches(RegExp(r'\b(you should|best to)\b'))),
          );
        }
      }
      for (final text in MaramatakaText.everythingSaid) {
        expect(text, isNot(matches(banned)));
      }
      for (final source in MaramatakaSource.values) {
        expect(source.name, isNotEmpty);
        expect(source.detail, isNotEmpty);
      }
    });

    test('the source note names the Ngāti Kahungunu sequence explicitly', () {
      expect(MaramatakaSource.teAra.detail, contains('Ngāti Kahungunu'));
      expect(MaramatakaSource.teAra.name, contains('Te Ara'));
      expect(MaramatakaSource.tePapa.name, contains('Te Papa'));
    });

    test('the variation note is the agreed wording', () {
      expect(
        Maramataka.variationNote,
        'Maramataka traditions vary between iwi and rohe. This view uses a '
        'published reference sequence and should not be read as universal.',
      );
    });
  });

  group('mapping the Moon\'s age to a night', () {
    test('the new moon is Whiro, the last sliver Mutuwhenua', () {
      expect(Maramataka.nightForAge(0).name, 'Whiro');
      expect(
        Maramataka.nightForAge(Maramataka.synodicMonthDays - 0.001).name,
        'Mutuwhenua',
      );
    });

    test('every age inside a night maps to that night', () {
      for (final night in Maramataka.nights) {
        final range = Maramataka.ageRangeOf(night);
        expect(range.to - range.from, closeTo(each, 1e-9));
        for (final t in [0.01, 0.5, 0.99]) {
          final age = range.from + (range.to - range.from) * t;
          expect(Maramataka.nightForAge(age), same(night), reason: '$age');
        }
      }
    });

    test('wraps deterministically: past a month, or negative', () {
      final month = Maramataka.synodicMonthDays;
      for (final age in [0.0, 3.3, 14.8, 29.0]) {
        expect(
          Maramataka.nightForAge(age + month),
          same(Maramataka.nightForAge(age)),
        );
        expect(
          Maramataka.nightForAge(age + 5 * month),
          same(Maramataka.nightForAge(age)),
        );
      }
      expect(Maramataka.nightForAge(month).name, 'Whiro');
      expect(Maramataka.nightForAge(-0.01).name, 'Mutuwhenua');
      expect(Maramataka.nightForAge(double.nan).name, 'Whiro');
      expect(Maramataka.nightForAge(double.infinity).name, 'Whiro');
    });

    test('ranges tile the month with no gaps', () {
      var from = 0.0;
      for (final night in Maramataka.nights) {
        final range = Maramataka.ageRangeOf(night);
        expect(range.from, closeTo(from, 1e-9));
        from = range.to;
      }
      expect(from, closeTo(Maramataka.synodicMonthDays, 1e-9));
    });
  });

  group('gated by the setting', () {
    ProviderContainer containerWith({required bool include}) {
      final container = ProviderContainer(
        overrides: environmentOverrides(
          now: DateTime.utc(2026, 9, 26, 12),
          includeMaramataka: include,
        ),
      );
      addTearDown(container.dispose);
      return container;
    }

    test('off: nothing at all', () {
      expect(
        containerWith(include: false).read(currentMaramatakaProvider),
        isNull,
      );
    });

    test('on: the night for the one Moon the app already has', () {
      final container = containerWith(include: true);
      final moon = container.read(currentMoonProvider);
      expect(
        container.read(currentMaramatakaProvider),
        same(Maramataka.nightForAge(moon.ageInDays)),
      );
    });

    test('turning it off takes it away at once', () async {
      final container = containerWith(include: true);
      expect(container.read(currentMaramatakaProvider), isNotNull);
      await container
          .read(userSettingsProvider.notifier)
          .setIncludeMaramataka(false);
      expect(container.read(currentMaramatakaProvider), isNull);
    });

    test('adds no category and no feature id', () {
      expect(
        FeatureId.values.map((id) => id.name),
        isNot(contains(matches(RegExp('maramataka', caseSensitive: false)))),
      );
      expect(
        FeatureRegistry.all.map((f) => f.name.toLowerCase()),
        isNot(contains(contains('maramataka'))),
      );
    });
  });

  group('the setting persists', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    Future<SettingsStore> open() => SharedPreferencesSettingsStore.open();

    test('defaults to off', () async {
      expect((await open()).read().includeMaramataka, isFalse);
      expect(const UserSettings().includeMaramataka, isFalse);
    });

    test('on survives a restart; off survives a restart', () async {
      final base = const UserSettings(
        name: 'Robin',
        nameAsked: true,
        hemisphere: Hemisphere.southern,
        locationIntroSeen: true,
        features: {FeatureId.journal, FeatureId.garden},
        onboardingCompleted: true,
      );
      await (await open()).write(base.copyWith(includeMaramataka: true));
      final on = (await open()).read();
      expect(on.includeMaramataka, isTrue);
      // Nothing else moved.
      expect(on.copyWith(includeMaramataka: false), base);

      await (await open()).write(on.copyWith(includeMaramataka: false));
      final off = (await open()).read();
      expect(off.includeMaramataka, isFalse);
      expect(off, base);
    });

    test('a damaged stored value reads as off, and nothing else is '
        'disturbed', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            'settings.includeMaramataka': 'yes please',
            'settings.name': 'Robin',
            'settings.hemisphere': 'southern',
            'settings.nameAsked': true,
            'settings.locationIntroSeen': true,
            'settings.onboardingCompleted': true,
            'settings.features': <String>['journal'],
          });
      final settings = (await open()).read();
      expect(settings.includeMaramataka, isFalse);
      expect(settings.name, 'Robin');
      expect(settings.hemisphere, Hemisphere.southern);
      expect(settings.features, {FeatureId.journal});
      expect(settings.onboardingCompleted, isTrue);
    });

    test('changing it through the controller changes nothing else', () async {
      final store = InMemorySettingsStore(
        const UserSettings(name: 'Sam', features: {FeatureId.yoga}),
      );
      final container = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container
          .read(userSettingsProvider.notifier)
          .setIncludeMaramataka(true);
      final saved = store.read();
      expect(saved.includeMaramataka, isTrue);
      expect(saved.name, 'Sam');
      expect(saved.features, {FeatureId.yoga});
    });
  });
}
