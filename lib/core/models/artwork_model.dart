import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'artwork_model.g.dart';

/// Convert int from JSON - handles both int and string values
int _intFromJson(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

@JsonSerializable()
class ArtworkModel {
  final String id;
  final UserModel user;
  final String? title;
  final String? description;
  final String imageUrl;
  final String? thumbnailUrl;
  @JsonKey(fromJson: _intFromJson)
  final int likesCount;
  @JsonKey(fromJson: _intFromJson)
  final int commentsCount;
  @JsonKey(fromJson: _intFromJson)
  final int remixCount;
  final bool isLikedByMe;
  @JsonKey(defaultValue: false)
  final bool isFollowedByMe;
  final bool isPublic;
  final bool isNSFW;
  final RemixData? remixedFrom;
  final DateTime createdAt;

  const ArtworkModel({
    required this.id,
    required this.user,
    this.title,
    this.description,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.remixCount,
    required this.isLikedByMe,
    this.isFollowedByMe = false,
    required this.isPublic,
    required this.isNSFW,
    this.remixedFrom,
    required this.createdAt,
  });

  factory ArtworkModel.fromJson(Map<String, dynamic> json) =>
      _$ArtworkModelFromJson(json);

  Map<String, dynamic> toJson() => _$ArtworkModelToJson(this);

  ArtworkModel copyWith({
    String? id,
    UserModel? user,
    String? title,
    String? description,
    String? imageUrl,
    String? thumbnailUrl,
    int? likesCount,
    int? commentsCount,
    int? remixCount,
    bool? isLikedByMe,
    bool? isFollowedByMe,
    bool? isPublic,
    bool? isNSFW,
    RemixData? remixedFrom,
    DateTime? createdAt,
  }) {
    return ArtworkModel(
      id: id ?? this.id,
      user: user ?? this.user,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      remixCount: remixCount ?? this.remixCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe,
      isPublic: isPublic ?? this.isPublic,
      isNSFW: isNSFW ?? this.isNSFW,
      remixedFrom: remixedFrom ?? this.remixedFrom,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@JsonSerializable()
class RemixData {
  final String id;
  final UserData user;

  const RemixData({required this.id, required this.user});

  factory RemixData.fromJson(Map<String, dynamic> json) =>
      _$RemixDataFromJson(json);

  Map<String, dynamic> toJson() => _$RemixDataToJson(this);
}

@JsonSerializable()
class UserData {
  final String name;

  const UserData({required this.name});

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);

  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}
