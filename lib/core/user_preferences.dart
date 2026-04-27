/// User art preferences (subjects, styles, colors, mood, complexity, permissions).
class UserPreferences {
  UserPreferences({
    this.subjects = const [],
    this.styles = const [],
    this.colors = const [],
    this.mood,
    this.complexity = 3,
    this.permissions = const PreferencePermissions(),
    this.onboardingComplete = false,
    this.playlistUrls = const [],
    this.playlists = const [],
  });

  final List<String> subjects;
  final List<String> styles;
  final List<String> colors;
  final String? mood;
  final int complexity;
  final PreferencePermissions permissions;
  final bool onboardingComplete;
  final List<String> playlistUrls;
  final List<SonicPlaylist> playlists;

  UserPreferences copyWith({
    List<String>? subjects,
    List<String>? styles,
    List<String>? colors,
    String? mood,
    int? complexity,
    PreferencePermissions? permissions,
    bool? onboardingComplete,
    List<String>? playlistUrls,
    List<SonicPlaylist>? playlists,
  }) {
    return UserPreferences(
      subjects: subjects ?? this.subjects,
      styles: styles ?? this.styles,
      colors: colors ?? this.colors,
      mood: mood ?? this.mood,
      complexity: complexity ?? this.complexity,
      permissions: permissions ?? this.permissions,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      playlistUrls: playlistUrls ?? this.playlistUrls,
      playlists: playlists ?? this.playlists,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjects': subjects,
      'styles': styles,
      'colors': colors,
      'mood': mood,
      'complexity': complexity,
      'permissions': permissions.toJson(),
      'onboardingComplete': onboardingComplete,
      'playlistUrls': playlistUrls,
      'playlists': playlists.map((e) => e.toJson()).toList(),
    };
  }

  static UserPreferences fromJson(Map<String, dynamic>? json) {
    if (json == null) return UserPreferences();
    return UserPreferences(
      subjects: (json['subjects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      styles: (json['styles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      colors: (json['colors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      mood: json['mood'] as String?,
      complexity: (json['complexity'] as num?)?.toInt() ?? 3,
      permissions: PreferencePermissions.fromJson(json['permissions'] as Map<String, dynamic>?),
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      playlistUrls: (json['playlistUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      playlists: (json['playlists'] as List<dynamic>?)
              ?.map((e) => SonicPlaylist.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SonicPlaylist {
  SonicPlaylist({
    required this.id,
    required this.name,
    required this.urls,
    this.mood,
    this.styles = const [],
    this.colors = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final List<String> urls;
  final String? mood;
  final List<String> styles;
  final List<String> colors;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'urls': urls,
      'mood': mood,
      'styles': styles,
      'colors': colors,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static SonicPlaylist fromJson(Map<String, dynamic> json) {
    return SonicPlaylist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Universe',
      urls: (json['urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      mood: json['mood'] as String?,
      styles: (json['styles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      colors: (json['colors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  SonicPlaylist copyWith({
    String? id,
    String? name,
    List<String>? urls,
    String? mood,
    List<String>? styles,
    List<String>? colors,
    DateTime? createdAt,
  }) {
    return SonicPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      urls: urls ?? this.urls,
      mood: mood ?? this.mood,
      styles: styles ?? this.styles,
      colors: colors ?? this.colors,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PreferencePermissions {
  const PreferencePermissions({
    this.location = false,
    this.weather = false,
    this.music = false,
    this.calendar = false,
    this.timeOfDay = false,
    this.gallery = false,
  });

  final bool location;
  final bool weather;
  final bool music;
  final bool calendar;
  final bool timeOfDay;
  final bool gallery;

  PreferencePermissions copyWith({
    bool? location,
    bool? weather,
    bool? music,
    bool? calendar,
    bool? timeOfDay,
    bool? gallery,
  }) {
    return PreferencePermissions(
      location: location ?? this.location,
      weather: weather ?? this.weather,
      music: music ?? this.music,
      calendar: calendar ?? this.calendar,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      gallery: gallery ?? this.gallery,
    );
  }

  Map<String, dynamic> toJson() => {
        'location': location,
        'weather': weather,
        'music': music,
        'calendar': calendar,
        'timeOfDay': timeOfDay,
        'gallery': gallery,
      };

  static PreferencePermissions fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PreferencePermissions();
    return PreferencePermissions(
      location: json['location'] as bool? ?? false,
      weather: json['weather'] as bool? ?? false,
      music: json['music'] as bool? ?? false,
      calendar: json['calendar'] as bool? ?? false,
      timeOfDay: json['timeOfDay'] as bool? ?? false,
      gallery: json['gallery'] as bool? ?? false,
    );
  }
}
