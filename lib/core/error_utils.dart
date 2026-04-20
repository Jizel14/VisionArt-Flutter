import 'package:dio/dio.dart';

import 'api_client.dart';

/// User-facing message from API/network errors (Dio, ApiException, etc.).
String userFacingApiError(Object e) {
  if (e is ApiException) return e.message;
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
      if (msg is List && msg.isNotEmpty) return msg.first.toString();
    }
    final status = e.response?.statusCode;
    if (status == 401) return 'Please sign in again.';
    if (status == 404) return 'Not found.';
    if (status == 400) return 'Invalid request.';
    if (status != null) return 'Server error ($status). Please try again.';
    return 'Could not reach the server. Check your connection.';
  }
  return e.toString();
}
