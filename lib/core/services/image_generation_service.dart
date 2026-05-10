import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../api_client.dart';

/// Talks to the backend `/image-generation/*` endpoints.
/// The backend (NestJS) proxies to HuggingFace FLUX.1-schnell so the mobile
/// app does not need any third-party API key.
class ImageGenerationService {
  Future<Uint8List> generateImage({
    required String prompt,
    String? negativePrompt,
    String? style,
    String? aspectRatio,
    int? quality,
  }) async {
    try {
      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        '/image-generation/generate',
        data: {
          'prompt': prompt,
          if (negativePrompt != null && negativePrompt.isNotEmpty)
            'negativePrompt': negativePrompt,
          if (style != null) 'style': style,
          if (aspectRatio != null) 'aspectRatio': aspectRatio,
          if (quality != null) 'quality': quality,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      final data = response.data;
      if (data == null || data['base64'] == null) {
        throw ApiException(500, 'Invalid response from image generation');
      }
      return base64Decode(data['base64'] as String);
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 500;
      final body = e.response?.data;
      final msg = (body is Map && body['message'] is String)
          ? body['message'] as String
          : (e.message ?? 'Image generation failed');
      throw ApiException(code, msg);
    }
  }

  Future<List<Uint8List>> generateSimilarImages({
    required String prompt,
    String? negativePrompt,
    String? style,
    String? aspectRatio,
  }) async {
    try {
      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        '/image-generation/generate-similar',
        data: {
          'prompt': prompt,
          if (negativePrompt != null && negativePrompt.isNotEmpty)
            'negativePrompt': negativePrompt,
          if (style != null) 'style': style,
          if (aspectRatio != null) 'aspectRatio': aspectRatio,
        },
        options: Options(receiveTimeout: const Duration(seconds: 180)),
      );
      final list = (response.data?['images'] as List?) ?? const [];
      return list
          .map((e) => base64Decode((e as Map)['base64'] as String))
          .toList();
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 500;
      final body = e.response?.data;
      final msg = (body is Map && body['message'] is String)
          ? body['message'] as String
          : (e.message ?? 'Image generation failed');
      throw ApiException(code, msg);
    }
  }

  Future<String> analyzeDrawing(String base64Image) async {
    try {
      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        '/image-generation/analyze-drawing',
        data: {'base64Image': base64Image},
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );
      return (response.data?['prompt'] as String?) ?? '';
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 500;
      throw ApiException(code, e.message ?? 'Sketch analysis failed');
    }
  }
}
