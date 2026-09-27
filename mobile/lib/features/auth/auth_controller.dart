import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';

// Compatibility export for existing feature imports.
export '../../app/authenticated_http.dart';

class AuthState {
  final bool restoring, busy;
  final String? token, name, error;
  final String role;
  bool get isAuthority => role == 'ADMIN' || role == 'DEPARTMENT';
  final int? userId;
  final DateTime? expiresAt;
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

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  final _repository = AuthRepository();
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
      final saved = await _repository.restore();
      if (_disposed) return;
      if (saved == null) {
        state = const AuthState();
        return;
      }
      final value = Map<String, dynamic>.from(jsonDecode(saved) as Map);
      final expires = DateTime.parse(value['expiresAt'] as String);
      if (!expires.isAfter(DateTime.now())) {
        await logout();
        return;
      }
      _accept(value);
    } catch (_) {
      if (!_disposed) {
        state = const AuthState(
          error: 'Could not restore your saved session. Please sign in again.',
        );
      }
    }
  }

  void _accept(Map<String, dynamic> value) {
    final user = Map<String, dynamic>.from(value['user'] as Map);
    final expires = DateTime.parse(value['expiresAt'] as String);
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
      () => logout(message: 'Session expired. Please sign in again.'),
    );
  }

  Future<void> authenticate({
    required bool register,
    required String email,
    required String password,
    String name = '',
  }) async {
    if (state.busy) return;
    state = const AuthState(busy: true);
    try {
      final value = await _repository.authenticate(
        register: register,
        email: email,
        password: password,
        name: name,
      );
      await _repository.save(value);
      if (!_disposed) _accept(value);
    } on DioException catch (e) {
      if (_disposed) return;
      state = AuthState(
        error: switch (e.response?.statusCode) {
          401 => 'Email or password is incorrect.',
          409 => 'This email is already registered. Please log in.',
          400 => 'Check your name, email and password (8–72 UTF-8 bytes).',
          _ =>
            'Could not reach the login service. Check the backend and retry.',
        },
      );
    } catch (_) {
      if (!_disposed) {
        state = const AuthState(
          error: 'Could not securely save your session. Please retry.',
        );
      }
    }
  }

  Future<void> logout({String? message}) async {
    _expiry?.cancel();
    if (!_disposed) state = AuthState(busy: true, error: message);
    try {
      await _repository.clear();
      if (!_disposed) state = AuthState(error: message);
    } catch (_) {
      if (!_disposed) {
        state = const AuthState(
          error: 'Signed out in this session, but secure storage could not be cleared. Clear app data before sharing this device.',
        );
      }
    }
  }
}
