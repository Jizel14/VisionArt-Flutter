import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'user_preferences.dart';

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

  /// Sign in with Google. Pass the [idToken] from Google Sign-In (authentication.idToken).
  Future<AuthResult> loginWithGoogle(String idToken) async {
    final res = await _api.post('/auth/google', {'idToken': idToken});
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

  Future<Map<String, dynamic>> updatePreferences(UserPreferences p) async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');
    _api.token = token;
    final body = <String, dynamic>{
      'subjects': p.subjects,
      'styles': p.styles,
      'colors': p.colors,
      'mood': p.mood,
      'complexity': p.complexity,
      'permissions': p.permissions.toJson(),
      'onboardingComplete': p.onboardingComplete,
    };
    return _api.patch('/auth/me/preferences', body);
  }

  /// Returns the API response; may contain [resetToken] when SMTP is not configured (dev).
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return _api.post('/auth/forgot-password', {'email': email});
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await _api.post('/auth/reset-password', {'token': token, 'newPassword': newPassword});
  }

  Future<void> logout() async {
    await clearToken();
  }

  /// Permanently deletes the current user account. Caller should clear local
  /// preferences and navigate to login after success.
  Future<void> deleteAccount() async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');
    _api.token = token;
    await _api.delete('/auth/me');
    await clearToken();
  }

  /// Submit a report (artwork, bug, user, other).
  Future<Map<String, dynamic>> submitReport({
    required String type,
    required String subject,
    required String description,
    String? targetId,
    String? imageUrl,
  }) async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');
    _api.token = token;
    final body = <String, dynamic>{
      'type': type,
      'subject': subject,
      'description': description,
    };
    if (targetId != null) body['targetId'] = targetId;
    if (imageUrl != null) body['imageUrl'] = imageUrl;
    return _api.post('/reports', body);
  }
}

class AuthResult {
  AuthResult({required this.token, required this.user});
  final String token;
  final Map<String, dynamic> user;
}
