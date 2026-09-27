import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../auth/auth_controller.dart';

class TrackedReport {
  final int id;
  final String status;
  final String severity;
  final String? description;
  final String? touristSpot;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final List<Map<String, dynamic>> detections;
  final List<Map<String, dynamic>> history;
  final List<Map<String, dynamic>> images;

  TrackedReport(Map<String, dynamic> json)
      : id = json['id'] as int,
        status = json['status'] as String,
        severity = json['severity'] as String,
        description = json['description'] as String?,
        touristSpot =
        (json['touristSpot'] as Map?)?['name']
        as String?,
        latitude =
        (json['latitude'] as num).toDouble(),
        longitude =
        (json['longitude'] as num).toDouble(),
        createdAt = DateTime.parse(
          json['createdAt'] as String,
        ),
        detections = (json['detections'] as List)
            .map(
              (entry) =>
          Map<String, dynamic>.from(
            entry as Map,
          ),
        )
            .toList(),
        history = (json['statusHistory'] as List)
            .map(
              (entry) =>
          Map<String, dynamic>.from(
            entry as Map,
          ),
        )
            .toList(),
        images = (json['images'] as List)
            .map(
              (entry) =>
          Map<String, dynamic>.from(
            entry as Map,
          ),
        )
            .toList();
}

class MyReportsPage {
  final List<TrackedReport> reports;
  final int totalPages;

  const MyReportsPage(
      this.reports,
      this.totalPages,
      );
}

final myReportsRepositoryProvider = Provider(
      (ref) => MyReportsRepository(
    ref.watch(authenticatedDioProvider),
  ),
);

class MyReportsRepository {
  final Dio dio;

  MyReportsRepository(this.dio);

  Future<T> _request<T>(
      Future<T> Function() action,
      ) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw AppFailure(
        switch (error.response?.statusCode) {
          401 => 'Please log in again.',
          403 || 404 =>
          'This report is not available to your account.',
          _ =>
          'Could not load your reports. Check your connection and retry.',
        },
      );
    } catch (_) {
      throw const AppFailure(
        'The report response could not be read. Please retry.',
      );
    }
  }

  Future<MyReportsPage> mine(
      int page, {
        bool authority = false,
      }) {
    return _request(() async {
      final response = await dio.get(
        authority
            ? '/api/v1/authority/reports'
            : '/api/v1/reports/mine',
        queryParameters: {
          'page': page,
          'size': 20,
        },
      );

      final json = Map<String, dynamic>.from(
        response.data as Map,
      );

      return MyReportsPage(
        (json['content'] as List)
            .map(
              (entry) => TrackedReport(
            Map<String, dynamic>.from(
              entry as Map,
            ),
          ),
        )
            .toList(),
        json['totalPages'] as int,
      );
    });
  }

  Future<TrackedReport> detail(int id) {
    return _request(
          () async => TrackedReport(
        Map<String, dynamic>.from(
          (await dio.get('/api/v1/reports/$id'))
              .data as Map,
        ),
      ),
    );
  }

  Future<Uint8List> image(
      int reportId,
      int imageId,
      ) {
    return _request(() async {
      final response = await dio.get<List<int>>(
        '/api/v1/reports/$reportId/images/$imageId',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      return Uint8List.fromList(response.data!);
    });
  }
}// Placeholder: paste the contents of mobile/lib/features/reports/repositories/my_reports_repository.dart from your app here.
