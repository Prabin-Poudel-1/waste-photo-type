import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/report_models.dart';

enum LocationRecovery { retry, appSettings, locationSettings }

class LocationFailure implements Exception {
  final String message;
  final LocationRecovery recovery;
  const LocationFailure(this.message, [this.recovery = LocationRecovery.retry]);
}

abstract interface class LocationService {
  Future<IncidentLocation> locate();
  Future<bool> openSettings(LocationRecovery recovery);
}

class DeviceLocationService implements LocationService {
  @override
  Future<IncidentLocation> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationFailure(
          'Location services are off. Enable them to locate the incident.',
          LocationRecovery.locationSettings,
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationFailure(
          'Location access is blocked. Allow location while using this app in settings.',
          LocationRecovery.appSettings,
        );
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw const LocationFailure(
          'Location permission was denied. We need the incident location before submitting. You can retry.',
        );
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
      final result = IncidentLocation(p.latitude, p.longitude, p.accuracy);
      if (!result.valid) {
        throw const LocationFailure(
          'The device returned invalid coordinates. Please retry.',
        );
      }
      return result;
    } on LocationFailure {
      rethrow;
    } on TimeoutException {
      throw const LocationFailure(
        'Location timed out. Try outdoors or set the emulator location, then retry.',
      );
    } catch (_) {
      throw const LocationFailure(
        'Could not get your location. Check permissions and retry.',
      );
    }
  }

  @override
  Future<bool> openSettings(LocationRecovery recovery) =>
      recovery == LocationRecovery.locationSettings
      ? Geolocator.openLocationSettings()
      : Geolocator.openAppSettings();
}
