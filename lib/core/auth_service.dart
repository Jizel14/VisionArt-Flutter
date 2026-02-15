import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import './api_client.dart';

class AuthService {
  AuthService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _keyToken = 'auth_token';

  Future<SharedPreferences> get prefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<bool> get isLoggedIn async {
    final token = await getToken;
    return token != null && token.isNotEmpty;
  }

  Future<String?> get getToken async {
    final p = await prefs;
    return p.getString(_keyToken);
  }

  Future<void> _saveToken(String token) async {
    (await prefs).setString(_keyToken, token);
    ApiClient.setToken(token);
  }

  Future<void> clearToken() async {
    final p = await prefs;
    await p.remove(_keyToken);
    ApiClient.clearToken();
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await ApiClient.instance.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final token = response.data['access_token'] as String?;
      if (token == null) throw ApiException(400, 'No token in response');
      await _saveToken(token);
      return AuthResult(
        token: token,
        user: Map<String, dynamic>.from(response.data['user'] as Map? ?? {}),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResult> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      final response = await ApiClient.instance.post(
        '/auth/register',
        data: {'email': email, 'password': password, 'name': name},
      );
      final token = response.data['access_token'] as String?;
      if (token == null) throw ApiException(400, 'No token in response');
      await _saveToken(token);
      return AuthResult(
        token: token,
        user: Map<String, dynamic>.from(response.data['user'] as Map? ?? {}),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');
    try {
      final response = await ApiClient.instance.get('/auth/me');
      return Map<String, dynamic>.from(response.data as Map? ?? {});
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearToken();
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? bio,
    String? avatarUrl,
    String? phoneNumber,
    String? website,
  }) async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (bio != null) body['bio'] = bio;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (website != null) body['website'] = website;
    try {
      final response = await ApiClient.instance.patch('/auth/me', data: body);
      return Map<String, dynamic>.from(response.data as Map? ?? {});
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearToken();
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await clearToken();
  }
}

class AuthResult {
  AuthResult({required this.token, required this.user});
  final String token;
  final Map<String, dynamic> user;
}
