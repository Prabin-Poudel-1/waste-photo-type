import '../../analysis/models/detection_result.dart';
import '../../../core/errors/app_failure.dart';

class IncidentLocation {
  final double latitude, longitude, accuracyMeters;
  const IncidentLocation(this.latitude, this.longitude, this.accuracyMeters);
  bool get valid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

class WasteCategory {
  final int id;
  final String code, name;
  const WasteCategory(this.id, this.code, this.name);
  factory WasteCategory.fromJson(Map<String, dynamic> j) =>
      WasteCategory(j['id'] as int, j['code'] as String, j['name'] as String);
}

class TouristSpot {
  final int id;
  final String name;
  final double latitude, longitude;
  final int radiusMeters;
  const TouristSpot(
    this.id,
    this.name,
    this.latitude,
    this.longitude,
    this.radiusMeters,
  );
  factory TouristSpot.fromJson(Map<String, dynamic> j) => TouristSpot(
    j['id'] as int,
    j['name'] as String,
    (j['latitude'] as num).toDouble(),
    (j['longitude'] as num).toDouble(),
    j['radiusMeters'] as int,
  );
}

String normalizeCategory(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

WasteCategory mapCategory(
  WasteDetection detection,
  List<WasteCategory> categories,
) {
  for (final c in categories) {
    if (normalizeCategory(c.code) ==
            normalizeCategory(detection.categoryCode) ||
        normalizeCategory(c.name) == normalizeCategory(detection.label)) {
      return c;
    }
  }
  for (final c in categories) {
    if (normalizeCategory(c.code) == 'other' ||
        normalizeCategory(c.name) == 'other') {
      return c;
    }
  }
  throw const AppFailure(
    'A detection has no matching category. Refresh the categories or contact the project team.',
  );
}

class SubmittedReport {
  final int id;
  final String status;
  final DateTime createdAt;
  final String? touristSpotName;
  final List<Map<String, dynamic>> images;
  const SubmittedReport(
    this.id,
    this.status,
    this.createdAt,
    this.touristSpotName,
    this.images,
  );
  factory SubmittedReport.fromJson(Map<String, dynamic> j) {
    final id = j['id'] as int;
    final status = j['status'] as String;
    if (id <= 0 || status.isEmpty) {
      throw const FormatException('Invalid report');
    }
    return SubmittedReport(
      id,
      status,
      DateTime.parse(j['createdAt'] as String),
      j['touristSpot'] == null
          ? null
          : (j['touristSpot'] as Map)['name'] as String,
      (j['images'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}

Map<String, dynamic> reportMetadata({
  required IncidentLocation location,
  required List<WasteDetection> detections,
  required List<WasteCategory> categories,
  required String description,
  required String severity,
  int? touristSpotId,
}) {
  if (!location.valid) {
    throw const AppFailure('Capture a valid GPS location before submitting.');
  }
  if (detections.isEmpty) {
    throw const AppFailure('A category is required for manual review.');
  }
  return {
    'description': description.trim(),
    'latitude': double.parse(location.latitude.toStringAsFixed(6)),
    'longitude': double.parse(location.longitude.toStringAsFixed(6)),
    'severity': severity,
    'touristSpotId': touristSpotId,
    'detections': detections
        .map(
          (d) => {
            'categoryId': mapCategory(d, categories).id,
            'label': d.label,
            'confidence': double.parse(d.confidence.toStringAsFixed(6)),
          },
        )
        .toList(),
  };
}
