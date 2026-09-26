import 'dart:async';

import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/open_meteo_marine_tide_service.dart';
import 'package:almanac/core/environment/tide.dart';
import 'package:almanac/core/environment/tide_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/fake_environment_services.dart';

void main() {
  setUpAll(useTimeZoneDatabase);

  final zone = TestTimeZones.london;
  const location = GeoLocation(latitude: 51.5074, longitude: -0.1278);
  final now = DateTime.utc(2025, 7, 15, 12);

  OpenMeteoMarineTideService serviceReturning(
    String body, {
    int statusCode = 200,
  }) => OpenMeteoMarineTideService(
    client: MockClient((request) async => http.Response(body, statusCode)),
  );

  OpenMeteoMarineTideService serviceThrowing(Object error) =>
      OpenMeteoMarineTideService(
        client: MockClient((request) async => throw error),
      );

  String hourlyBody(List<String> times, List<String> heights) =>
      '{"hourly": {"time": [${times.map((t) => '"$t"').join(',')}], '
      '"sea_level_height_msl": [${heights.join(',')}]}}';

  group('a valid response', () {
    test('parses samples and derives extrema', () async {
      final times = [
        '2025-07-15T09:00',
        '2025-07-15T10:00',
        '2025-07-15T11:00',
        '2025-07-15T12:00',
        '2025-07-15T13:00',
      ];
      final heights = ['0.5', '1.0', '1.4', '1.0', '0.5'];
      final service = serviceReturning(hourlyBody(times, heights));

      final result = await service.fetch(
        location: location,
        timeZone: zone,
        now: now,
      );

      expect(result, isA<TideFetchData>());
      final snapshot = (result as TideFetchData).snapshot;
      expect(snapshot.samples, hasLength(5));
      expect(snapshot.extrema, hasLength(1));
      expect(snapshot.extrema.single.type, TideExtremeType.high);
    });

    test('rounds the requested coordinates to two decimal places', () async {
      Uri? requested;
      final service = OpenMeteoMarineTideService(
        client: MockClient((request) async {
          requested = request.url;
          return http.Response(hourlyBody(['2025-07-15T12:00'], ['1.0']), 200);
        }),
      );

      await service.fetch(
        location: const GeoLocation(latitude: 51.50741, longitude: -0.12789),
        timeZone: zone,
        now: now,
      );

      expect(requested!.queryParameters['latitude'], '51.51');
      expect(requested!.queryParameters['longitude'], '-0.13');
      expect(requested!.queryParameters['hourly'], 'sea_level_height_msl');
    });
  });

  group('what the request contains, and what it never does', () {
    test(
      'only the coordinates, the one variable, and time parameters are sent',
      () async {
        Uri? requested;
        final service = OpenMeteoMarineTideService(
          client: MockClient((request) async {
            requested = request.url;
            return http.Response(
              hourlyBody(['2025-07-15T12:00'], ['1.0']),
              200,
            );
          }),
        );

        await service.fetch(location: location, timeZone: zone, now: now);

        final params = requested!.queryParameters;
        expect(params.keys.toSet(), {
          'latitude',
          'longitude',
          'hourly',
          'timeformat',
          'timezone',
          'past_days',
          'forecast_days',
        });
        expect(requested!.host, 'marine-api.open-meteo.com');
        expect(requested!.path, '/v1/marine');
      },
    );

    test(
      'no identifying field ever appears, however it might be named',
      () async {
        Uri? requested;
        final service = OpenMeteoMarineTideService(
          client: MockClient((request) async {
            requested = request.url;
            return http.Response(
              hourlyBody(['2025-07-15T12:00'], ['1.0']),
              200,
            );
          }),
        );

        await service.fetch(location: location, timeZone: zone, now: now);

        final url = requested!.toString().toLowerCase();
        for (final forbidden in [
          'apikey',
          'api_key',
          'account',
          'user',
          'device',
          'name',
          'cycle',
          'garden',
          'profile',
          'token',
        ]) {
          expect(url, isNot(contains(forbidden)), reason: forbidden);
        }
      },
    );
  });

  group('a location with no marine data', () {
    test(
      'every reading null is a clean "no data" result, not a failure',
      () async {
        final times = [
          '2025-07-15T11:00',
          '2025-07-15T12:00',
          '2025-07-15T13:00',
        ];
        final service = serviceReturning(
          hourlyBody(times, ['null', 'null', 'null']),
        );

        final result = await service.fetch(
          location: location,
          timeZone: zone,
          now: now,
        );

        expect(result, isA<TideFetchNoData>());
      },
    );

    test('too few real samples among the gaps is also "no data"', () async {
      final times = [
        '2025-07-15T11:00',
        '2025-07-15T12:00',
        '2025-07-15T13:00',
      ];
      final service = serviceReturning(
        hourlyBody(times, ['1.0', 'null', 'null']),
      );

      final result = await service.fetch(
        location: location,
        timeZone: zone,
        now: now,
      );

      expect(result, isA<TideFetchNoData>());
    });
  });

  group('malformed or unexpected responses', () {
    test('a missing hourly block fails', () async {
      final service = serviceReturning('{"latitude": 51.5}');

      await expectLater(
        service.fetch(location: location, timeZone: zone, now: now),
        throwsA(isA<TideServiceFailure>()),
      );
    });

    test('an empty hourly series fails', () async {
      final service = serviceReturning(
        '{"hourly": {"time": [], "sea_level_height_msl": []}}',
      );

      await expectLater(
        service.fetch(location: location, timeZone: zone, now: now),
        throwsA(isA<TideServiceFailure>()),
      );
    });

    test('mismatched time and value array lengths fail', () async {
      final body =
          '{"hourly": {"time": ["2025-07-15T11:00", "2025-07-15T12:00"], '
          '"sea_level_height_msl": [1.0]}}';
      final service = serviceReturning(body);

      await expectLater(
        service.fetch(location: location, timeZone: zone, now: now),
        throwsA(isA<TideServiceFailure>()),
      );
    });

    test('a non-200 response fails', () async {
      final service = serviceReturning(
        '{"error": true, "reason": "bad parameter"}',
        statusCode: 400,
      );

      await expectLater(
        service.fetch(location: location, timeZone: zone, now: now),
        throwsA(isA<TideServiceFailure>()),
      );
    });

    test('invalid JSON fails', () async {
      final service = serviceReturning('not json at all');

      await expectLater(
        service.fetch(location: location, timeZone: zone, now: now),
        throwsA(isA<TideServiceFailure>()),
      );
    });

    test('a response that is valid JSON but the wrong shape fails', () async {
      final service = serviceReturning('[1, 2, 3]');

      await expectLater(
        service.fetch(location: location, timeZone: zone, now: now),
        throwsA(isA<TideServiceFailure>()),
      );
    });
  });

  group('transport failure', () {
    test(
      'a timeout is reported as a TideServiceFailure, not left to crash',
      () async {
        final service = serviceThrowing(TimeoutException('no response'));

        await expectLater(
          service.fetch(location: location, timeZone: zone, now: now),
          throwsA(isA<TideServiceFailure>()),
        );
      },
    );

    test('a socket error is reported as a TideServiceFailure', () async {
      final service = serviceThrowing(StateError('connection refused'));

      await expectLater(
        service.fetch(location: location, timeZone: zone, now: now),
        throwsA(isA<TideServiceFailure>()),
      );
    });
  });
}
