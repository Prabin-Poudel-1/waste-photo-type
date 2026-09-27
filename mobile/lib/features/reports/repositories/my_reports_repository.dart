import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../auth/auth_controller.dart';

class TrackedReport {
  final int id;
  final String status, severity;
  final String? description, touristSpot;
  final double latitude, longitude;
  final DateTime createdAt;
  final List<Map<String, dynamic>> detections, history, images;
  TrackedReport(Map<String, dynamic> j)
    : id = j['id'] as int,
      status = j['status'] as String,
      severity = j['severity'] as String,
      description = j['description'] as String?,
      touristSpot = (j['touristSpot'] as Map?)?['name'] as String?,
      latitude = (j['latitude'] as num).toDouble(),
      longitude = (j['longitude'] as num).toDouble(),
      createdAt = DateTime.parse(j['createdAt'] as String),
      detections = (j['detections'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      history = (j['statusHistory'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      images = (j['images'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
}

class MyReportsPage {
  final List<TrackedReport> reports;
  final int totalPages;
  const MyReportsPage(this.reports, this.totalPages);
}

final myReportsRepositoryProvider = Provider(
  (ref) => MyReportsRepository(ref.watch(authenticatedDioProvider)),
);

class MyReportsRepository {
  final Dio dio;
  MyReportsRepository(this.dio);
  Future<T> _request<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw AppFailure(switch (e.response?.statusCode) {
        401 => 'Please log in again.',
        403 || 404 => 'This report is not available to your account.',
        _ => 'Could not load your reports. Check your connection and retry.',
      });
    } catch (_) {
      throw const AppFailure(
        'The report response could not be read. Please retry.',
      );
    }
  }

  Future<MyReportsPage> mine(int page, {bool authority = false}) =>
      _request(() async {
        final r = await dio.get(
          authority ? '/api/v1/authority/reports' : '/api/v1/reports/mine',
          queryParameters: {'page': page, 'size': 20},
        );
        final j = Map<String, dynamic>.from(r.data as Map);
        return MyReportsPage(
          (j['content'] as List)
              .map((e) => TrackedReport(Map<String, dynamic>.from(e as Map)))
              .toList(),
          j['totalPages'] as int,
        );
      });
  Future<TrackedReport> detail(int id) => _request(
    () async => TrackedReport(
      Map<String, dynamic>.from(
        (await dio.get('/api/v1/reports/$id')).data as Map,
      ),
    ),
  );
  Future<Uint8List> image(int reportId, int imageId) => _request(() async {
    final r = await dio.get<List<int>>(
      '/api/v1/reports/$reportId/images/$imageId',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(r.data!);
  });
}
