// Placeholder: paste the contents of mobile/lib/features/reports/controllers/report_controller.dart from your app here.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../analysis/models/detection_result.dart';
import '../../auth/auth_controller.dart';
import '../models/report_models.dart';
import '../repositories/report_repository.dart';
import '../services/location_service.dart';

final reportRepositoryProvider =
Provider<ReportRepository>((ref) {
  return HttpReportRepository(
    ref.watch(authenticatedDioProvider),
  );
});

final locationServiceProvider =
Provider<LocationService>(
      (ref) => DeviceLocationService(),
);

class ReportController extends ChangeNotifier {
  final ReportRepository repository;
  final LocationService locations;

  ReportController(
      this.repository,
      this.locations,
      );

  List<WasteCategory> categories = [];
  List<TouristSpot> spots = [];

  IncidentLocation? location;
  TouristSpot? selectedSpot;

  bool loading = false;
  bool locating = false;
  bool matching = false;
  bool submitting = false;
  bool catalogReady = false;
  bool matchReady = false;
  bool manualSpot = false;

  String? catalogError;
  String? matchError;
  String? submitError;

  LocationFailure? locationError;
  SubmittedReport? submitted;
  double? progress;

  bool _disposed = false;

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadCatalog() async {
    if (loading || submitting) {
      return;
    }

    loading = true;
    catalogReady = false;
    catalogError = null;
    _notify();

    try {
      categories = await repository.categories();
      spots = await repository.spots();

      if (categories.isEmpty) {
        throw const AppFailure(
          'No active waste categories are available. Please contact the project team.',
        );
      }

      if (selectedSpot != null &&
          !spots.any(
                (spot) =>
            spot.id == selectedSpot!.id,
          )) {
        selectedSpot = null;
      }

      catalogReady = true;
    } on AppFailure catch (error) {
      catalogError = error.message;
    } catch (_) {
      catalogError =
      'Could not load report options. Please retry.';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> locate() async {
    if (locating || submitting || matching) {
      return;
    }

    locating = true;
    location = null;
    selectedSpot = null;
    manualSpot = false;
    matchReady = false;
    locationError = null;
    matchError = null;
    _notify();

    try {
      final value = await locations.locate();

      if (!value.valid) {
        throw const LocationFailure(
          'Invalid GPS coordinates. Retry location.',
        );
      }

      if (_disposed) {
        return;
      }

      location = value;
    } on LocationFailure catch (error) {
      locationError = error;
    } catch (_) {
      locationError = const LocationFailure(
        'Location unavailable. Please retry.',
      );
    } finally {
      locating = false;
      _notify();
    }

    if (!_disposed && location != null) {
      await match();
    }
  }

  Future<void> match() async {
    if (location == null ||
        matching ||
        submitting) {
      return;
    }

    matching = true;
    manualSpot = false;
    matchError = null;
    matchReady = false;
    _notify();

    try {
      selectedSpot = await repository.nearest(
        location!,
      );

      if (selectedSpot != null &&
          !spots.any(
                (spot) =>
            spot.id == selectedSpot!.id,
          )) {
        spots = [
          ...spots,
          selectedSpot!,
        ];
      }

      matchReady = true;
    } on AppFailure catch (error) {
      matchError = error.message;
    } catch (_) {
      matchError =
      'Could not match a tourist spot. Retry or select one manually.';
    } finally {
      matching = false;
      _notify();
    }
  }

  void selectSpot(int? id) {
    if (submitting || matching) {
      return;
    }

    selectedSpot = id == null
        ? null
        : spots.firstWhere(
          (spot) => spot.id == id,
    );

    manualSpot = true;
    matchReady = true;
    matchError = null;
    _notify();
  }

  bool get canSubmit =>
      catalogReady &&
          location != null &&
          matchReady &&
          !loading &&
          !locating &&
          !matching &&
          !submitting &&
          submitted == null;

  Future<void> submit(
      WastePhoto photo,
      List<WasteDetection> detections,
      String description,
      String severity,
      ) async {
    if (!canSubmit) {
      return;
    }

    submitting = true;
    submitError = null;
    progress = null;
    _notify();

    try {
      final metadata = reportMetadata(
        location: location!,
        detections: detections,
        categories: categories,
        description: description,
        severity: severity,
        touristSpotId: selectedSpot?.id,
      );

      submitted = await repository.submit(
        metadata,
        photo,
            (sent, total) {
          progress = total > 0
              ? sent / total
              : null;
          _notify();
        },
      );
    } on AppFailure catch (error) {
      submitError = error.message;
    } catch (_) {
      submitError =
      'Could not complete submission. Your photo has been kept for retry.';
    } finally {
      submitting = false;
      _notify();
    }
  }
}