import 'package:dio/dio.dart';
import '../api_client.dart';

class NotificationsService {
  late final Dio _dio = ApiClient.instance;

  Future<PaginatedNotifications> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/social/notifications',
      queryParameters: {'page': page, 'limit': limit},
    );

    return PaginatedNotifications.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get('/social/notifications/unread-count');
    final payload = response.data as Map<String, dynamic>;
    final value = payload['unreadCount'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> markAsRead(String notificationId) async {
    await _dio.patch('/social/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch('/social/notifications/read-all');
  }
}

class PaginatedNotifications {
  PaginatedNotifications({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<AppNotificationItem> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory PaginatedNotifications.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? const {};
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return PaginatedNotifications(
      data: (json['data'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => AppNotificationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: parseInt(pagination['page']),
      limit: parseInt(pagination['limit']),
      total: parseInt(pagination['total']),
      totalPages: parseInt(pagination['totalPages']),
    );
  }
}

class AppNotificationItem {
  AppNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.actorName,
    this.actorAvatarUrl,
    this.artworkId,
    this.artworkTitle,
    this.artworkImageUrl,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? actorName;
  final String? actorAvatarUrl;
  final String? artworkId;
  final String? artworkTitle;
  final String? artworkImageUrl;

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    final actor = json['actorUser'] as Map<String, dynamic>?;
    final artwork = json['artwork'] as Map<String, dynamic>?;

    return AppNotificationItem(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      isRead: json['isRead'] as bool? ?? false,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      actorName: actor?['name']?.toString(),
      actorAvatarUrl: actor?['avatarUrl']?.toString(),
      artworkId: artwork?['id']?.toString(),
      artworkTitle: artwork?['title']?.toString(),
      artworkImageUrl: artwork?['imageUrl']?.toString(),
    );
  }
}
