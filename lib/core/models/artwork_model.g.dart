// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artwork_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtworkModel _$ArtworkModelFromJson(Map<String, dynamic> json) => ArtworkModel(
  id: json['id'] as String,
  user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
  title: json['title'] as String?,
  description: json['description'] as String?,
  imageUrl: json['imageUrl'] as String,
  thumbnailUrl: json['thumbnailUrl'] as String?,
  likesCount: _intFromJson(json['likesCount']),
  commentsCount: _intFromJson(json['commentsCount']),
  remixCount: _intFromJson(json['remixCount']),
  isLikedByMe: json['isLikedByMe'] as bool,
  isPublic: json['isPublic'] as bool,
  isNSFW: json['isNSFW'] as bool,
  remixedFrom: json['remixedFrom'] == null
      ? null
      : RemixData.fromJson(json['remixedFrom'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ArtworkModelToJson(ArtworkModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'title': instance.title,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'likesCount': instance.likesCount,
      'commentsCount': instance.commentsCount,
      'remixCount': instance.remixCount,
      'isLikedByMe': instance.isLikedByMe,
      'isPublic': instance.isPublic,
      'isNSFW': instance.isNSFW,
      'remixedFrom': instance.remixedFrom,
      'createdAt': instance.createdAt.toIso8601String(),
    };

RemixData _$RemixDataFromJson(Map<String, dynamic> json) => RemixData(
  id: json['id'] as String,
  user: UserData.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RemixDataToJson(RemixData instance) => <String, dynamic>{
  'id': instance.id,
  'user': instance.user,
};

UserData _$UserDataFromJson(Map<String, dynamic> json) =>
    UserData(name: json['name'] as String);

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
  'name': instance.name,
};
