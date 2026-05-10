import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

class ApiClient {
  static late final Dio _dio;
  static String? _token;

  /// Same key as [AuthService] — keeps Bearer header in sync after hot restart.
  static const _prefsTokenKey = 'auth_token';

  /// Ensures the in-memory Bearer token matches [SharedPreferences] (e.g. after hot reload).
  static Future<void> syncTokenFromStorage() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString(_prefsTokenKey);
    if (t != null && t.isNotEmpty) {
      _token = t;
    }
  }

  /// Initialize API client
  static Future<void> init() async {
    final baseUrl = AppConfig.apiBaseUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        // Connection: close avoids flaky keep-alive through adb reverse / some hotspots.
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Connection': 'close',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          final isAuthEndpoint = path == '/auth/login' ||
              path == '/auth/register' ||
              path == '/auth/google';
          final res = error.response;
          final data = res?.data;

          if (res?.statusCode == 403 &&
              data is Map &&
              data['code'] == 'ACCOUNT_BANNED') {
            final p = await SharedPreferences.getInstance();
            await p.remove(_prefsTokenKey);
            _token = null;
            final msg = data['message'] is String
                ? data['message'] as String
                : 'Compte temporairement suspendu.';
            final until = data['bannedUntil'] is String
                ? data['bannedUntil'] as String
                : null;
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                error: AccountBannedException(403, msg, bannedUntilIso: until),
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }

          if (error.response?.statusCode == 401 && !isAuthEndpoint) {
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                error: SessionExpiredException(
                  401,
                  'Session expired. Please login again.',
                ),
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Dio instance
  static Dio get instance => _dio;

  /// Set auth token
  static void setToken(String token) {
    _token = token;
  }

  /// Clear auth token
  static void clearToken() {
    _token = null;
  }

  /// Get current token
  static String? get token => _token;

  /// Is authenticated
  static bool get isAuthenticated =>
      _token != null && _token!.isNotEmpty;
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class SessionExpiredException extends ApiException {
  SessionExpiredException(int statusCode, String message)
      : super(statusCode, message);
}

/// Server rejected requests because [bannedUntilIso] is still in the future.
class AccountBannedException extends ApiException {
  AccountBannedException(
    int statusCode,
    String message, {
    this.bannedUntilIso,
  }) : super(statusCode, message);

  final String? bannedUntilIso;
}