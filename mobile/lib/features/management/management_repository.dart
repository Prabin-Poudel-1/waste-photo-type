import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../auth/auth_controller.dart';

class ManagedRecord {
  final int id;
  final String name, description, address;
  final bool active;
  final double? latitude, longitude;
  final int? radiusMeters;
  ManagedRecord(Map<String, dynamic> j)
    : id = j['id'] as int,
      name = j['name'] as String,
      description = j['description'] as String? ?? '',
      address = j['address'] as String? ?? '',
      active = j['active'] as bool,
      latitude = (j['latitude'] as num?)?.toDouble(),
      longitude = (j['longitude'] as num?)?.toDouble(),
      radiusMeters = j['radiusMeters'] as int?;
}

final managementRepositoryProvider = Provider(
  (ref) => ManagementRepository(ref.watch(authenticatedDioProvider)),
);

class ManagementRepository {
  final Dio dio;
  ManagementRepository(this.dio);
  String path(bool spots) =>
      '/api/v1/admin/management/${spots ? 'tourist-spots' : 'departments'}';
  Future<List<ManagedRecord>> list(bool spots) async {
    try {
      final response = await dio.get(path(spots));
      return (response.data as List)
          .map((e) => ManagedRecord(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw failure(e);
    }
  }

  Future<void> save(bool spots, int? id, Map<String, dynamic> data) async {
    try {
      if (id == null) {
        await dio.post(path(spots), data: data);
      } else {
        await dio.put('${path(spots)}/$id', data: data);
      }
    } catch (e) {
      throw failure(e);
    }
  }

  AppFailure failure(Object error) => AppFailure(switch (error) {
    DioException(response: final r) when r?.statusCode == 409 =>
      'This name already exists. Check active and inactive records.',
    DioException(response: final r) when r?.statusCode == 403 =>
      'Only an administrator can manage these records.',
    DioException(response: final r) when r?.statusCode == 400 =>
      'Check the required fields and location values.',
    DioException(response: final r) when r?.statusCode == 404 =>
      'This record is no longer available. Refresh the list.',
    _ => 'Could not save or load data. Check your connection and retry.',
  });
}
