class StoryUserModel {
  const StoryUserModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isVerified = false,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final bool isVerified;

  factory StoryUserModel.fromJson(Map<String, dynamic> json) {
    return StoryUserModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      isVerified: json['isVerified'] == true,
    );
  }
}

class StoryModel {
  const StoryModel({
    required this.id,
    required this.user,
    required this.mediaUrl,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final StoryUserModel user;
  final String mediaUrl;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime(1970);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime(1970);
    }

    return StoryModel(
      id: (json['id'] ?? '').toString(),
      user: StoryUserModel.fromJson(
        (json['user'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ),
      mediaUrl: (json['mediaUrl'] ?? '').toString(),
      createdAt: parseDate(json['createdAt']),
      expiresAt: parseDate(json['expiresAt']),
    );
  }
}
