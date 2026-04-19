import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'app_config.dart';

/// AI Image Generation Service — forwards requests to the NestJS backend
/// which calls the Google Gemini / Imagen API.
/// No client-side API key required.
class VisionCraftService {
  VisionCraftService();

  /// Always true — generation is handled server-side.
  bool get isConfigured => true;

  /// Helper: Convert relative URL to absolute if needed
  String _toAbsoluteUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final base = AppConfig.apiBaseUrl.endsWith('/') 
        ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
        : AppConfig.apiBaseUrl;
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }

  /// Generate an image via the backend's Gemini integration.
  /// Returns raw image bytes (JPEG) on success, or null on failure.
  Future<Map<String, dynamic>?> generateImage({
    required String prompt,
    String styleName = 'anime',
    String? negativePrompt,
    String aspectRatio = 'square',
    int quality = 3,
    bool generateSimilar = false,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/social/artworks/generate',
        data: {
          'prompt': prompt,
          'negativePrompt': negativePrompt,
          'style': styleName,
          'aspectRatio': aspectRatio,
          'quality': quality,
          'generateSimilar': generateSimilar,
        },
      );

      final data = response.data;
      if (data != null && data['success'] == true && data['imageB64'] != null) {
        return {
          'imageBytes': base64Decode(data['imageB64'] as String),
          'similarArtworks': data['similarArtworks'] ?? [],
          'artworkId': data['artworkId'],
        };
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final backendError = e.response!.data['message'];
        if (backendError != null) {
          throw Exception(backendError);
        }
      }
      rethrow;
    }
  }

  /// Generate a video from an existing artwork (img+prompt to video)
  Future<String?> generateVideo(String artworkId) async {
    try {
      final response = await ApiClient.instance.post(
        '/social/artworks/$artworkId/generate-video',
      );
      final data = response.data;
      if (data != null && data['success'] == true) {
        final url = data['videoUrl'] as String;
        return _toAbsoluteUrl(url);
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final backendError = e.response!.data['message'];
        if (backendError != null) {
          throw Exception(backendError);
        }
      }
      rethrow;
    }
  }

  /// Analyze a drawing (Base64) via Gemini Vision backend and retrieve a prompt suggestion.
  Future<String?> analyzeDrawing(String base64Image) async {
    try {
      final response = await ApiClient.instance.post(
        '/social/artworks/analyze-drawing',
        data: {
          'imageB64': base64Image,
        },
      );
      final data = response.data;
      if (data != null && data['success'] == true) {
        return data['prompt'] as String;
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final backendError = e.response!.data['message'];
        if (backendError != null) {
          throw Exception(backendError);
        }
      }
      rethrow;
    }
  }

  /// Generate a matching music track for an existing artwork
  Future<String?> generateAudio(String artworkId) async {
    try {
      final response = await ApiClient.instance.post(
        '/social/artworks/$artworkId/generate-audio',
      );
      final data = response.data;
      if (data != null && data['success'] == true) {
        final url = data['audioUrl'] as String;
        return _toAbsoluteUrl(url);
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final backendError = e.response!.data['message'];
        if (backendError != null) {
          throw Exception(backendError);
        }
      }
      rethrow;
    }
  }
}
