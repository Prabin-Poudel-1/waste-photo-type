import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/config/app_config.dart';

/// Owns authentication transport and secure session persistence.
class AuthRepository {
  static const _storage = FlutterSecureStorage();
  static const _key = 'chitwan_care_session';

  Future<String?> restore() => _storage.read(key: _key);
  Future<void> save(Map<String, dynamic> value) =>
      _storage.write(key: _key, value: jsonEncode(value));
  Future<void> clear() => _storage.delete(key: _key);

  Future<Map<String, dynamic>> authenticate({
    required bool register,
    required String email,
    required String password,
    String name = '',
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    try {
      final response = await dio.post(
        '/api/v1/auth/${register ? 'register' : 'login'}',
        data: {
          'email': email.trim(),
          'password': password,
          if (register) 'name': name.trim(),
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } finally {
      dio.close();
    }
  }
}
