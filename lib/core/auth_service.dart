import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'user_preferences.dart';

class AuthService {
  AuthService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _keyToken = 'auth_token';

  /// The currently authenticated user's ID (set on login / profile fetch).
  static String? currentUserId;

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

    final user = Map<String, dynamic>.from(response.data['user'] ?? {});
    currentUserId = user['id'] as String?;

    return AuthResult(token: token, user: user);
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

    final user = Map<String, dynamic>.from(response.data['user'] ?? {});
    currentUserId = user['id'] as String?;

    return AuthResult(token: token, user: user);
  }

  Future<AuthResult> loginWithGoogle(String idToken) async {
    final response = await ApiClient.instance.post(
      '/auth/google',
      data: {'idToken': idToken},
    );

    final token = response.data['access_token'] as String?;
    if (token == null) throw ApiException(400, 'No token in response');

    await _saveToken(token);

    final user = Map<String, dynamic>.from(response.data['user'] ?? {});
    currentUserId = user['id'] as String?;

    return AuthResult(token: token, user: user);
  }

  // =========================
  // PROFILE
  // =========================

  Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');

    try {
      final response = await ApiClient.instance.get('/auth/me');
      final data = Map<String, dynamic>.from(response.data ?? {});
      currentUserId = data['id'] as String?;
      return data;
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

    final response = await ApiClient.instance.get('/auth/me');
    final data = Map<String, dynamic>.from(response.data['preferences'] ?? {});
    return _mapBackendToOnboardingPrefs(data);
  }

  Future<bool> needsPreferencesOnboarding() async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');

    try {
      final response = await ApiClient.instance.get('/auth/me');
      
      final dynamic body = response.data;
      if (body == null || body is! Map) {
        return true;
      }

      final preferencesData = body['preferences'];
      
      if (preferencesData == null) {
        return true;
      }
      
      final data = Map<String, dynamic>.from(preferencesData is Map ? preferencesData : {});

    // Check if onboarding is explicitly marked as complete
    // Be robust with types (bool, int, or string)
    final onboardingComplete = data['onboardingComplete'];
    if (onboardingComplete == true || 
        onboardingComplete == 1 || 
        onboardingComplete == 'true' ||
        onboardingComplete == '1') {
      return false;
    }

    // Fallback: Check if user has at least some preferences set
    final favoriteStyles = data['favoriteStyles'] as List? ?? [];
    final favoriteColors = data['favoriteColors'] as List? ?? [];
    final styles = data['styles'] as List? ?? [];
    final colors = data['colors'] as List? ?? [];
    final subjects = data['subjects'] as List? ?? [];
    final playlists = data['playlists'] as List? ?? [];
    final playlistUrls = data['playlistUrls'] as List? ?? [];
    
    final preferredMood = data['preferredMood']?.toString() ?? '';
    final mood = data['mood']?.toString() ?? '';
    
    // Legacy fields
    final artComplexity = data['artComplexity']?.toString() ?? '';
    final complexity = data['complexity']?.toString() ?? '';

    // If ANY of these have data, we assume onboarding is NOT needed
    final hasSomePrefs = favoriteStyles.isNotEmpty ||
        favoriteColors.isNotEmpty ||
        styles.isNotEmpty ||
        colors.isNotEmpty ||
        subjects.isNotEmpty ||
        playlists.isNotEmpty ||
        playlistUrls.isNotEmpty ||
        preferredMood.isNotEmpty ||
        mood.isNotEmpty ||
        artComplexity.isNotEmpty ||
        complexity.isNotEmpty;

    return !hasSomePrefs;
    } catch (e) {
      print('Error checking onboarding status: $e');
      // If we can't check, safer to assume they might need it, 
      // but let's not block them if it's just a network error.
      return false; 
    }
  }

  Future<Map<String, dynamic>> updatePreferences(UserPreferences p) async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');

    final body = {
      'favoriteStyles': p.styles,
      'favoriteColors': p.colors,
      'preferredMood': p.mood,
      'styles': p.styles,
      'colors': p.colors,
      'mood': p.mood,
      'subjects': p.subjects,
      'onboardingComplete': p.onboardingComplete,
      'artComplexity': _mapComplexityToBackend(p.complexity),
      'complexity': _mapComplexityToBackend(p.complexity),
      'enableLocationContext': p.permissions.location,
      'enableWeatherContext': p.permissions.weather,
      'enableCalendarContext': p.permissions.calendar,
      'enableMusicContext': p.permissions.music,
      'enableTimeContext': p.permissions.timeOfDay,
      'playlistUrls': p.playlistUrls,
      'playlists': p.playlists.map((e) => e.toJson()).toList(),
    };

    final response = await ApiClient.instance.patch(
      '/user-preferences/me',
      data: body,
    );

    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<List<String>> generatePlaylist() async {
    final token = await getToken;
    if (token == null) throw ApiException(401, 'Not logged in');

    final response = await ApiClient.instance.post('/user-preferences/generate-playlist');
    final data = Map<String, dynamic>.from(response.data ?? {});
    return List<String>.from(data['playlistUrls'] as List? ?? const []);
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
    currentUserId = null;
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
