import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chitwan_care/core/errors/app_failure.dart';
import 'package:chitwan_care/features/analysis/models/detection_result.dart';
import 'package:chitwan_care/features/analysis/services/http_waste_detection_service.dart';

class StubAdapter implements HttpClientAdapter {
  final int code;
  final Map<String, dynamic> response;
  RequestOptions? received;
  StubAdapter(this.code, this.response);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    received = options;
    return ResponseBody.fromString(
      jsonEncode(response),
      code,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final photo = WastePhoto(
    bytes: Uint8List.fromList([1, 2, 3]),
    name: 'scene.png',
    selectedAt: DateTime(2026),
  );
  test(
    'HTTP adapter sends multipart photo and parses versioned mock contract',
    () async {
      final adapter = StubAdapter(202, {
        'id': 'one',
        'schemaVersion': 1,
        'status': 'COMPLETED',
        'isMock': true,
        'modelVersion': 'mock-v1',
        'wasteDetected': true,
        'detections': [
          {'categoryCode': 'plastic', 'label': 'Plastic', 'confidence': .94},
        ],
      });
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8081'))
        ..httpClientAdapter = adapter;
      final result = await HttpWasteDetectionService(dio)
          .analyze(photo, MockScenario.multiple);
      expect(result.detections.single.confidence, .94);
      expect(adapter.received!.path, '/api/v1/analyses');
      final form = adapter.received!.data as FormData;
      expect(form.files.single.key, 'image');
      expect(form.files.single.value.filename, 'scene.png');
      expect(form.fields.single.value, 'multiple');
      dio.close();
    },
  );
  for (final code in [400, 401, 413, 429, 503]) {
    test('HTTP $code becomes a useful AppFailure', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8081'))
        ..httpClientAdapter = StubAdapter(code, {
          'message': 'raw internal detail',
        });
      try {
        await HttpWasteDetectionService(dio)
            .analyze(photo, MockScenario.multiple);
        fail('Expected failure');
      } on AppFailure catch (e) {
        expect(e.message, isNot(contains('raw internal detail')));
        expect(e.message, isNotEmpty);
      } finally {
        dio.close();
      }
    });
  }
  test('Malformed confidence is rejected', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8081'))
      ..httpClientAdapter = StubAdapter(202, {
        'id': 'one',
        'schemaVersion': 1,
        'status': 'COMPLETED',
        'isMock': true,
        'modelVersion': 'mock-v1',
        'wasteDetected': true,
        'detections': [
          {'categoryCode': 'plastic', 'label': 'Plastic', 'confidence': 7},
        ],
      });
    await expectLater(
      HttpWasteDetectionService(dio).analyze(photo, MockScenario.multiple),
      throwsA(isA<AppFailure>()),
    );
    dio.close();
  });
}
