import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'follow_model.g.dart';

/// Convert int from JSON - handles both int and string values
int _intFromJson(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

@JsonSerializable()
class FollowStatusModel {
  final bool isFollowing;
  @JsonKey(fromJson: _intFromJson)
  final int followerCount;
  @JsonKey(fromJson: _intFromJson)
  final int followingCount;

  const FollowStatusModel({
    required this.isFollowing,
    required this.followerCount,
    required this.followingCount,
  });

  factory FollowStatusModel.fromJson(Map<String, dynamic> json) =>
      _$FollowStatusModelFromJson(json);

  Map<String, dynamic> toJson() => _$FollowStatusModelToJson(this);
}

@JsonSerializable()
class FollowerModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isVerified;
  @JsonKey(fromJson: _intFromJson)
  final int followersCount;

  const FollowerModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.isVerified,
    required this.followersCount,
  });

  factory FollowerModel.fromJson(Map<String, dynamic> json) =>
      _$FollowerModelFromJson(json);

  Map<String, dynamic> toJson() => _$FollowerModelToJson(this);
}

@JsonSerializable()
class FollowersListModel {
  final List<FollowerModel> data;
  final PaginationModel pagination;

  const FollowersListModel({required this.data, required this.pagination});

  factory FollowersListModel.fromJson(Map<String, dynamic> json) =>
      _$FollowersListModelFromJson(json);

  Map<String, dynamic> toJson() => _$FollowersListModelToJson(this);
}

@JsonSerializable()
class PaginationModel {
  @JsonKey(fromJson: _intFromJson)
  final int page;
  @JsonKey(fromJson: _intFromJson)
  final int limit;
  @JsonKey(fromJson: _intFromJson)
  final int total;
  @JsonKey(fromJson: _intFromJson)
  final int totalPages;

  const PaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) =>
      _$PaginationModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationModelToJson(this);
}

@JsonSerializable()
class FollowResponseModel {
  final bool success;
  final String message;

  const FollowResponseModel({required this.success, required this.message});

  factory FollowResponseModel.fromJson(Map<String, dynamic> json) =>
      _$FollowResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$FollowResponseModelToJson(this);
}
