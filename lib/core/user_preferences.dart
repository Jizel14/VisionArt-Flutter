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
  });

  final List<String> subjects;
  final List<String> styles;
  final List<String> colors;
  final String? mood;
  final int complexity;
  final PreferencePermissions permissions;
  final bool onboardingComplete;

  UserPreferences copyWith({
    List<String>? subjects,
    List<String>? styles,
    List<String>? colors,
    String? mood,
    int? complexity,
    PreferencePermissions? permissions,
    bool? onboardingComplete,
  }) {
    return UserPreferences(
      subjects: subjects ?? this.subjects,
      styles: styles ?? this.styles,
      colors: colors ?? this.colors,
      mood: mood ?? this.mood,
      complexity: complexity ?? this.complexity,
      permissions: permissions ?? this.permissions,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
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
