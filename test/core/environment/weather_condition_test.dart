import 'package:almanac/core/environment/weather_condition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fromWmoCode', () {
    final cases = <int, WeatherCondition>{
      0: WeatherCondition.clear,
      1: WeatherCondition.mostlyClear,
      2: WeatherCondition.partlyCloudy,
      3: WeatherCondition.cloudy,
      45: WeatherCondition.fog,
      48: WeatherCondition.fog,
      51: WeatherCondition.drizzle,
      53: WeatherCondition.drizzle,
      55: WeatherCondition.drizzle,
      56: WeatherCondition.drizzle,
      57: WeatherCondition.drizzle,
      61: WeatherCondition.rain,
      63: WeatherCondition.rain,
      65: WeatherCondition.rain,
      66: WeatherCondition.mixedPrecipitation,
      67: WeatherCondition.mixedPrecipitation,
      71: WeatherCondition.snow,
      73: WeatherCondition.snow,
      75: WeatherCondition.snow,
      77: WeatherCondition.snow,
      80: WeatherCondition.showers,
      81: WeatherCondition.showers,
      82: WeatherCondition.showers,
      85: WeatherCondition.snow,
      86: WeatherCondition.snow,
      95: WeatherCondition.thunderstorm,
      96: WeatherCondition.thunderstorm,
      99: WeatherCondition.thunderstorm,
    };

    cases.forEach((code, expected) {
      test('WMO $code maps to ${expected.name}', () {
        expect(WeatherCondition.fromWmoCode(code), expected);
      });
    });

    test('an unrecognised code falls back to cloudy', () {
      expect(WeatherCondition.fromWmoCode(404), WeatherCondition.cloudy);
      expect(WeatherCondition.fromWmoCode(-1), WeatherCondition.cloudy);
    });
  });

  group('isPrecipitating', () {
    test('every form of precipitation is precipitating', () {
      for (final condition in [
        WeatherCondition.drizzle,
        WeatherCondition.rain,
        WeatherCondition.showers,
        WeatherCondition.thunderstorm,
        WeatherCondition.snow,
        WeatherCondition.mixedPrecipitation,
      ]) {
        expect(condition.isPrecipitating, isTrue, reason: condition.name);
      }
    });

    test('dry conditions are not precipitating', () {
      for (final condition in [
        WeatherCondition.clear,
        WeatherCondition.mostlyClear,
        WeatherCondition.partlyCloudy,
        WeatherCondition.cloudy,
        WeatherCondition.fog,
      ]) {
        expect(condition.isPrecipitating, isFalse, reason: condition.name);
      }
    });
  });

  group('isOpenSky', () {
    test('clear and mostly clear are open', () {
      expect(WeatherCondition.clear.isOpenSky, isTrue);
      expect(WeatherCondition.mostlyClear.isOpenSky, isTrue);
    });

    test('everything else is not open', () {
      for (final condition in WeatherCondition.values) {
        if (condition == WeatherCondition.clear ||
            condition == WeatherCondition.mostlyClear) {
          continue;
        }
        expect(condition.isOpenSky, isFalse, reason: condition.name);
      }
    });
  });
}
