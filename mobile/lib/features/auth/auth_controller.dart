import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/config/app_config.dart';

class AuthState {
  final bool restoring;
  final bool busy;
  final String? token;
  final String? name;
  final String? error;
  final String role;
  final int? userId;
  final DateTime? expiresAt;

  bool get isAuthority =>
      role == 'ADMIN' || role == 'DEPARTMENT';

  const AuthState({
    this.role = 'USER',
    this.restoring = false,
    this.busy = false,
    this.token,
    this.name,
    this.userId,
    this.expiresAt,
    this.error,
  });
}

final authProvider =
NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  static const _storage = FlutterSecureStorage();
  static const _key = 'chitwan_care_session';

  Timer? _expiry;
  bool _disposed = false;

  @override
  AuthState build() {
    ref.onDispose(() {
      _disposed = true;
      _expiry?.cancel();
    });

    Future.microtask(_restore);

    return const AuthState(restoring: true);
  }

  Future<void> _restore() async {
    try {
      final saved = await _storage.read(key: _key);

      if (_disposed) {
        return;
      }

      if (saved == null) {
        state = const AuthState();
        return;
      }

      final value = Map<String, dynamic>.from(
        jsonDecode(saved) as Map,
      );

      final expires = DateTime.parse(
        value['expiresAt'] as String,
      );

      if (!expires.isAfter(DateTime.now())) {
        await logout();
        return;
      }

      _accept(value);
    } catch (_) {
      if (!_disposed) {
        state = const AuthState(
          error:
          'Could not restore your saved session. Please sign in again.',
        );
      }
    }
  }

  void _accept(Map<String, dynamic> value) {
    final user = Map<String, dynamic>.from(
      value['user'] as Map,
    );

    final expires = DateTime.parse(
      value['expiresAt'] as String,
    );

    state = AuthState(
      token: value['token'] as String,
      name: user['name'] as String,
      role: user['role'] as String? ?? 'USER',
      userId: user['id'] as int,
      expiresAt: expires,
    );

    _expiry?.cancel();

    _expiry = Timer(
      expires.difference(DateTime.now()),
          () => logout(
        message: 'Session expired. Please sign in again.',
      ),
    );
  }

  Future<void> authenticate({
    required bool register,
    required String email,
    required String password,
    String name = '',
  }) async {
    if (state.busy) {
      return;
    }

    state = const AuthState(busy: true);

    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
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

      final value = Map<String, dynamic>.from(
        response.data as Map,
      );

      await _storage.write(
        key: _key,
        value: jsonEncode(value),
      );

      if (!_disposed) {
        _accept(value);
      }
    } on DioException catch (e) {
      if (_disposed) {
        return;
      }

      state = AuthState(
        error: switch (e.response?.statusCode) {
          401 => 'Email or password is incorrect.',
          409 =>
          'This email is already registered. Please log in.',
          400 =>
          'Check your name, email and password (8–72 UTF-8 bytes).',
          _ =>
          'Could not reach the login service. Check the backend and retry.',
        },
      );
    } catch (_) {
      if (!_disposed) {
        state = const AuthState(
          error:
          'Could not securely save your session. Please retry.',
        );
      }
    } finally {
      dio.close();
    }
  }

  Future<void> logout({
    String? message,
  }) async {
    _expiry?.cancel();

    if (!_disposed) {
      state = AuthState(
        busy: true,
        error: message,
      );
    }

    try {
      await _storage.delete(key: _key);

      if (!_disposed) {
        state = AuthState(error: message);
      }
    } catch (_) {
      if (!_disposed) {
        state = const AuthState(
          error:
          'Signed out in this session, but secure storage could not be cleared. Clear app data before sharing this device.',
        );
      }
    }
  }
}

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

        if (token != null) {
          options.headers['Authorization'] =
          'Bearer $token';
        }

        handler.next(options);
      },
      onError: (error, handler) {
        final token = ref.read(authProvider).token;

        if (error.response?.statusCode == 401 &&
            token != null &&
            error.requestOptions.headers['Authorization'] ==
                'Bearer $token') {
          unawaited(
            ref.read(authProvider.notifier).logout(
              message:
              'Session expired. Please sign in again.',
            ),
          );
        }

        handler.next(error);
      },
    ),
  );

  ref.onDispose(() => dio.close(force: true));

  return dio;
});// Placeholder: paste the contents of mobile/lib/features/auth/auth_controller.dart from your app here.
