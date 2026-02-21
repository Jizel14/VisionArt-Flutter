import 'package:dio/dio.dart';
import 'app_config.dart';

class ApiClient {
  static late final Dio _dio;
  static String? _token;

  /// Initialize API client
  static Future<void> init() async {
    final baseUrl = AppConfig.apiBaseUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
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
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
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