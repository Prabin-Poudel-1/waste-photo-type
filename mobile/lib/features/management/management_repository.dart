import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../auth/auth_controller.dart';

class ManagedRecord {
  final int id;
  final String name;
  final String description;
  final String address;
  final bool active;
  final double? latitude;
  final double? longitude;
  final int? radiusMeters;

  ManagedRecord(Map<String, dynamic> json)
      : id = json['id'] as int,
        name = json['name'] as String,
        description =
            json['description'] as String? ?? '',
        address =
            json['address'] as String? ?? '',
        active = json['active'] as bool,
        latitude =
        (json['latitude'] as num?)
            ?.toDouble(),
        longitude =
        (json['longitude'] as num?)
            ?.toDouble(),
        radiusMeters =
        json['radiusMeters'] as int?;
}

final managementRepositoryProvider = Provider(
      (ref) => ManagementRepository(
    ref.watch(authenticatedDioProvider),
  ),
);

class ManagementRepository {
  final Dio dio;

  ManagementRepository(this.dio);

  String path(bool spots) {
    return '/api/v1/admin/management/'
        '${spots ? 'tourist-spots' : 'departments'}';
  }

  Future<List<ManagedRecord>> list(
      bool spots,
      ) async {
    try {
      final response = await dio.get(
        path(spots),
      );

      return (response.data as List)
          .map(
            (entry) => ManagedRecord(
          Map<String, dynamic>.from(
            entry as Map,
          ),
        ),
      )
          .toList();
    } catch (error) {
      throw failure(error);
    }
  }

  Future<void> save(
      bool spots,
      int? id,
      Map<String, dynamic> data,
      ) async {
    try {
      if (id == null) {
        await dio.post(
          path(spots),
          data: data,
        );
      } else {
        await dio.put(
          '${path(spots)}/$id',
          data: data,
        );
      }
    } catch (error) {
      throw failure(error);
    }
  }

  AppFailure failure(Object error) {
    return AppFailure(
      switch (error) {
        DioException(response: final response)
        when response?.statusCode == 409 =>
        'This name already exists. Check active and inactive records.',
        DioException(response: final response)
        when response?.statusCode == 403 =>
        'Only an administrator can manage these records.',
        DioException(response: final response)
        when response?.statusCode == 400 =>
        'Check the required fields and location values.',
        DioException(response: final response)
        when response?.statusCode == 404 =>
        'This record is no longer available. Refresh the list.',
        _ =>
        'Could not save or load data. Check your connection and retry.',
      },
    );
  }
}// Placeholder: paste the contents of mobile/lib/features/management/management_repository.dart from your app here.
