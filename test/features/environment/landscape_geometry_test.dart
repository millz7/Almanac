import 'dart:io';
import 'dart:ui';

import 'package:almanac/app/theme/seasonal_palettes.dart';
import 'package:almanac/core/environment/day_night.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:almanac/features/environment/domain/almanac_landscape.dart';
import 'package:almanac/features/environment/domain/landscape_appearance.dart';
import 'package:flutter_test/flutter_test.dart';

/// **THE LANDSCAPE IS ONE PLACE. THE GEOMETRY STAYS FIXED; THE
/// ENVIRONMENT CHANGES.**
///
/// This file is that rule, in code. It should fail if somebody later
/// moves the mountain for Winter.
void main() {
  const size = Size(390, 260);

  DayNightState dayNight(DayPhase phase) => DayNightState(
    phase: phase,
    daylight: switch (phase) {
      DayPhase.day => 1,
      DayPhase.dawn => 0.55,
      DayPhase.dusk => 0.45,
      DayPhase.night => 0,
    },
  );

  LandscapeAppearance appearance(Season season, DayPhase phase) =>
      LandscapeAppearance.resolve(
        season: season,
        dayNight: dayNight(phase),
        palette: SeasonalPalettes.resolve(
          season: season,
          daylight: dayNight(phase).daylight,
        ),
      );

  /// Every fixed feature of the place, as drawn.
  ///
  /// A `Path` has no value equality, so the comparison is on what a path
  /// actually occupies: its bounds, to a hundredth of a pixel. Move a
  /// peak and the bounds move with it.
  Map<String, Rect> fixedFeatures(LandscapeAppearance appearance) {
    final form = appearance.form;
    return {
      'far range': form
          .ridge(
            AlmanacLandscape.farRange,
            size,
            floor: AlmanacLandscape.horizon,
          )
          .getBounds(),
      'near range': form
          .ridge(
            AlmanacLandscape.nearRange,
            size,
            floor: AlmanacLandscape.horizon,
          )
          .getBounds(),
      'left headland': form
          .smoothed(AlmanacLandscape.leftHeadland, size)
          .getBounds(),
      'right headland': form
          .smoothed(AlmanacLandscape.rightHeadland, size)
          .getBounds(),
      'right spur': form.smoothed(AlmanacLandscape.rightSpur, size).getBounds(),
      for (final (index, island) in AlmanacLandscape.islands.indexed)
        'island $index': form.smoothed(island, size).getBounds(),
      'bank': form.bank(size).getBounds(),
      'boulder': form.smoothed(AlmanacLandscape.boulder, size).getBounds(),
      'water': form.water(size),
      'sky': form.sky(size),
    };
  }

  const seasons = Season.values;
  const phases = DayPhase.values;

  group('the geometry does not vary with the season', () {
    test('every season carries the same form, and it is the same object', () {
      for (final season in seasons) {
        for (final phase in phases) {
          expect(
            identical(appearance(season, phase).form, AlmanacLandscape.form),
            isTrue,
            reason: '${season.name} ${phase.name}',
          );
        }
      }
    });

    test('Spring == Summer == Autumn == Winter, feature by feature', () {
      final reference = fixedFeatures(appearance(Season.spring, DayPhase.day));
      for (final season in seasons.skip(1)) {
        final other = fixedFeatures(appearance(season, DayPhase.day));
        for (final entry in reference.entries) {
          expect(
            other[entry.key],
            entry.value,
            reason: '${season.name} moved the ${entry.key}',
          );
        }
      }
    });

    test('and day == dawn == dusk == night, feature by feature', () {
      for (final season in seasons) {
        final reference = fixedFeatures(appearance(season, DayPhase.day));
        for (final phase in phases.skip(1)) {
          final other = fixedFeatures(appearance(season, phase));
          for (final entry in reference.entries) {
            expect(
              other[entry.key],
              entry.value,
              reason: '${season.name} ${phase.name} moved the ${entry.key}',
            );
          }
        }
      }
    });

    test('all sixteen states agree on every feature', () {
      // The full grid, so no pair can drift past the two tests above.
      final seen = <String, Set<Rect>>{};
      for (final season in seasons) {
        for (final phase in phases) {
          fixedFeatures(appearance(season, phase)).forEach((name, bounds) {
            (seen[name] ??= <Rect>{}).add(bounds);
          });
        }
      }
      for (final entry in seen.entries) {
        expect(entry.value, hasLength(1), reason: entry.key);
      }
    });
  });

  group('the foreground may change without the land changing', () {
    test('summer is denser than winter on the same bank', () {
      final summer = appearance(Season.summer, DayPhase.day);
      final winter = appearance(Season.winter, DayPhase.day);

      expect(
        summer.vegetationDensity,
        greaterThan(winter.vegetationDensity),
        reason: 'summer should cover more of the same shoreline',
      );
      expect(
        fixedFeatures(summer)['bank'],
        fixedFeatures(winter)['bank'],
        reason: 'and the bank underneath is identical',
      );
      expect(
        fixedFeatures(summer)['left headland'],
        fixedFeatures(winter)['left headland'],
      );
    });

    test('the places plants grow are fixed, whatever grows in them', () {
      // Density decides how many of these are used, never where they are.
      const plantings = AlmanacLandscape.plantings;
      expect(plantings, isNotEmpty);
      expect(identical(AlmanacLandscape.plantings, plantings), isTrue);

      for (final season in seasons) {
        expect(
          appearance(season, DayPhase.day).flowers,
          isNotEmpty,
          reason: '${season.name} has something on the bank',
        );
      }
      // And after building all of them, the list is untouched.
      expect(AlmanacLandscape.plantings, plantings);
    });

    test('flowers do not touch the land paths', () {
      final bare = fixedFeatures(appearance(Season.winter, DayPhase.day));
      final full = fixedFeatures(appearance(Season.summer, DayPhase.day));
      expect(full, bare);
    });
  });

  group('the geometry file cannot know about the season', () {
    /// Comments stripped: the file's own documentation explains the rule
    /// by naming what it may not import, and a test that could not tell
    /// an explanation from an import would be useless.
    final source =
        File('lib/features/environment/domain/almanac_landscape.dart')
            .readAsLinesSync()
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');

    test('it imports nothing that could tell it', () {
      // This is what makes the rule provable rather than promised: there
      // is no parameter a future edit could branch a winter mountain on
      // without first importing something this file is not allowed to
      // import.
      for (final forbidden in [
        'Season',
        'DayPhase',
        'Daylight',
        'daylight',
        'Palette',
        'Appearance',
        'MoonPhase',
      ]) {
        expect(
          source.contains(forbidden),
          isFalse,
          reason: 'almanac_landscape.dart mentions $forbidden',
        );
      }
    });

    test('and names no colour at all', () {
      expect(source.contains('Color('), isFalse);
      expect(source.contains('package:flutter/material.dart'), isFalse);
    });

    test('and no pixel: every coordinate is normalised', () {
      // Offsets in this file are unit-square coordinates. If any of them
      // leaves 0..1 it is a pixel that has crept in — with the one
      // documented exception of the bough, which starts just off the
      // left edge so the branch enters from outside the frame.
      for (final point in [
        ...AlmanacLandscape.farRange,
        ...AlmanacLandscape.nearRange,
        ...AlmanacLandscape.leftHeadland,
        ...AlmanacLandscape.rightHeadland,
        ...AlmanacLandscape.rightSpur,
        ...AlmanacLandscape.bank,
        ...AlmanacLandscape.boulder,
        for (final island in AlmanacLandscape.islands) ...island,
      ]) {
        expect(point.dx, inInclusiveRange(0, 1), reason: '$point');
        expect(point.dy, inInclusiveRange(0, 1), reason: '$point');
      }
      for (final (x, y, height, _) in AlmanacLandscape.plantings) {
        expect(x, inInclusiveRange(0, 1));
        expect(y, inInclusiveRange(0, 1));
        expect(height, inInclusiveRange(0, 1));
      }
    });
  });

  group('the scene is the same shape at every size', () {
    test('a point keeps its place in the frame', () {
      // Proportional coordinates, projected by a single uniform multiply:
      // the same mountain is the same mountain on a phone and a tablet,
      // because the band it is painted into keeps its aspect ratio.
      const point = Offset(0.47, 0.30);
      for (final frame in [
        const Size(320, 213),
        const Size(390, 260),
        const Size(640, 427),
      ]) {
        final projected = LandscapeForm.project(point, frame);
        expect(projected.dx / frame.width, closeTo(point.dx, 1e-9));
        expect(projected.dy / frame.height, closeTo(point.dy, 1e-9));
      }
    });

    test('and every feature scales together', () {
      // The boulder rather than a headland, because a headland starts at
      // x = 0 and a ratio against zero proves nothing.
      final small = AlmanacLandscape.form
          .smoothed(AlmanacLandscape.boulder, const Size(320, 213))
          .getBounds();
      final large = AlmanacLandscape.form
          .smoothed(AlmanacLandscape.boulder, const Size(640, 426))
          .getBounds();

      expect(large.left / small.left, closeTo(2, 0.01));
      expect(large.top / small.top, closeTo(2, 0.01));
      expect(large.width / small.width, closeTo(2, 0.01));
      expect(large.height / small.height, closeTo(2, 0.01));
    });
  });
}
