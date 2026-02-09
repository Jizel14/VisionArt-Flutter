import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

class AuthService {
  AuthService({ApiClient? api, SharedPreferences? prefs})
      : _api = api ?? ApiClient(),
        _prefs = prefs;

  final ApiClient _api;
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
    _api.token = token;
  }

  Future<void> clearToken() async {
    (await prefs).remove(_keyToken);
    _api.token = null;
  }

  Future<AuthResult> login(String email, String password) async {
    final res = await _api.post('/auth/login', {'email': email, 'password': password});
    final token = res['access_token'] as String?;
    if (token == null) throw ApiException(400, 'No token in response');
    await _saveToken(token);
    return AuthResult(
      token: token,
      user: Map<String, dynamic>.from(res['user'] as Map? ?? {}),
    );
  }

  Future<AuthResult> register(String email, String password, String name) async {
    final res = await _api.post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
    });
    final token = res['access_token'] as String?;
    if (token == null) throw ApiException(400, 'No token in response');
    await _saveToken(token);
    return AuthResult(
      token: token,
      user: Map<String, dynamic>.from(res['user'] as Map? ?? {}),
    );
  }

  Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');
    _api.token = token;
    return _api.get('/auth/me');
  }

  Future<Map<String, dynamic>> updateProfile({String? name, String? email}) async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');
    _api.token = token;
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    return _api.patch('/auth/me', body);
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
