/// API base URL for the NestJS backend.
///
/// - **Real device (phone):** Use your PC's LAN IP so the phone can reach the backend.
///   Example: http://192.168.1.100:3000
///   Find your IP: `ip addr` or `hostname -I` on Linux.
/// - **Android emulator:** http://10.0.2.2:3000
/// - **Web / desktop:** http://localhost:3000
const String kApiBaseUrl = 'http://10.205.182.5:3000';

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
