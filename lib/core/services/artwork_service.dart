import 'package:dio/dio.dart';
import '../models/artwork_model.dart';
import '../api_client.dart';

class ArtworkService {
  late final Dio _dio = ApiClient.instance;

  static const List<String> reportReasons = <String>[
    'inappropriate',
    'copyright',
    'nsfw',
    'spam',
    'other',
  ];

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

  Future<int> likeArtwork(String artworkId) async {
    try {
      final response = await _dio.post('/social/artworks/$artworkId/like');
      final data = response.data as Map<String, dynamic>;
      return _toInt(data['likesCount']);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> unlikeArtwork(String artworkId) async {
    try {
      final response = await _dio.delete('/social/artworks/$artworkId/like');
      final data = response.data as Map<String, dynamic>;
      return _toInt(data['likesCount']);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ArtworkCommentItem>> getArtworkComments(
    String artworkId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/social/artworks/$artworkId/comments',
        queryParameters: {'page': page, 'limit': limit},
      );

      final payload = response.data as Map<String, dynamic>;
      final comments = (payload['data'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (item) => ArtworkCommentItem.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      return comments;
    } catch (e) {
      rethrow;
    }
  }

  Future<ArtworkCommentItem> createArtworkComment(
    String artworkId,
    String content,
  ) async {
    try {
      final response = await _dio.post(
        '/social/artworks/$artworkId/comments',
        data: {'content': content},
      );

      return ArtworkCommentItem.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reportArtwork({
    required String artworkId,
    required String reason,
    String? details,
  }) async {
    if (!reportReasons.contains(reason)) {
      throw ApiException(400, 'Invalid report reason');
    }

    await _dio.post(
      '/social/artworks/$artworkId/report',
      data: {
        'reason': reason,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      },
    );
  }

  Future<void> saveArtwork(
    String artworkId, {
    String collectionName = 'Favorites',
  }) async {
    await _dio.post(
      '/social/artworks/$artworkId/save',
      data: {'collectionName': collectionName},
    );
  }

  Future<void> unsaveArtwork(String artworkId) async {
    await _dio.delete('/social/artworks/$artworkId/save');
  }

  Future<List<CollectionSummary>> getCollections() async {
    final response = await _dio.get('/social/collections');
    final payload = response.data as Map<String, dynamic>;
    return (payload['data'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => CollectionSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PaginatedArtworks> getSavedArtworks({
    String? collectionName,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/social/collections/artworks',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (collectionName != null && collectionName.trim().isNotEmpty)
          'collectionName': collectionName.trim(),
      },
    );

    return PaginatedArtworks.fromJson(response.data as Map<String, dynamic>);
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class CollectionSummary {
  const CollectionSummary({required this.name, required this.itemsCount});

  final String name;
  final int itemsCount;

  factory CollectionSummary.fromJson(Map<String, dynamic> json) {
    final rawCount = json['itemsCount'];
    final count = rawCount is int
        ? rawCount
        : int.tryParse(rawCount?.toString() ?? '0') ?? 0;

    return CollectionSummary(
      name: (json['name'] ?? 'Favorites').toString(),
      itemsCount: count,
    );
  }
}

class ArtworkCommentItem {
  const ArtworkCommentItem({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String content;
  final DateTime createdAt;

  factory ArtworkCommentItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return ArtworkCommentItem(
      id: (json['id'] ?? '').toString(),
      userId: (user['id'] ?? '').toString(),
      userName: (user['name'] ?? 'Unknown').toString(),
      userAvatarUrl: user['avatarUrl']?.toString(),
      content: (json['content'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
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
