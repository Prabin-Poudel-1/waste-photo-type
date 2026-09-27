import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_failure.dart';
import '../../analysis/models/detection_result.dart';
import '../models/report_models.dart';

abstract interface class ReportRepository {
  Future<List<WasteCategory>> categories();
  Future<List<TouristSpot>> spots();
  Future<TouristSpot?> nearest(IncidentLocation location);
  Future<SubmittedReport> submit(
    Map<String, dynamic> metadata,
    WastePhoto photo,
    void Function(int, int) onProgress,
  );
}

class HttpReportRepository implements ReportRepository {
  final Dio dio;
  HttpReportRepository(this.dio);

  Future<T> _request<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppFailure {
      rethrow;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 413) {
        throw const AppFailure(
          'The photo is too large. Choose a photo under 10 MB.',
        );
      }
      if (status != null && status >= 400 && status < 500) {
        throw const AppFailure(
          'The server could not accept this report. Check the photo, categories and tourist spot, then retry.',
        );
      }
      if (status != null && status >= 500) {
        throw const AppFailure(
          'The server could not complete the request. Your photo is still here; please retry.',
        );
      }
      throw const AppFailure(
        'Cannot reach the server or the request timed out. Check your connection and backend. If submission had started, it may have reached the server; retrying could create another report.',
      );
    } catch (_) {
      throw const AppFailure(
        'The server returned an unexpected response. If you were submitting, the report may have been saved. Check the backend before retrying.',
      );
    }
  }

  @override
  Future<List<WasteCategory>> categories() => _request(() async {
    final r = await dio.get('/api/v1/waste-categories');
    return (r.data as List)
        .map((e) => WasteCategory.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  });
  @override
  Future<List<TouristSpot>> spots() => _request(() async {
    final r = await dio.get('/api/v1/tourist-spots');
    return (r.data as List)
        .map((e) => TouristSpot.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  });
  @override
  Future<TouristSpot?> nearest(IncidentLocation location) => _request(() async {
    final r = await dio.get(
      '/api/v1/tourist-spots/nearest',
      queryParameters: {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
    );
    return r.statusCode == 204
        ? null
        : TouristSpot.fromJson(Map<String, dynamic>.from(r.data as Map));
  });

  static FormData multipart(Map<String, dynamic> metadata, WastePhoto photo) {
    final b = photo.bytes;
    if (b.isEmpty || b.length > AppConfig.maxImageBytes) {
      throw const AppFailure('Choose a non-empty photo under 10 MB.');
    }
    final png =
        b.length >= 8 && b[0] == 137 && b[1] == 80 && b[2] == 78 && b[3] == 71;
    final jpeg = b.length >= 3 && b[0] == 255 && b[1] == 216 && b[2] == 255;
    if (!png && !jpeg) {
      throw const AppFailure('Please select a JPEG or PNG photo for upload.');
    }
    return FormData.fromMap({
      'metadata': MultipartFile.fromString(
        jsonEncode(metadata),
        contentType: DioMediaType('application', 'json'),
      ),
      'image': MultipartFile.fromBytes(
        b,
        filename: photo.name,
        contentType: DioMediaType('image', png ? 'png' : 'jpeg'),
      ),
    });
  }

  @override
  Future<SubmittedReport> submit(
    Map<String, dynamic> metadata,
    WastePhoto photo,
    void Function(int, int) onProgress,
  ) => _request(() async {
    final r = await dio.post(
      '/api/v1/reports',
      data: multipart(metadata, photo),
      onSendProgress: onProgress,
    );
    if (r.statusCode != 201) {
      throw const FormatException('Expected created report');
    }
    return SubmittedReport.fromJson(Map<String, dynamic>.from(r.data as Map));
  });
}
