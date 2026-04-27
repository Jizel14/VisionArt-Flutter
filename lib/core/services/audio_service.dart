import 'package:dio/dio.dart';
import '../api_client.dart';
import '../app_config.dart';

/// AI Audio service — talks to the NestJS backend `/audio/*` endpoints.
/// The backend uses UdioAPI / Beatoven to generate tracks server-side and
/// returns relative URLs (e.g. `/audio/file/<uuid>.mp3`).
class AudioService {
  AudioService();

  String toAbsoluteUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
        : AppConfig.apiBaseUrl;
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }

  /// Generate a 3-track playlist from preferences.
  /// Returns absolute URLs.
  Future<List<String>> generatePlaylist({
    List<String> aesthetics = const [],
    List<String> colors = const [],
    String? mood,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/audio/playlist',
        data: {
          'aesthetics': aesthetics,
          'colors': colors,
          'mood': mood,
        },
      );
      final data = response.data;
      if (data is Map && data['tracks'] is List) {
        return (data['tracks'] as List)
            .whereType<String>()
            .map(toAbsoluteUrl)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? 'Audio generation failed');
    }
  }

  /// Generate a single track that matches an image vibe.
  /// `keywords` is a comma-separated list (e.g. "ambient, calm, piano").
  Future<String?> generateForImage(String keywords) async {
    try {
      final response = await ApiClient.instance.post(
        '/audio/for-image',
        data: {'keywords': keywords},
      );
      final data = response.data;
      if (data is Map && data['url'] is String) {
        return toAbsoluteUrl(data['url'] as String);
      }
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? 'Audio generation failed');
    }
  }
}
