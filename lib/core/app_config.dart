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

  /// Initialize configuration
  static Future<void> init() async {
    try {
      await dotenv.load();
    } catch (_) {
      // .env not found (normal in production builds)
      print('⚠️ .env not found. Using dart-define values.');
    }

    apiBaseUrl =
        dotenv.env['API_BASE_URL'] ??
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:3000',
        );

    visionCraftApiKey =
        dotenv.env['VISIONCRAFT_API_KEY'] ??
        const String.fromEnvironment(
          'VISIONCRAFT_API_KEY',
          defaultValue: '',
        );

    visionCraftBaseUrl =
        dotenv.env['VISIONCRAFT_BASE_URL'] ??
        const String.fromEnvironment(
          'VISIONCRAFT_BASE_URL',
          defaultValue: 'https://visioncraft.top',
        );

    googleWebClientId =
        dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
        const String.fromEnvironment(
          'GOOGLE_WEB_CLIENT_ID',
          defaultValue: '',
        );

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

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
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