import 'package:almanac/core/environment/daypart.dart';
import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Daypart at(int hour, [int minute = 0]) =>
      daypartAt(LocalTimeZone.utc.instantAtLocal(2026, 1, 1, hour, minute));

  group('boundaries', () {
    test('04:59 is still night', () => expect(at(4, 59), Daypart.night));
    test('05:00 becomes morning', () => expect(at(5), Daypart.morning));
    test('11:59 is still morning', () => expect(at(11, 59), Daypart.morning));
    test('12:00 becomes afternoon', () => expect(at(12), Daypart.afternoon));
    test(
      '16:59 is still afternoon',
      () => expect(at(16, 59), Daypart.afternoon),
    );
    test('17:00 becomes evening', () => expect(at(17), Daypart.evening));
    test('20:59 is still evening', () => expect(at(20, 59), Daypart.evening));
    test('21:00 becomes night', () => expect(at(21), Daypart.night));
    test('midnight is night', () => expect(at(0), Daypart.night));
  });

  group('next', () {
    test('morning leads to afternoon', () {
      expect(Daypart.morning.next, Daypart.afternoon);
    });
    test('afternoon leads to evening', () {
      expect(Daypart.afternoon.next, Daypart.evening);
    });
    test('evening leads to night', () {
      expect(Daypart.evening.next, Daypart.night);
    });
    test('night leads back to morning', () {
      expect(Daypart.night.next, Daypart.morning);
    });
  });
}
