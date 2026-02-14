/// API base URL for the NestJS backend.
///
/// - **Real device (phone):** Use your PC's LAN IP so the phone can reach the backend.
///   Example: http://192.168.1.100:3000
///   Find your IP: `ip addr` or `hostname -I` on Linux.
/// - **Android emulator:** http://10.0.2.2:3000
/// - **Web / desktop:** http://localhost:3000
const String kApiBaseUrl = 'http://172.28.11.5:3000';

/// VisionCraft AI image generation (https://visioncraft.top).
///
/// Get your API key from the VisionCraft Telegram bot: https://t.me/Metimol
/// Set via dart-define: flutter run --dart-define=VISIONCRAFT_API_KEY=your_key
/// or replace this placeholder for development.
const String kVisionCraftApiKey = String.fromEnvironment(
  'VISIONCRAFT_API_KEY',
  defaultValue: '',
);
const String kVisionCraftBaseUrl = 'https://visioncraft.top';

/// Google Sign-In Web Client ID (OAuth 2.0 Web application in Google Cloud Console).
/// Must match GOOGLE_CLIENT_ID on the backend.
const String kGoogleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '987311737711-ook0mrmtt827pd25afngb2jrivia4ccu.apps.googleusercontent.com',
);
