import 'dart:async';

import 'package:chitwan_care/features/reports/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

class TestGeolocator extends GeolocatorPlatform {
  bool enabled = true;

  LocationPermission permission =
      LocationPermission.whileInUse;

  LocationPermission requested =
      LocationPermission.whileInUse;

  int requests = 0;
  Object? failure;

  @override
  Future<bool>
  isLocationServiceEnabled() async {
    return enabled;
  }

  @override
  Future<LocationPermission>
  checkPermission() async {
    return permission;
  }

  @override
  Future<LocationPermission>
  requestPermission() async {
    requests++;
    return requested;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    if (failure != null) {
      throw failure!;
    }

    return Position(
      longitude: 84.43,
      latitude: 27.68,
      timestamp: DateTime(2026),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  late GeolocatorPlatform previous;
  late TestGeolocator platform;

  setUp(() {
    previous = GeolocatorPlatform.instance;
    platform = TestGeolocator();
    GeolocatorPlatform.instance = platform;
  });

  tearDown(() {
    GeolocatorPlatform.instance = previous;
  });

  test(
    'Granted GPS returns actual platform coordinates',
        () async {
      final point =
      await DeviceLocationService()
          .locate();

      expect(point.latitude, 27.68);
      expect(point.longitude, 84.43);
      expect(platform.requests, 0);
    },
  );

  test(
    'Services disabled provides location settings recovery',
        () async {
      platform.enabled = false;

      expect(
            () =>
            DeviceLocationService().locate(),
        throwsA(
          isA<LocationFailure>().having(
                (error) => error.recovery,
            'recovery',
            LocationRecovery
                .locationSettings,
          ),
        ),
      );
    },
  );

  test(
    'Denied permission requests permission and allows retry on denial',
        () async {
      platform.permission =
          LocationPermission.denied;

      platform.requested =
          LocationPermission.denied;

      await expectLater(
            () =>
            DeviceLocationService().locate(),
        throwsA(
          isA<LocationFailure>().having(
                (error) => error.recovery,
            'recovery',
            LocationRecovery.retry,
          ),
        ),
      );

      expect(platform.requests, 1);
    },
  );

  test(
    'Permanently denied permission opens app settings without requesting again',
        () async {
      platform.permission =
          LocationPermission.deniedForever;

      await expectLater(
            () =>
            DeviceLocationService().locate(),
        throwsA(
          isA<LocationFailure>().having(
                (error) => error.recovery,
            'recovery',
            LocationRecovery.appSettings,
          ),
        ),
      );

      expect(platform.requests, 0);
    },
  );

  test(
    'Timeout and device errors never invent coordinates',
        () async {
      platform.failure =
          TimeoutException('test');

      await expectLater(
            () =>
            DeviceLocationService().locate(),
        throwsA(
          isA<LocationFailure>().having(
                (error) => error.message,
            'message',
            contains('timed out'),
          ),
        ),
      );

      platform.failure =
          Exception('device failure');

      await expectLater(
            () =>
            DeviceLocationService().locate(),
        throwsA(
          isA<LocationFailure>(),
        ),
      );
    },
  );
}// Placeholder: paste the contents of mobile/test/location_service_test.dart from your app here.
