// Writes one synthetic report. Run ONLY against a dedicated test backend/database.
// dart run tool/verify_report_api.dart http://127.0.0.1:18081
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:chitwan_care/features/analysis/models/detection_result.dart';
import 'package:chitwan_care/features/reports/models/report_models.dart';
import 'package:chitwan_care/features/reports/repositories/report_repository.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    throw ArgumentError(
      'Provide the dedicated test backend URL (this writes a synthetic report).',
    );
  }
  final dio = Dio(
    BaseOptions(
      baseUrl: args.single,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  try {
    final repository = HttpReportRepository(dio);
    final categories = await repository.categories();
    final spots = await repository.spots();
    const location = IncidentLocation(0.000123, 0.000234, 5);
    final spot = await repository.nearest(location);
    if (spot == null || !spots.any((s) => s.id == spot.id)) {
      throw StateError(
        'Seed a clearly labelled test spot at 0,0 with radius 100 m in the test database first.',
      );
    }
    final photo = WastePhoto(
      bytes: File('test/fixtures/synthetic-scene.png').readAsBytesSync(),
      name: 'synthetic-scene.png',
      selectedAt: DateTime.now(),
    );
    final metadata = reportMetadata(
      location: location,
      detections: const [
        WasteDetection(
          categoryCode: 'plastic',
          label: 'Plastic',
          confidence: .94,
        ),
        WasteDetection(
          categoryCode: 'organic',
          label: 'Organic',
          confidence: .82,
        ),
      ],
      categories: categories,
      description: 'Synthetic Phase 3 Dart HTTP verification',
      severity: 'MEDIUM',
      touristSpotId: spot.id,
    );
    final created = await repository.submit(metadata, photo, (_, _) {});
    if (created.status != 'SUBMITTED' || created.images.length != 1) {
      throw StateError('Incomplete report');
    }
    final detail = (await dio.get('/api/v1/reports/${created.id}')).data as Map;
    if ((detail['detections'] as List).length != 2 ||
        (detail['statusHistory'] as List).length != 1 ||
        detail['latitude'] != .000123 ||
        detail['longitude'] != .000234 ||
        (detail['touristSpot'] as Map)['id'] != spot.id) {
      throw StateError('Stored metadata differs from submitted metadata');
    }
    final image = await dio.get<List<int>>(
      created.images.single['url'] as String,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = image.data!;
    if (bytes.length != photo.bytes.length) {
      throw StateError('Image length differs');
    }
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] != photo.bytes[i]) throw StateError('Image differs');
    }
    stdout.writeln(
      'PASS: real multipart HTTP → report #${created.id}, SUBMITTED, two detections, GPS, spot, original image and byte-identical retrieval.',
    );
  } finally {
    dio.close();
  }
}
