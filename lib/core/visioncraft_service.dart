import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api_client.dart';

/// AI Image Generation Service — forwards requests to the NestJS backend
/// which calls the Google Gemini / Imagen API.
/// No client-side API key required.
class VisionCraftService {
  VisionCraftService();

  /// Always true — generation is handled server-side.
  bool get isConfigured => true;

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
  Future<String?> generateVideo(String artworkId, {String? prompt}) async {
    try {
      final response = await ApiClient.instance.post(
        '/social/artworks/$artworkId/generate-video',
        data: prompt != null ? {'prompt': prompt} : {},
      );
      final data = response.data;
      if (data != null && data['success'] == true) {
        return data['videoUrl'] as String;
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
}
