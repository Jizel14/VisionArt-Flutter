import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../api_client.dart';

class CriticService {
  final Dio _dio = ApiClient.instance;

  Future<String> analyzeArt({
    String? imageUrl,
    Uint8List? imageBytes,
    String? prompt,
  }) async {
    try {
      final response = await _dio.post(
        '/critic/analyze',
        data: {
          if (imageUrl != null) 'imageUrl': imageUrl,
          if (imageBytes != null) 'image': base64Encode(imageBytes),
          if (prompt != null && prompt.isNotEmpty) 'prompt': prompt,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['feedback'] as String;
      } else {
        throw ApiException(
          response.statusCode ?? 500,
          response.data?['message'] ?? 'Failed to analyze art',
        );
      }
    } on DioException catch (e) {
      if (e.error is SessionExpiredException) {
        rethrow;
      }
      throw ApiException(
        e.response?.statusCode ?? 500,
        e.response?.data?['message'] ?? e.message ?? 'Network error',
      );
    } catch (e) {
      throw ApiException(500, e.toString());
    }
  }

  Future<Uint8List> generateArt({
    required String prompt,
    String? negativePrompt,
  }) async {
    try {
      final response = await _dio.post(
        '/critic/generate',
        data: {
          'prompt': prompt,
          if (negativePrompt != null && negativePrompt.isNotEmpty)
            'negativePrompt': negativePrompt,
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 5),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final base64String = response.data['imageBase64'] as String;
        return base64Decode(base64String);
      } else {
        throw ApiException(
          response.statusCode ?? 500,
          response.data?['message'] ?? 'Failed to generate art',
        );
      }
    } on DioException catch (e) {
      if (e.error is SessionExpiredException) {
        rethrow;
      }
      throw ApiException(
        e.response?.statusCode ?? 500,
        e.response?.data?['message'] ?? e.message ?? 'Network error',
      );
    } catch (e) {
      throw ApiException(500, e.toString());
    }
  }

  Future<Map<String, dynamic>> generateCaption({required String prompt}) async {
    try {
      final response = await _dio.post(
        '/critic/generate-caption',
        data: {'prompt': prompt},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ApiException(
          response.statusCode ?? 500,
          response.data?['message'] ?? 'Failed to generate caption',
        );
      }
    } on DioException catch (e) {
      if (e.error is SessionExpiredException) {
        rethrow;
      }
      throw ApiException(
        e.response?.statusCode ?? 500,
        e.response?.data?['message'] ?? e.message ?? 'Network error',
      );
    } catch (e) {
      throw ApiException(500, e.toString());
    }
  }
}
