import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'user_preferences.dart';

class AuthService {
  AuthService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _keyToken = 'auth_token';

  Future<SharedPreferences> get prefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  // =========================
  // Auth State
  // =========================

  Future<String?> get getToken async {
    final p = await prefs;
    return p.getString(_keyToken);
  }

  Future<bool> get isLoggedIn async {
    final token = await getToken;
    return token != null && token.isNotEmpty;
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

  // =========================
  // LOGIN / REGISTER
  // =========================

  Future<AuthResult> login(String email, String password) async {
    final response = await ApiClient.instance.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final token = response.data['access_token'] as String?;
    if (token == null) throw ApiException(400, 'No token in response');

    await _saveToken(token);

    return AuthResult(
      token: token,
      user: Map<String, dynamic>.from(response.data['user'] ?? {}),
    );
  }

  Future<AuthResult> register(
    String email,
    String password,
    String name,
  ) async {
    final response = await ApiClient.instance.post(
      '/auth/register',
      data: {'email': email, 'password': password, 'name': name},
    );

    final token = response.data['access_token'] as String?;
    if (token == null) throw ApiException(400, 'No token in response');

    await _saveToken(token);

    return AuthResult(
      token: token,
      user: Map<String, dynamic>.from(response.data['user'] ?? {}),
    );
  }

  Future<AuthResult> loginWithGoogle(String idToken) async {
    final response = await ApiClient.instance.post(
      '/auth/google',
      data: {'idToken': idToken},
    );

    final token = response.data['access_token'] as String?;
    if (token == null) throw ApiException(400, 'No token in response');

    await _saveToken(token);

    return AuthResult(
      token: token,
      user: Map<String, dynamic>.from(response.data['user'] ?? {}),
    );
  }

  // =========================
  // PROFILE
  // =========================

  Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');

    try {
      final response = await ApiClient.instance.get('/auth/me');
      return Map<String, dynamic>.from(response.data ?? {});
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

      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearToken();
      }
      rethrow;
    }
  }

  // =========================
  // PREFERENCES
  // =========================

  String _mapComplexityToBackend(int complexity) {
    if (complexity <= 2) return 'minimal';
    if (complexity >= 4) return 'detailed';
    return 'moderate';
  }

  int _mapComplexityFromBackend(String? complexity) {
    switch (complexity) {
      case 'minimal':
        return 1;
      case 'detailed':
        return 5;
      default:
        return 3;
    }
  }

  UserPreferences _mapBackendToOnboardingPrefs(Map<String, dynamic> data) {
    return UserPreferences(
      subjects: const [],
      styles: List<String>.from(data['favoriteStyles'] as List? ?? const []),
      colors: List<String>.from(data['favoriteColors'] as List? ?? const []),
      mood: data['preferredMood'] as String?,
      complexity: _mapComplexityFromBackend(data['artComplexity'] as String?),
      permissions: PreferencePermissions(
        location: data['enableLocationContext'] as bool? ?? false,
        weather: data['enableWeatherContext'] as bool? ?? false,
        music: data['enableMusicContext'] as bool? ?? false,
        calendar: data['enableCalendarContext'] as bool? ?? false,
        timeOfDay: data['enableTimeContext'] as bool? ?? true,
        gallery: false,
      ),
      onboardingComplete: true,
    );
  }

  Future<UserPreferences> getOnboardingPreferences() async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');

    final response = await ApiClient.instance.get('/user-preferences/me');
    final data = Map<String, dynamic>.from(response.data ?? {});
    return _mapBackendToOnboardingPrefs(data);
  }

  Future<bool> needsPreferencesOnboarding() async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');

    final response = await ApiClient.instance.get('/user-preferences/me');
    final data = Map<String, dynamic>.from(response.data ?? {});

    final favoriteStyles = List<String>.from(
      data['favoriteStyles'] as List? ?? const [],
    );
    final favoriteColors = List<String>.from(
      data['favoriteColors'] as List? ?? const [],
    );
    final preferredMood = data['preferredMood'] as String?;
    final lastStyleUpdate = data['lastStyleUpdate'];

    return favoriteStyles.isEmpty &&
        favoriteColors.isEmpty &&
        (preferredMood == null || preferredMood.isEmpty) &&
        lastStyleUpdate == null;
  }

  Future<Map<String, dynamic>> updatePreferences(UserPreferences p) async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');

    final body = {
      'favoriteStyles': p.styles,
      'favoriteColors': p.colors,
      'preferredMood': p.mood,
      'artComplexity': _mapComplexityToBackend(p.complexity),
      'enableLocationContext': p.permissions.location,
      'enableWeatherContext': p.permissions.weather,
      'enableCalendarContext': p.permissions.calendar,
      'enableMusicContext': p.permissions.music,
      'enableTimeContext': p.permissions.timeOfDay,
    };

    final response = await ApiClient.instance.patch(
      '/user-preferences/me',
      data: body,
    );

    return Map<String, dynamic>.from(response.data ?? {});
  }

  // =========================
  // PASSWORD
  // =========================

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await ApiClient.instance.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await ApiClient.instance.post(
      '/auth/reset-password',
      data: {'token': token, 'newPassword': newPassword},
    );
  }

  // =========================
  // ACCOUNT
  // =========================

  Future<void> deleteAccount() async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');

    await ApiClient.instance.delete('/auth/me');
    await clearToken();
  }

  Future<void> logout() async {
    await clearToken();
  }

  // =========================
  // REPORT
  // =========================

  Future<Map<String, dynamic>> submitReport({
    required String type,
    required String subject,
    required String description,
    String? targetId,
    String? imageUrl,
  }) async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');

    final body = {
      'type': type,
      'subject': subject,
      'description': description,
      if (targetId != null) 'targetId': targetId,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };

    final response = await ApiClient.instance.post('/reports', data: body);

    return Map<String, dynamic>.from(response.data ?? {});
  }
}

class AuthResult {
  AuthResult({required this.token, required this.user});

  final String token;
  final Map<String, dynamic> user;
}
