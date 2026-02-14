import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({this.baseUrl = 'http://localhost:3000', String? token}) : _token = token;

  final String baseUrl;
  String? _token;

  set token(String? value) => _token = value;

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final r = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(r);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final r = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handleResponse(r);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final r = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(r);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final r = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handleResponse(r);
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response r) async {
    final decoded = r.body.isNotEmpty ? jsonDecode(r.body) : <String, dynamic>{};
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    }
    final message = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Request failed';
    throw ApiException(r.statusCode, message);
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => message;
}
