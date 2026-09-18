import 'dart:io';
import 'dart:ui';

import 'package:almanac/app/theme/colour_contrast.dart';
import 'package:almanac/app/theme/seasonal_palettes.dart';
import 'package:almanac/core/environment/day_night.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:almanac/features/environment/domain/landscape_appearance.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the one place looks like — season by season, and hour by hour.
///
/// Structural, not pixel snapshots: a golden file would fail on every
/// deliberate change and tell nobody why. These assert the relationships
/// the references actually establish.
void main() {
  DayNightState dayNight(DayPhase phase) => DayNightState(
    phase: phase,
    daylight: switch (phase) {
      DayPhase.day => 1,
      DayPhase.dawn => 0.55,
      DayPhase.dusk => 0.45,
      DayPhase.night => 0,
    },
  );

  LandscapeAppearance look(Season season, DayPhase phase) =>
      LandscapeAppearance.resolve(
        season: season,
        dayNight: dayNight(phase),
        palette: SeasonalPalettes.resolve(
          season: season,
          daylight: dayNight(phase).daylight,
        ),
      );

  /// How green a colour is, relative to its other channels. Used to say
  /// "lusher" without pinning a hex value.
  double greenness(Color colour) => colour.g - (colour.r + colour.b) / 2;

  double lightness(Color colour) => colour.computeLuminance();

  group('the four seasons are four different days in one place', () {
    test('summer is lusher than spring, not merely a different green', () {
      final spring = look(Season.spring, DayPhase.day);
      final summer = look(Season.summer, DayPhase.day);

      // Denser bank, and a deeper green rather than a recoloured one.
      expect(summer.vegetationDensity, greaterThan(spring.vegetationDensity));
      expect(lightness(summer.foliage), lessThan(lightness(spring.foliage)));
      expect(greenness(summer.foliage), greaterThan(0));
      expect(summer.bough, BoughDress.leaf);
      expect(spring.bough, BoughDress.blossom);
    });

    test('summer is the fullest bank of the year', () {
      final densities = {
        for (final season in Season.values)
          season: look(season, DayPhase.day).vegetationDensity,
      };
      expect(densities[Season.summer], 1.0);
      for (final season in Season.values.where((s) => s != Season.summer)) {
        expect(
          densities[season],
          lessThan(densities[Season.summer]!),
          reason: season.name,
        );
      }
    });

    test('summer carries the approved forget-me-nots, and nothing else '
        'does', () {
      for (final season in Season.values) {
        final forms = look(season, DayPhase.day).flowers.map((f) => f.form);
        expect(
          forms.contains(FlowerForm.forgetMeNot),
          season == Season.summer,
          reason: season.name,
        );
      }
    });

    test('and they stay an accent rather than a border', () {
      final summer = look(Season.summer, DayPhase.day);
      final share = summer.flowers
          .firstWhere((f) => f.form == FlowerForm.forgetMeNot)
          .share;

      // A minority of the bank: present, noticeable, not a floral edge.
      expect(share, greaterThan(0.1));
      expect(share, lessThan(0.5));
      // And they are blue with a pale eye, as a forget-me-not is.
      final flower = summer.flowers.firstWhere(
        (f) => f.form == FlowerForm.forgetMeNot,
      );
      expect(flower.colour.b, greaterThan(flower.colour.r));
      expect(lightness(flower.centre), greaterThan(lightness(flower.colour)));
    });

    test('every season has a different set of flower forms', () {
      final sets = {
        for (final season in Season.values)
          season: look(season, DayPhase.day).flowers.map((f) => f.form).toSet(),
      };
      // Four distinct silhouette sets — explicitly not one five-petal
      // icon recoloured four times.
      expect(sets.values.toSet(), hasLength(4));
    });

    test('autumn goes to seed and turns the bough', () {
      final autumn = look(Season.autumn, DayPhase.day);
      expect(autumn.flowers.map((f) => f.form), contains(FlowerForm.seedHead));
      expect(autumn.bough, BoughDress.turned);
      // Earth rather than green.
      expect(
        greenness(autumn.foliage),
        lessThan(greenness(look(Season.summer, DayPhase.day).foliage)),
      );
    });

    test('AUTUMN DAYLIGHT IS NOT SUNSET', () {
      // The rule with its own heading in the brief: a daytime autumn sky
      // is a daytime sky. The mistake would be to bake the reference's
      // dusk palette into the season.
      final autumnDay = look(Season.autumn, DayPhase.day);
      final autumnDusk = look(Season.autumn, DayPhase.dusk);
      final summerDay = look(Season.summer, DayPhase.day);

      expect(autumnDay.light, LandscapeLight.day);
      expect(autumnDay.skyStops, isNot(autumnDusk.skyStops));

      // Its daytime sky is blue-led, the same way summer's is: the blue
      // channel leads the red one overhead.
      final overhead = autumnDay.skyStops.first;
      expect(overhead.b, greaterThan(overhead.r));
      expect(
        overhead.b - overhead.r,
        greaterThan(
          0.5 * (summerDay.skyStops.first.b - summerDay.skyStops.first.r),
        ),
      );
    });

    test('winter is sparser and cooler, and still the same place', () {
      final winter = look(Season.winter, DayPhase.day);
      final summer = look(Season.summer, DayPhase.day);

      expect(winter.vegetationDensity, lessThan(0.5));
      expect(winter.bough, BoughDress.bare);
      // Cooler: less green in the foliage than any other season.
      for (final season in [Season.spring, Season.summer]) {
        expect(
          greenness(winter.foliage),
          lessThan(greenness(look(season, DayPhase.day).foliage)),
          reason: season.name,
        );
      }
      expect(winter.form, summer.form);
    });
  });

  group('dawn, day, dusk and night are four different lights', () {
    test('each phase maps to its own state', () {
      expect(look(Season.spring, DayPhase.dawn).light, LandscapeLight.dawn);
      expect(look(Season.spring, DayPhase.day).light, LandscapeLight.day);
      expect(look(Season.spring, DayPhase.dusk).light, LandscapeLight.dusk);
      expect(look(Season.spring, DayPhase.night).light, LandscapeLight.night);
    });

    test('and each looks different from the others', () {
      for (final season in Season.values) {
        final skies = {
          for (final phase in DayPhase.values)
            phase: look(season, phase).skyStops,
        };
        expect(skies.values.toSet(), hasLength(4), reason: season.name);
      }
    });

    test('SUNSET IS NOT SUNRISE PLAYED BACKWARDS', () {
      for (final season in Season.values) {
        final dawn = look(season, DayPhase.dawn);
        final dusk = look(season, DayPhase.dusk);

        expect(dawn.skyStops, isNot(dusk.skyStops), reason: season.name);
        // Dusk runs warmer and more saturated overhead; dawn stays cool
        // up top with the colour held low.
        expect(
          dusk.skyStops.first.r - dusk.skyStops.first.b,
          greaterThan(dawn.skyStops.first.r - dawn.skyStops.first.b),
          reason: '${season.name}: dusk should be the warmer sky',
        );
      }
    });

    test('night deepens the same place rather than replacing it', () {
      for (final season in Season.values) {
        final day = look(season, DayPhase.day);
        final night = look(season, DayPhase.night);

        expect(
          lightness(night.skyStops.first),
          lessThan(lightness(day.skyStops.first)),
          reason: season.name,
        );
        expect(night.starStrength, 1);
        expect(day.starStrength, 0);
        expect(night.sunIsUp, isFalse);
        expect(day.sunIsUp, isTrue);
        // The geography is untouched.
        expect(night.form, day.form);
      }
    });

    test('and every season has its own night', () {
      final skies = {
        for (final season in Season.values)
          season: look(season, DayPhase.night).skyStops.first,
      };
      expect(skies.values.toSet(), hasLength(4));
    });

    test('the distance hazes most when the light is low', () {
      final day = look(Season.summer, DayPhase.day);
      for (final phase in [DayPhase.dawn, DayPhase.dusk]) {
        expect(
          look(Season.summer, phase).haze,
          greaterThan(day.haze),
          reason: phase.name,
        );
      }
    });
  });

  group('the scene has no astronomy and no clock of its own', () {
    final painter = File(
      'lib/features/environment/presentation/widgets/'
      'almanac_landscape_view.dart',
    ).readAsStringSync();
    final appearance = File(
      'lib/features/environment/domain/landscape_appearance.dart',
    ).readAsStringSync();

    test('no second sun, and no DateTime.now in the painting path', () {
      for (final source in [painter, appearance]) {
        expect(source.contains('DateTime.now'), isFalse);
        expect(source.contains('SolarService'), isFalse);
        expect(source.contains('sunriseAt'), isFalse);
        expect(source.contains('solarDayProgress'), isFalse);
      }
    });

    test('and the painting never asks for a location', () {
      for (final source in [painter, appearance]) {
        expect(source.contains('locationStateProvider'), isFalse);
        expect(source.contains('requestAccess'), isFalse);
        expect(source.contains('LocationService'), isFalse);
      }
    });

    test('the painter mixes no colour of its own', () {
      // Every colour comes from the appearance. A literal here would be a
      // season the palette does not know about.
      expect(painter.contains('Color(0x'), isFalse);
      expect(painter.contains('Colors.'), isFalse);
    });
  });

  group('chrome stays readable through the whole transition', () {
    /// Every state the Environment's own chrome can be seen against,
    /// including the twilight midpoints that were the known problem.
    Iterable<(String, double, Season)> states() sync* {
      for (final season in Season.values) {
        for (final daylight in [0.0, 0.25, 0.5, 0.5001, 0.75, 1.0]) {
          yield ('${season.name} at $daylight', daylight, season);
        }
      }
    }

    test('body text clears 4.5:1 everywhere, including the old bad '
        'midpoint', () {
      for (final (name, daylight, season) in states()) {
        final palette = SeasonalPalettes.resolve(
          season: season,
          daylight: daylight,
        );
        for (final (role, ink) in [
          ('textPrimary', palette.textPrimary),
          ('textSecondary', palette.textSecondary),
        ]) {
          final ratio = contrastRatio(ink, palette.background);
          expect(
            ratio,
            greaterThanOrEqualTo(kBodyTextContrast),
            reason: '$name: $role is ${ratio.toStringAsFixed(2)}:1',
          );
        }
      }
    });

    test('icons and control boundaries clear 3:1 everywhere', () {
      for (final (name, daylight, season) in states()) {
        final palette = SeasonalPalettes.resolve(
          season: season,
          daylight: daylight,
        );
        for (final (role, colour) in [
          ('icon', palette.icon),
          ('border', palette.border),
        ]) {
          final ratio = contrastRatio(colour, palette.background);
          expect(
            ratio,
            greaterThanOrEqualTo(kGraphicalContrast),
            reason: '$name: $role is ${ratio.toStringAsFixed(2)}:1',
          );
        }
      }
    });

    test('and content on every coloured container clears 4.5:1', () {
      for (final (name, daylight, season) in states()) {
        final palette = SeasonalPalettes.resolve(
          season: season,
          daylight: daylight,
        );
        for (final (role, ink, ground) in [
          ('onPrimary', palette.onPrimary, palette.primary),
          ('onPrimarySoft', palette.onPrimarySoft, palette.primarySoft),
          ('textPrimary on surface', palette.textPrimary, palette.surface),
          (
            'textPrimary on inset',
            palette.textPrimary,
            palette.surfaceElevated,
          ),
        ]) {
          final ratio = contrastRatio(ink, ground);
          expect(
            ratio,
            greaterThanOrEqualTo(kBodyTextContrast),
            reason: '$name: $role is ${ratio.toStringAsFixed(2)}:1',
          );
        }
      }
    });
  });
}
