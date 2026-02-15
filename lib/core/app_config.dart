import 'package:flutter_dotenv/flutter_dotenv.dart';

// ============================================================
// Configuration Manager
// ============================================================
// This manager loads configuration from multiple sources:
// 1. .env file (local development)
// 2. --dart-define (CI/CD builds)
// 3. Default values (fallback)

class AppConfig {
  static late final String apiBaseUrl;
  static late final String visionCraftApiKey;
  static late final String visionCraftBaseUrl;

  /// Initialize configuration from .env file
  static Future<void> init() async {
    try {
      await dotenv.load();
    } catch (e) {
      // .env file not found or error loading - will fall back to dart-define
      print('Warning: Could not load .env file, using dart-define values');
    }

    // Load API URL: dotenv > dart-define > default
    apiBaseUrl =
        dotenv.env['API_BASE_URL'] ??
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:3000',
        );

    // Load VisionCraft API Key: dotenv > dart-define > default (empty)
    visionCraftApiKey =
        dotenv.env['VISIONCRAFT_API_KEY'] ??
        const String.fromEnvironment('VISIONCRAFT_API_KEY', defaultValue: '');

    // Load VisionCraft Base URL: dotenv > dart-define > default
    visionCraftBaseUrl =
        dotenv.env['VISIONCRAFT_BASE_URL'] ??
        const String.fromEnvironment(
          'VISIONCRAFT_BASE_URL',
          defaultValue: 'https://visioncraft.top',
        );

    print('AppConfig initialized:');
    print('  API Base URL: $apiBaseUrl');
    print('  VisionCraft Base URL: $visionCraftBaseUrl');
    print(
      '  VisionCraft API Key: ${visionCraftApiKey.isEmpty ? '(not set)' : '(set)'}',
    );
  }
}

// ============================================================
// Legacy Constants (for backward compatibility)
// ============================================================
// These will fallback to dart-define if AppConfig.init() is not called
// It's recommended to use AppConfig.apiBaseUrl instead

/// API base URL for the NestJS backend.
///
/// - **Real device (phone):** Use your PC's LAN IP so the phone can reach the backend.
///   Example: http://192.168.1.100:3000
///   Find your IP: `ip addr` or `hostname -I` on Linux.
/// - **Android emulator:** http://10.0.2.2:3000
/// - **Web / desktop:** http://localhost:3000
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

/// VisionCraft AI image generation (https://visioncraft.top).
///
/// Get your API key from the VisionCraft Telegram bot: https://t.me/Metimol
/// Set via .env file: VISIONCRAFT_API_KEY=your_key
/// or via dart-define: flutter run --dart-define=VISIONCRAFT_API_KEY=your_key
const String kVisionCraftApiKey = String.fromEnvironment(
  'VISIONCRAFT_API_KEY',
  defaultValue: '',
);

const String kVisionCraftBaseUrl = String.fromEnvironment(
  'VISIONCRAFT_BASE_URL',
  defaultValue: 'https://visioncraft.top',
);
