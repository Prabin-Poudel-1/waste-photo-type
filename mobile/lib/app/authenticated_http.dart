import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../features/auth/auth_controller.dart';

// Shared bearer handling; all report requests and private images use this client.
final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authProvider).token;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) {
        final token = ref.read(authProvider).token;
        if (error.response?.statusCode == 401 &&
            token != null &&
            error.requestOptions.headers['Authorization'] == 'Bearer $token') {
          unawaited(
            ref
                .read(authProvider.notifier)
                .logout(message: 'Session expired. Please sign in again.'),
          );
        }
        handler.next(error);
      },
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return dio;
});
