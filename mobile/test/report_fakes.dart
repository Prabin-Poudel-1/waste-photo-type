import 'dart:async';

import 'package:chitwan_care/core/errors/app_failure.dart';
import 'package:chitwan_care/features/analysis/models/detection_result.dart';
import 'package:chitwan_care/features/reports/models/report_models.dart';
import 'package:chitwan_care/features/reports/repositories/report_repository.dart';
import 'package:chitwan_care/features/reports/services/location_service.dart';

class FakeReportRepository implements ReportRepository {
  int calls = 0;
  bool fail = false;
  Completer<SubmittedReport>? pending;
  Map<String, dynamic>? metadata;
  @override
  Future<List<WasteCategory>> categories() async => const [
    WasteCategory(42, 'plastic', 'Plastic'),
    WasteCategory(57, 'other', 'Other'),
  ];
  @override
  Future<List<TouristSpot>> spots() async => const [
    TouristSpot(77, 'Development fixture', 0, 0, 100),
  ];
  @override
  Future<TouristSpot?> nearest(IncidentLocation location) async => null;
  @override
  Future<SubmittedReport> submit(
    Map<String, dynamic> value,
    WastePhoto photo,
    void Function(int, int) onProgress,
  ) async {
    calls++;
    metadata = value;
    if (fail) throw const AppFailure('Backend unavailable. Retry.');
    return pending == null
        ? SubmittedReport(1042, 'SUBMITTED', DateTime.utc(2026), null, [])
        : pending!.future;
  }
}

class FakeLocationService implements LocationService {
  LocationFailure? failure;
  @override
  Future<IncidentLocation> locate() async {
    if (failure != null) throw failure!;
    return const IncidentLocation(0.0001234, 0.0002345, 5);
  }

  @override
  Future<bool> openSettings(LocationRecovery recovery) async => true;
}
