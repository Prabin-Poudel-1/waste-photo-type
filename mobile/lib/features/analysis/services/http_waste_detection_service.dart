import 'package:dio/dio.dart';

import '../../../core/errors/app_failure.dart';
import '../models/detection_result.dart';
import 'waste_detection_service.dart';

class HttpWasteDetectionService implements WasteDetectionService {
  final Dio client;

  HttpWasteDetectionService(this.client);

  @override
  Future<DetectionResult> analyze(
      WastePhoto photo,
      MockScenario scenario,
      ) async {
    try {
      final response = await client.post<Map<String, dynamic>>(
        '/api/v1/analyses',
        data: FormData.fromMap({
          'image': MultipartFile.fromBytes(
            photo.bytes,
            filename: photo.name,
          ),
          'scenario': scenario.code,
        }),
      );

      var data = response.data;

      // The same contract supports a future asynchronous inference worker.
      for (
      var attempt = 0;
      data != null &&
          data['status'] != 'COMPLETED' &&
          attempt < 20;
      attempt++
      ) {
        if (data['status'] == 'FAILED') {
          throw const AppFailure(
            'Analysis failed. Your photo is safe to retry.',
          );
        }

        final id = data['id'] as String;

        await Future<void>.delayed(
          const Duration(seconds: 1),
        );

        data = (await client.get<Map<String, dynamic>>(
          '/api/v1/analyses/${Uri.encodeComponent(id)}',
        ))
            .data;
      }

      if (data == null || data['status'] != 'COMPLETED') {
        throw const AppFailure(
          'Analysis is taking too long. Please try again shortly.',
        );
      }

      return DetectionResult.fromJson(data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const AppFailure(
          'The connection timed out. Check your network and try again.',
        );
      }

      if (e.response?.statusCode == 413) {
        throw const AppFailure(
          'This photo is too large. Choose one under 10 MB.',
        );
      }

      if (e.response?.statusCode == 401 ||
          e.response?.statusCode == 403) {
        throw const AppFailure(
          'Access was denied by the server. Check the development server configuration.',
        );
      }

      if (e.response?.statusCode == 429) {
        throw const AppFailure(
          'Too many requests. Please wait and try again.',
        );
      }

      if (e.response?.statusCode == 503) {
        throw const AppFailure(
          'The analysis service is unavailable. Your photo is still here; try again later.',
        );
      }

      if (e.response?.statusCode == 400) {
        throw const AppFailure(
          'The server could not read this photo. Try another JPEG or PNG image.',
        );
      }

      throw const AppFailure(
        'Cannot reach the analysis server. Check your network, server and API_BASE_URL.',
      );
    } on FormatException {
      throw const AppFailure(
        'The analysis service returned an unsupported result. Please try again.',
      );
    } on TypeError {
      throw const AppFailure(
        'The analysis response was incomplete. Please try again.',
      );
    }
  }
}// Placeholder: paste the contents of mobile/lib/features/analysis/services/http_waste_detection_service.dart from your app here.
