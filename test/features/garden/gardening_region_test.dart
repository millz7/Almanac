import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/features/garden/domain/plant_book.dart';
import 'package:flutter_test/flutter_test.dart';

/// A few real places, to keep the bands honest.
const auckland = GeoLocation(latitude: -36.85, longitude: 174.76);
const tauranga = GeoLocation(latitude: -37.69, longitude: 176.17);
const hamilton = GeoLocation(latitude: -37.79, longitude: 175.28);
const napier = GeoLocation(latitude: -39.49, longitude: 176.92);
const wellington = GeoLocation(latitude: -41.29, longitude: 174.78);
const nelson = GeoLocation(latitude: -41.27, longitude: 173.28);
const christchurch = GeoLocation(latitude: -43.53, longitude: 172.64);
const dunedin = GeoLocation(latitude: -45.87, longitude: 170.5);
const invercargill = GeoLocation(latitude: -46.41, longitude: 168.35);

const sydney = GeoLocation(latitude: -33.87, longitude: 151.21);
const london = GeoLocation(latitude: 51.51, longitude: -0.13);
const seattle = GeoLocation(latitude: 47.61, longitude: -122.33);

void main() {
  group('the bands within New Zealand', () {
    test('the warm north', () {
      for (final place in [auckland, tauranga]) {
        expect(
          GardeningRegion.forLocation(place),
          GardeningRegion.nzNorthern,
          reason: '$place',
        );
      }
    });

    test('a latitude band cannot see inland frost', () {
      // Hamilton sits north of the 38 degree line and is put in the
      // warm band, though the Waikato is frostier than the coast at the
      // same latitude. This is the documented limit of what coarse
      // location can honestly support: the band is broad, the screens
      // say so, and the alternative — elevation and shelter — is not
      // something the app has or is going to ask for.
      expect(GardeningRegion.forLocation(hamilton), GardeningRegion.nzNorthern);
    });

    test('the temperate middle, on both islands', () {
      for (final place in [napier, wellington, nelson]) {
        expect(
          GardeningRegion.forLocation(place),
          GardeningRegion.nzCentral,
          reason: '$place',
        );
      }
    });

    test('the cooler south', () {
      for (final place in [christchurch, dunedin, invercargill]) {
        expect(
          GardeningRegion.forLocation(place),
          GardeningRegion.nzSouthern,
          reason: '$place',
        );
      }
    });

    test('the boundaries are where they are documented to be', () {
      expect(
        GardeningRegion.forLocation(
          const GeoLocation(latitude: -37.99, longitude: 175),
        ),
        GardeningRegion.nzNorthern,
      );
      expect(
        GardeningRegion.forLocation(
          const GeoLocation(latitude: -38.01, longitude: 175),
        ),
        GardeningRegion.nzCentral,
      );
      expect(
        GardeningRegion.forLocation(
          const GeoLocation(latitude: -41.99, longitude: 174),
        ),
        GardeningRegion.nzCentral,
      );
      expect(
        GardeningRegion.forLocation(
          const GeoLocation(latitude: -42.01, longitude: 174),
        ),
        GardeningRegion.nzSouthern,
      );
    });
  });

  group('outside New Zealand', () {
    test('the app admits it has no regional model yet', () {
      // Rather than pretending New Zealand's calendar applies, it falls
      // back to the broader guide for that hemisphere.
      expect(
        GardeningRegion.forLocation(sydney),
        GardeningRegion.genericSouthern,
      );
      for (final place in [london, seattle]) {
        expect(
          GardeningRegion.forLocation(place),
          GardeningRegion.genericNorthern,
          reason: '$place',
        );
      }
    });

    test('a hemisphere alone gives the generic guide', () {
      expect(
        GardeningRegion.forHemisphere(Hemisphere.southern),
        GardeningRegion.genericSouthern,
      );
      expect(
        GardeningRegion.forHemisphere(Hemisphere.northern),
        GardeningRegion.genericNorthern,
      );
    });

    test('and says so in its name', () {
      expect(
        GardeningRegion.genericSouthern.label,
        'General Southern Hemisphere guide',
      );
      expect(
        GardeningRegion.genericNorthern.label,
        'General Northern Hemisphere guide',
      );
      expect(GardeningRegion.genericSouthern.isLocationBacked, isFalse);
      expect(GardeningRegion.nzCentral.isLocationBacked, isTrue);
    });
  });

  group('how a window reads in each band', () {
    // Every rule in the plant book is written for the temperate middle.
    const spring = MonthWindow(9, 11);

    test('the temperate middle is the baseline', () {
      expect(spring.shifted(GardeningRegion.nzCentral.monthOffset), spring);
      expect(GardeningRegion.nzCentral.monthOffset, 0);
    });

    test('the warm north runs a month earlier', () {
      expect(
        spring.shifted(GardeningRegion.nzNorthern.monthOffset),
        const MonthWindow(8, 10),
      );
    });

    test('the cooler south runs a month later', () {
      expect(
        spring.shifted(GardeningRegion.nzSouthern.monthOffset),
        const MonthWindow(10, 12),
      );
    });

    test('the northern hemisphere is half a year across', () {
      expect(
        spring.shifted(GardeningRegion.genericNorthern.monthOffset),
        const MonthWindow(3, 5),
      );
      // A southern December is a northern June.
      expect(
        const MonthWindow(
          12,
          1,
        ).shifted(GardeningRegion.genericNorthern.monthOffset),
        const MonthWindow(6, 7),
      );
    });

    test('windows wrap the new year cleanly', () {
      const summer = MonthWindow(11, 2);

      expect(summer.wraps, isTrue);
      expect(summer.length, 4);
      expect(summer.contains(12), isTrue);
      expect(summer.contains(1), isTrue);
      expect(summer.contains(3), isFalse);
      expect(
        summer.shifted(GardeningRegion.nzSouthern.monthOffset),
        const MonthWindow(12, 3),
      );
    });

    test('a window can be a single month', () {
      const june = MonthWindow.only(6);
      expect(june.length, 1);
      expect(june.contains(6), isTrue);
      expect(june.contains(7), isFalse);
    });
  });
}
