import 'package:dio/dio.dart';
import '../models/follow_model.dart';
import '../api_client.dart';

class FollowService {
  late final Dio _dio = ApiClient.instance;

  /// Follow a user
  Future<FollowResponseModel> followUser(String userId) async {
    try {
      final response = await _dio.post('/social/follow/$userId');
      return FollowResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Unfollow a user
  Future<FollowResponseModel> unfollowUser(String userId) async {
    try {
      final response = await _dio.delete('/social/follow/$userId');
      return FollowResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get follow status for a user
  Future<FollowStatusModel> getFollowStatus(String userId) async {
    try {
      final response = await _dio.get('/social/follow/status/$userId');
      return FollowStatusModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get followers of a user
  Future<FollowersListModel> getFollowers({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/social/follow/followers/list',
        queryParameters: {'userId': userId, 'page': page, 'limit': limit},
      );

      final payload = response.data as Map<String, dynamic>;
      final rows = (payload['data'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) {
            final map = item as Map<String, dynamic>;
            final nested = map['follower'] as Map<String, dynamic>?;
            return nested ?? map;
          })
          .map((item) => FollowerModel.fromJson(item))
          .toList();

      final pagination =
          payload['pagination'] as Map<String, dynamic>? ?? <String, dynamic>{};

      return FollowersListModel(
        data: rows,
        pagination: PaginationModel(
          page: _toInt(pagination['page'], page),
          limit: _toInt(pagination['limit'], limit),
          total: _toInt(pagination['total'], rows.length),
          totalPages: _toInt(pagination['totalPages'], 1),
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get following list for a user
  Future<FollowersListModel> getFollowing({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/social/follow/following/list',
        queryParameters: {'userId': userId, 'page': page, 'limit': limit},
      );

      final payload = response.data as Map<String, dynamic>;
      final rows = (payload['data'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) {
            final map = item as Map<String, dynamic>;
            final nested = map['follower'] as Map<String, dynamic>?;
            return nested ?? map;
          })
          .map((item) => FollowerModel.fromJson(item))
          .toList();

      final pagination =
          payload['pagination'] as Map<String, dynamic>? ?? <String, dynamic>{};

      return FollowersListModel(
        data: rows,
        pagination: PaginationModel(
          page: _toInt(pagination['page'], page),
          limit: _toInt(pagination['limit'], limit),
          total: _toInt(pagination['total'], rows.length),
          totalPages: _toInt(pagination['totalPages'], 1),
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get follow suggestions
  Future<List<FollowerModel>> getFollowSuggestions({int limit = 50}) async {
    try {
      final response = await _dio.get(
        '/social/follow/suggestions',
        queryParameters: {'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      final suggestions = (data['suggestions'] as List)
          .map((e) => FollowerModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return suggestions;
    } catch (e) {
      rethrow;
    }
  }
}

int _toInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
