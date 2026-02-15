import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  static late Dio _dio;
  static String? _token;

  // Initialize the API client
  static Future<void> init() async {
    await dotenv.load();

    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.15:3000';

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Handle token refresh or logout here
            print('Unauthorized - Token may have expired');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Get singleton instance
  static Dio get instance => _dio;

  // Set authentication token
  static void setToken(String token) {
    _token = token;
  }

  // Clear authentication token
  static void clearToken() {
    _token = null;
  }

  // Get current token
  static String? get token => _token;

  // Check if user is authenticated
  static bool get isAuthenticated => _token != null && _token!.isNotEmpty;
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
