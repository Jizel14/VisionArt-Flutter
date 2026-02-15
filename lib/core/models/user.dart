class User {
  User({
    required this.id,
    required this.email,
    required this.name,
    this.bio,
    this.avatarUrl,
    this.phoneNumber,
    this.website,
  });

  final String id;
  final String email;
  final String name;
  final String? bio;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? website;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      website: json['website'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (website != null) 'website': website,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? bio,
    String? avatarUrl,
    String? phoneNumber,
    String? website,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
    );
  }
}
