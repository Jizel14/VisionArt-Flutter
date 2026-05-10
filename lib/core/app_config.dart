import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ============================================================
/// Configuration Manager
/// ============================================================
/// Loads configuration from:
/// 1. .env file (local dev)
/// 2. --dart-define (CI/CD)
/// 3. Default fallback values

class AppConfig {
  static late final String apiBaseUrl;
  static late final String visionCraftApiKey;
  static late final String visionCraftBaseUrl;
  static late final String googleWebClientId;

  /// Trim, drop BOM, remove trailing slashes (avoids subtle .env / copy-paste issues).
  static String _normalizeBaseUrl(String raw) {
    var s = raw.trim();
    if (s.startsWith('\uFEFF')) {
      s = s.substring(1).trim();
    }
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// Initialize configuration
  static Future<void> init() async {
    try {
      await dotenv.load();
    } catch (_) {
      // .env not found (normal in production builds)
      print('⚠️ .env not found. Using dart-define values.');
    }

    apiBaseUrl = _normalizeBaseUrl(
      dotenv.env['API_BASE_URL'] ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://10.0.2.2:3000',
          ),
    );

    visionCraftApiKey =
        (dotenv.env['VISIONCRAFT_API_KEY'] ??
                const String.fromEnvironment(
                  'VISIONCRAFT_API_KEY',
                  defaultValue: '',
                ))
            .trim();

    visionCraftBaseUrl = _normalizeBaseUrl(
      dotenv.env['VISIONCRAFT_BASE_URL'] ??
          const String.fromEnvironment(
            'VISIONCRAFT_BASE_URL',
            defaultValue: 'https://visioncraft.top',
          ),
    );

    googleWebClientId =
        (dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
                const String.fromEnvironment(
                  'GOOGLE_WEB_CLIENT_ID',
                  defaultValue: '',
                ))
            .trim();

    print('AppConfig initialized:');
    print('  API Base URL: $apiBaseUrl');
    print('  VisionCraft Base URL: $visionCraftBaseUrl');
    print(
      '  VisionCraft API Key: ${visionCraftApiKey.isEmpty ? '(not set)' : '(set)'}',
    );
    print(
      '  Google Web Client ID: ${googleWebClientId.isEmpty ? '(not set)' : '(set)'}',
    );
  }
}

/// ============================================================
/// Legacy Constants (Backward Compatibility)
/// ============================================================
/// These fallback to dart-define if AppConfig.init() is not used.
/// Prefer using AppConfig.apiBaseUrl instead.

/// Default targets Android emulator (10.0.2.2 → host). Use LAN IP for physical devices.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

const String kVisionCraftApiKey = String.fromEnvironment(
  'VISIONCRAFT_API_KEY',
  defaultValue: '',
);

const String kVisionCraftBaseUrl = String.fromEnvironment(
  'VISIONCRAFT_BASE_URL',
  defaultValue: 'https://visioncraft.top',
);

const String kGoogleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '',
);