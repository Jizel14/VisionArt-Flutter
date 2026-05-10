import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// Convert int from JSON - handles both int and string values
int _intFromJson(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

@JsonSerializable()
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? bio;
  final String? avatarUrl;
  final bool isVerified;
  final bool isPrivateAccount;
  @JsonKey(fromJson: _intFromJson)
  final int followersCount;
  @JsonKey(fromJson: _intFromJson)
  final int followingCount;
  @JsonKey(fromJson: _intFromJson)
  final int publicGenerationsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    this.avatarUrl,
    required this.isVerified,
    required this.isPrivateAccount,
    required this.followersCount,
    required this.followingCount,
    required this.publicGenerationsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? bio,
    String? avatarUrl,
    bool? isVerified,
    bool? isPrivateAccount,
    int? followersCount,
    int? followingCount,
    int? publicGenerationsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      isPrivateAccount: isPrivateAccount ?? this.isPrivateAccount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      publicGenerationsCount:
          publicGenerationsCount ?? this.publicGenerationsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
