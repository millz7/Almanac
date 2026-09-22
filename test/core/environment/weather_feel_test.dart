import 'package:almanac/core/environment/weather_feel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('temperatureFeelOf', () {
    test('below coldBelow is cold', () {
      expect(
        temperatureFeelOf(WeatherThresholds.coldBelow - 0.1),
        TemperatureFeel.cold,
      );
    });

    test('coldBelow itself is already cool', () {
      expect(
        temperatureFeelOf(WeatherThresholds.coldBelow),
        TemperatureFeel.cool,
      );
    });

    test('just under coolBelow is cool', () {
      expect(
        temperatureFeelOf(WeatherThresholds.coolBelow - 0.1),
        TemperatureFeel.cool,
      );
    });

    test('coolBelow itself is already mild', () {
      expect(
        temperatureFeelOf(WeatherThresholds.coolBelow),
        TemperatureFeel.mild,
      );
    });

    test('just under mildBelow is mild', () {
      expect(
        temperatureFeelOf(WeatherThresholds.mildBelow - 0.1),
        TemperatureFeel.mild,
      );
    });

    test('mildBelow itself is already warm', () {
      expect(
        temperatureFeelOf(WeatherThresholds.mildBelow),
        TemperatureFeel.warm,
      );
    });

    test('just under warmBelow is warm', () {
      expect(
        temperatureFeelOf(WeatherThresholds.warmBelow - 0.1),
        TemperatureFeel.warm,
      );
    });

    test('warmBelow itself is already hot', () {
      expect(
        temperatureFeelOf(WeatherThresholds.warmBelow),
        TemperatureFeel.hot,
      );
    });

    test('a very hot reading is hot', () {
      expect(temperatureFeelOf(35), TemperatureFeel.hot);
    });
  });

  group('windFeelOf', () {
    test('below breezyFrom is calm', () {
      expect(windFeelOf(WeatherThresholds.breezyFrom - 0.1), WindFeel.calm);
    });

    test('breezyFrom itself is breezy', () {
      expect(windFeelOf(WeatherThresholds.breezyFrom), WindFeel.breezy);
    });

    test('just under windyFrom is breezy', () {
      expect(windFeelOf(WeatherThresholds.windyFrom - 0.1), WindFeel.breezy);
    });

    test('windyFrom itself is windy', () {
      expect(windFeelOf(WeatherThresholds.windyFrom), WindFeel.windy);
    });

    test('a gale-force reading is windy', () {
      expect(windFeelOf(90), WindFeel.windy);
    });

    test('dead calm is calm', () {
      expect(windFeelOf(0), WindFeel.calm);
    });
  });
}
