// Placeholder: paste the contents of mobile/lib/features/reports/models/report_models.dart from your app here.
import '../../../core/errors/app_failure.dart';
import '../../analysis/models/detection_result.dart';

class IncidentLocation {
  final double latitude;
  final double longitude;
  final double accuracyMeters;

  const IncidentLocation(
      this.latitude,
      this.longitude,
      this.accuracyMeters,
      );

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
  final String code;
  final String name;

  const WasteCategory(
      this.id,
      this.code,
      this.name,
      );

  factory WasteCategory.fromJson(
      Map<String, dynamic> json,
      ) {
    return WasteCategory(
      json['id'] as int,
      json['code'] as String,
      json['name'] as String,
    );
  }
}

class TouristSpot {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;

  const TouristSpot(
      this.id,
      this.name,
      this.latitude,
      this.longitude,
      this.radiusMeters,
      );

  factory TouristSpot.fromJson(
      Map<String, dynamic> json,
      ) {
    return TouristSpot(
      json['id'] as int,
      json['name'] as String,
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
      json['radiusMeters'] as int,
    );
  }
}

String normalizeCategory(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
}

WasteCategory mapCategory(
    WasteDetection detection,
    List<WasteCategory> categories,
    ) {
  for (final category in categories) {
    if (normalizeCategory(category.code) ==
        normalizeCategory(
          detection.categoryCode,
        ) ||
        normalizeCategory(category.name) ==
            normalizeCategory(detection.label)) {
      return category;
    }
  }

  for (final category in categories) {
    if (normalizeCategory(category.code) == 'other' ||
        normalizeCategory(category.name) == 'other') {
      return category;
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

  factory SubmittedReport.fromJson(
      Map<String, dynamic> json,
      ) {
    final id = json['id'] as int;
    final status = json['status'] as String;

    if (id <= 0 || status.isEmpty) {
      throw const FormatException('Invalid report');
    }

    return SubmittedReport(
      id,
      status,
      DateTime.parse(
        json['createdAt'] as String,
      ),
      json['touristSpot'] == null
          ? null
          : (json['touristSpot'] as Map)['name']
      as String,
      (json['images'] as List)
          .map(
            (entry) => Map<String, dynamic>.from(
          entry as Map,
        ),
      )
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
    throw const AppFailure(
      'Capture a valid GPS location before submitting.',
    );
  }

  if (detections.isEmpty) {
    throw const AppFailure(
      'A category is required for manual review.',
    );
  }

  return {
    'description': description.trim(),
    'latitude': double.parse(
      location.latitude.toStringAsFixed(6),
    ),
    'longitude': double.parse(
      location.longitude.toStringAsFixed(6),
    ),
    'severity': severity,
    'touristSpotId': touristSpotId,
    'detections': detections
        .map(
          (detection) => {
        'categoryId': mapCategory(
          detection,
          categories,
        ).id,
        'label': detection.label,
        'confidence': double.parse(
          detection.confidence.toStringAsFixed(6),
        ),
      },
    )
        .toList(),
  };
}