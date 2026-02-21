import 'package:dio/dio.dart';
import '../models/artwork_model.dart';
import '../api_client.dart';

class ArtworkService {
  late final Dio _dio = ApiClient.instance;

  /// Get artwork by ID
  Future<ArtworkModel> getArtwork(String artworkId) async {
    try {
      final response = await _dio.get('/social/artworks/$artworkId');
      return ArtworkModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get personalized feed (followed users' artworks)
  Future<PaginatedArtworks> getFeed({
    int page = 1,
    int limit = 20,
    String sort = 'recent',
  }) async {
    try {
      final response = await _dio.get(
        '/social/artworks/feed',
        queryParameters: {'page': page, 'limit': limit, 'sort': sort},
      );
      return PaginatedArtworks.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get public feed (all users' public artworks)
  Future<PaginatedArtworks> getPublicFeed({
    int page = 1,
    int limit = 20,
    String sort = 'recent',
  }) async {
    try {
      final response = await _dio.get(
        '/social/artworks/feed/public',
        queryParameters: {'page': page, 'limit': limit, 'sort': sort},
      );
      return PaginatedArtworks.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get explore page (trending/popular artworks)
  Future<PaginatedArtworks> getExplore({
    int page = 1,
    int limit = 20,
    String filter = 'trending',
  }) async {
    try {
      final response = await _dio.get(
        '/social/artworks/explore',
        queryParameters: {'page': page, 'limit': limit, 'filter': filter},
      );
      return PaginatedArtworks.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's gallery (public artworks)
  Future<PaginatedArtworks> getUserGallery({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/social/artworks/user/$userId',
        queryParameters: {'page': page, 'limit': limit},
      );
      return PaginatedArtworks.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user's artworks (including private)
  Future<PaginatedArtworks> getMyArtworks({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/social/artworks/me/all',
        queryParameters: {'page': page, 'limit': limit},
      );
      return PaginatedArtworks.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get remixes of an artwork
  Future<PaginatedArtworks> getRemixes({
    required String artworkId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/social/artworks/$artworkId/remixes',
        queryParameters: {'page': page, 'limit': limit},
      );
      return PaginatedArtworks.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

class PaginatedArtworks {
  final List<ArtworkModel> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginatedArtworks({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginatedArtworks.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    final artworks = (json['data'] as List)
        .map((e) => ArtworkModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Handle both int and String values from pagination
    int _toInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.parse(value);
      return 0;
    }

    return PaginatedArtworks(
      data: artworks,
      page: _toInt(pagination['page']),
      limit: _toInt(pagination['limit']),
      total: _toInt(pagination['total']),
      totalPages: _toInt(pagination['totalPages']),
    );
  }
}
