import 'package:dio/dio.dart';

import '../api_client.dart';
import '../models/story_model.dart';

class StoryService {
  late final Dio _dio = ApiClient.instance;

  Future<List<StoryModel>> getFeed({int limit = 50}) async {
    final response = await _dio.get(
      '/social/stories/feed',
      queryParameters: {'limit': limit},
    );

    final payload = response.data;

    final rawList = payload is Map<String, dynamic>
        ? (payload['data'] as List<dynamic>? ?? const <dynamic>[])
        : const <dynamic>[];

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(StoryModel.fromJson)
        .where((s) => !s.isExpired)
        .toList();
  }

  Future<StoryModel> createStory({required String mediaUrl}) async {
    final response = await _dio.post(
      '/social/stories',
      data: {'mediaUrl': mediaUrl},
    );

    return StoryModel.fromJson(response.data as Map<String, dynamic>);
  }
}
