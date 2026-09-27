import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../analysis/models/detection_result.dart';
import '../auth/auth_controller.dart';

final authorityRepositoryProvider = Provider(
      (ref) => AuthorityRepository(
    ref.watch(authenticatedDioProvider),
  ),
);

class AuthorityRepository {
  final Dio dio;

  AuthorityRepository(this.dio);

  Future<List<Map<String, dynamic>>>
  departments() async {
    try {
      final response = await dio.get(
        '/api/v1/departments',
      );

      return (response.data as List)
          .map(
            (entry) =>
        Map<String, dynamic>.from(
          entry as Map,
        ),
      )
          .toList();
    } catch (_) {
      throw const AppFailure(
        'Could not load departments. Retry.',
      );
    }
  }

  Future<void> update(
      int id,
      String status,
      String note,
      WastePhoto? photo, {
        int? departmentId,
      }) async {
    try {
      if (status == 'ASSIGNED') {
        if (departmentId == null) {
          throw const AppFailure(
            'Select a department.',
          );
        }

        await dio.post(
          '/api/v1/authority/reports/$id/assign',
          data: {
            'departmentId': departmentId,
            'note': note,
          },
        );
      } else if (status == 'RESOLVED') {
        if (photo == null) {
          throw const AppFailure(
            'Select a cleanup photo.',
          );
        }

        final bytes = photo.bytes;

        final png =
            bytes.length >= 4 &&
                bytes[0] == 137 &&
                bytes[1] == 80 &&
                bytes[2] == 78 &&
                bytes[3] == 71;

        await dio.post(
          '/api/v1/authority/reports/$id/resolve',
          data: FormData.fromMap({
            'metadata':
            MultipartFile.fromString(
              jsonEncode({
                'note': note,
              }),
              contentType: DioMediaType(
                'application',
                'json',
              ),
            ),
            'image': MultipartFile.fromBytes(
              bytes,
              filename: photo.name,
              contentType: DioMediaType(
                'image',
                png ? 'png' : 'jpeg',
              ),
            ),
          }),
        );
      } else {
        await dio.patch(
          '/api/v1/authority/reports/$id/status',
          data: {
            'status': status,
            'note': note,
          },
        );
      }
    } on DioException catch (error) {
      throw AppFailure(
        switch (error.response?.statusCode) {
          401 || 403 =>
          'Authority access required. Please log in again.',
          409 =>
          'Report status changed or this transition is not allowed. Refresh before retrying.',
          400 || 413 =>
          'Check the note and photo. Use a JPEG/PNG under 10 MB.',
          _ =>
          'Could not confirm the update. Refresh the report before retrying.',
        },
      );
    }
  }
}// Placeholder: paste the contents of mobile/lib/features/authority/authority_repository.dart from your app here.
