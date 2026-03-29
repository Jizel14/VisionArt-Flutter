// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FollowStatusModel _$FollowStatusModelFromJson(Map<String, dynamic> json) =>
    FollowStatusModel(
      isFollowing: json['isFollowing'] as bool,
      followerCount: (json['followerCount'] as num).toInt(),
      followingCount: (json['followingCount'] as num).toInt(),
    );

Map<String, dynamic> _$FollowStatusModelToJson(FollowStatusModel instance) =>
    <String, dynamic>{
      'isFollowing': instance.isFollowing,
      'followerCount': instance.followerCount,
      'followingCount': instance.followingCount,
    };

FollowerModel _$FollowerModelFromJson(Map<String, dynamic> json) =>
    FollowerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool,
      followersCount: (json['followersCount'] as num).toInt(),
    );

Map<String, dynamic> _$FollowerModelToJson(FollowerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
      'isVerified': instance.isVerified,
      'followersCount': instance.followersCount,
    };

FollowersListModel _$FollowersListModelFromJson(Map<String, dynamic> json) =>
    FollowersListModel(
      data: (json['data'] as List<dynamic>)
          .map((e) => FollowerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationModel.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$FollowersListModelToJson(FollowersListModel instance) =>
    <String, dynamic>{'data': instance.data, 'pagination': instance.pagination};

PaginationModel _$PaginationModelFromJson(Map<String, dynamic> json) =>
    PaginationModel(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
    );

Map<String, dynamic> _$PaginationModelToJson(PaginationModel instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'totalPages': instance.totalPages,
    };

FollowResponseModel _$FollowResponseModelFromJson(Map<String, dynamic> json) =>
    FollowResponseModel(
      success: json['success'] as bool,
      message: json['message'] as String,
    );

Map<String, dynamic> _$FollowResponseModelToJson(
  FollowResponseModel instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
};
