import 'dart:typed_data';

export '../../../core/models/waste_photo.dart';

class DetectionBox {
  final double left, top, right, bottom;
  const DetectionBox(this.left, this.top, this.right, this.bottom);
}

class WasteDetection {
  final String categoryCode;
  final String label;
  final double confidence;
  final DetectionBox? box;
  const WasteDetection({
    required this.categoryCode,
    required this.label,
    required this.confidence,
    this.box,
  });
  bool get needsReview => confidence < .6;
  factory WasteDetection.fromJson(Map<String, dynamic> json) {
    final confidence = (json['confidence'] as num).toDouble();
    final label = json['label'] as String;
    final code = json['categoryCode'] as String;
    if (!confidence.isFinite ||
        confidence < 0 ||
        confidence > 1 ||
        label.isEmpty ||
        code.isEmpty) {
      throw const FormatException('Invalid detection');
    }
    return WasteDetection(
      categoryCode: code,
      label: label,
      confidence: confidence,
    );
  }
}

class DetectionResult {
  final String id;
  final bool isMock;
  final String modelVersion;
  final List<WasteDetection> detections;
  final int? imageWidth, imageHeight;
  final Uint8List? previewBytes;
  const DetectionResult({
    required this.id,
    required this.isMock,
    required this.modelVersion,
    required this.detections,
    this.imageWidth,
    this.imageHeight,
    this.previewBytes,
  });
  bool get wasteDetected => detections.isNotEmpty;
  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1 || json['status'] != 'COMPLETED') {
      throw const FormatException('Unsupported result');
    }
    final detections = (json['detections'] as List)
        .map(
          (e) => WasteDetection.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
    if ((json['wasteDetected'] as bool) != detections.isNotEmpty) {
      throw const FormatException('Inconsistent detection');
    }
    return DetectionResult(
      id: json['id'] as String,
      isMock: json['isMock'] as bool,
      modelVersion: json['modelVersion'] as String,
      detections: List.unmodifiable(detections),
    );
  }
}

enum MockScenario {
  multiple('Multiple categories', 'multiple'),
  none('No waste detected', 'none'),
  low('Low confidence', 'low'),
  error('Service unavailable', 'error');

  const MockScenario(this.label, this.code);
  final String label;
  final String code;
}
