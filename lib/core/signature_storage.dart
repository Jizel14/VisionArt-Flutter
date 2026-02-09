import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

const String kKeyUserSignature = 'user_signature';

/// Load/save user's custom signature image (base64 PNG) for splash logo.
class SignatureStorage {
  static Future<Uint8List?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final base64 = prefs.getString(kKeyUserSignature);
    if (base64 == null || base64.isEmpty) return null;
    try {
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kKeyUserSignature, base64Encode(bytes));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kKeyUserSignature);
  }
}
