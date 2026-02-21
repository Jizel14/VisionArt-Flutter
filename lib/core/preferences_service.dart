import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'models/user_preferences.dart';

/// Service for managing user preferences
/// Handles all API calls to the backend preferences endpoints
class PreferencesService {
  PreferencesService({SharedPreferences? prefs}) : _prefs = prefs;

  late final Dio _dio = ApiClient.instance;
  SharedPreferences? _prefs;
  static const _keyPreferences = 'user_preferences_cached';

  Future<SharedPreferences> get prefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Get current user preferences
  /// Auto-creates defaults if not yet configured
  Future<UserPreferences> getPreferences() async {
    try {
      final res = await _dio.get('/user-preferences/me');
      final prefs = UserPreferences.fromJson(res.data);
      _cachePreferences(prefs);
      return prefs;
    } on SessionExpiredException {
      rethrow;
    }
  }

  /// Get default preferences structure (public endpoint)
  /// Useful for UI initialization before login
  Future<UserPreferences> getDefaultPreferences() async {
    try {
      final res = await _dio.get('/user-preferences/defaults');
      return UserPreferences.fromJson(res.data);
    } catch (e) {
      // Return fallback defaults if API call fails
      return UserPreferences();
    }
  }

  /// Update preferences (full or partial update)
  Future<UserPreferences> updatePreferences(UserPreferences prefs) async {
    try {
      final res = await _dio.patch(
        '/user-preferences/me',
        data: prefs.toJson(),
      );
      final updated = UserPreferences.fromJson(res.data);
      _cachePreferences(updated);
      return updated;
    } on SessionExpiredException {
      rethrow;
    }
  }

  /// Update only specific preference fields
  Future<UserPreferences> updatePreferencesPartial(
    Map<String, dynamic> updates,
  ) async {
    try {
      final res = await _dio.patch('/user-preferences/me', data: updates);
      final updated = UserPreferences.fromJson(res.data);
      _cachePreferences(updated);
      return updated;
    } on SessionExpiredException {
      rethrow;
    }
  }

  /// Reset preferences to defaults
  Future<UserPreferences> resetPreferences() async {
    try {
      final res = await _dio.post('/user-preferences/reset', data: {});
      final prefs = UserPreferences.fromJson(res.data);
      _cachePreferences(prefs);
      return prefs;
    } on SessionExpiredException {
      rethrow;
    }
  }

  /// Get context permissions (which data contexts user has consented to)
  Future<Map<String, bool>> getContextPermissions() async {
    try {
      final res = await _dio.get('/user-preferences/me/context-permissions');
      final perms = <String, bool>{};
      if (res.data is Map) {
        res.data.forEach((key, value) {
          perms[key] = value as bool? ?? false;
        });
      }
      return perms;
    } on SessionExpiredException {
      rethrow;
    }
  }

  /// Get preferences formatted for AI generation
  /// Only includes data user has consented to
  Future<Map<String, dynamic>> getGenerationContext() async {
    try {
      final res = await _dio.get('/user-preferences/me/generation-context');
      return Map<String, dynamic>.from(res.data as Map? ?? {});
    } on SessionExpiredException {
      rethrow;
    }
  }

  /// Update artistic style preferences
  Future<UserPreferences> updateStyles({
    required List<String> favoriteStyles,
    required List<String> favoriteColors,
    String? preferredMood,
    String? artComplexity,
  }) async {
    final updates = <String, dynamic>{};
    updates['favoriteStyles'] = favoriteStyles;
    updates['favoriteColors'] = favoriteColors;
    if (preferredMood != null) updates['preferredMood'] = preferredMood;
    if (artComplexity != null) updates['artComplexity'] = artComplexity;
    return updatePreferencesPartial(updates);
  }

  /// Update context permissions
  Future<UserPreferences> updateContextPermissions({
    bool? enableLocationContext,
    bool? enableWeatherContext,
    bool? enableCalendarContext,
    bool? enableMusicContext,
    bool? enableTimeContext,
    String? locationPrecision,
  }) async {
    final updates = <String, dynamic>{};
    if (enableLocationContext != null)
      updates['enableLocationContext'] = enableLocationContext;
    if (enableWeatherContext != null)
      updates['enableWeatherContext'] = enableWeatherContext;
    if (enableCalendarContext != null)
      updates['enableCalendarContext'] = enableCalendarContext;
    if (enableMusicContext != null)
      updates['enableMusicContext'] = enableMusicContext;
    if (enableTimeContext != null)
      updates['enableTimeContext'] = enableTimeContext;
    if (locationPrecision != null)
      updates['locationPrecision'] = locationPrecision;
    return updatePreferencesPartial(updates);
  }

  /// Update generation preferences
  Future<UserPreferences> updateGenerationPreferences({
    String? defaultResolution,
    String? defaultAspectRatio,
    bool? enableNSFWFilter,
    String? generationQuality,
  }) async {
    final updates = <String, dynamic>{};
    if (defaultResolution != null)
      updates['defaultResolution'] = defaultResolution;
    if (defaultAspectRatio != null)
      updates['defaultAspectRatio'] = defaultAspectRatio;
    if (enableNSFWFilter != null)
      updates['enableNSFWFilter'] = enableNSFWFilter;
    if (generationQuality != null)
      updates['generationQuality'] = generationQuality;
    return updatePreferencesPartial(updates);
  }

  /// Update UI/UX preferences
  Future<UserPreferences> updateUIPreferences({
    String? preferredLanguage,
    String? theme,
    bool? notificationsEnabled,
    bool? emailNotificationsEnabled,
  }) async {
    final updates = <String, dynamic>{};
    if (preferredLanguage != null)
      updates['preferredLanguage'] = preferredLanguage;
    if (theme != null) updates['theme'] = theme;
    if (notificationsEnabled != null)
      updates['notificationsEnabled'] = notificationsEnabled;
    if (emailNotificationsEnabled != null)
      updates['emailNotificationsEnabled'] = emailNotificationsEnabled;
    return updatePreferencesPartial(updates);
  }

  /// Update privacy preferences
  Future<UserPreferences> updatePrivacyPreferences({
    int? dataRetentionPeriod,
    bool? allowDataForTraining,
    bool? shareGenerationsPublicly,
  }) async {
    final updates = <String, dynamic>{};
    if (dataRetentionPeriod != null)
      updates['dataRetentionPeriod'] = dataRetentionPeriod;
    if (allowDataForTraining != null)
      updates['allowDataForTraining'] = allowDataForTraining;
    if (shareGenerationsPublicly != null)
      updates['shareGenerationsPublicly'] = shareGenerationsPublicly;
    return updatePreferencesPartial(updates);
  }

  /// Cache preferences locally for instant access
  void _cachePreferences(UserPreferences prefs) async {
    try {
      final p = await this.prefs;
      p.setString(_keyPreferences, _preferencesToJson(prefs));
    } catch (_) {}
  }

  /// Get cached preferences
  /// Returns null if not cached
  Future<UserPreferences?> getCachedPreferences() async {
    try {
      final p = await prefs;
      final json = p.getString(_keyPreferences);
      if (json != null) {
        return UserPreferences.fromJson(
          Map<String, dynamic>.from(_jsonToPreferences(json)),
        );
      }
    } catch (_) {}
    return null;
  }

  /// Clear cached preferences
  Future<void> clearCache() async {
    try {
      final p = await prefs;
      p.remove(_keyPreferences);
    } catch (_) {}
  }

  String _preferencesToJson(UserPreferences prefs) {
    // Simple JSON serialization
    return prefs.toJson().toString();
  }

  Map<String, dynamic> _jsonToPreferences(String json) {
    // Simple JSON deserialization (in production, use proper JSON library)
    // For now, return empty map - will fetch from API
    return {};
  }
}
