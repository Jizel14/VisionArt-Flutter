import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_preferences.dart';

const String _keyPreferences = 'user_preferences';

class PreferenceStorage {
  static Future<UserPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPreferences);
    if (raw == null) return UserPreferences();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>?;
      return UserPreferences.fromJson(json);
    } catch (_) {
      return UserPreferences();
    }
  }

  static Future<void> save(UserPreferences p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPreferences, jsonEncode(p.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPreferences);
  }
}
