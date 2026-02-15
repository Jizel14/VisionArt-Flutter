/// Models for User Preferences
/// Mirrors the backend UserPreferences entity structure

class UserPreferences {
  UserPreferences({
    this.id,
    // Artistic
    this.favoriteStyles = const [],
    this.favoriteColors = const [],
    this.preferredMood,
    this.artComplexity = 'moderate',
    // Context
    this.enableLocationContext = false,
    this.enableWeatherContext = false,
    this.enableCalendarContext = false,
    this.enableMusicContext = false,
    this.enableTimeContext = true,
    this.locationPrecision = 'city',
    // Generation
    this.defaultResolution = '1024x1024',
    this.defaultAspectRatio = 'square',
    this.enableNSFWFilter = true,
    this.generationQuality = 'balanced',
    // UI/UX
    this.preferredLanguage = 'fr',
    this.theme = 'auto',
    this.notificationsEnabled = true,
    this.emailNotificationsEnabled = false,
    // Privacy
    this.dataRetentionPeriod = 365,
    this.allowDataForTraining = true,
    this.shareGenerationsPublicly = false,
    // Timestamps
    this.createdAt,
    this.updatedAt,
    this.lastStyleUpdate,
  });

  /// Unique identifier
  final String? id;

  /// Artistic preferences
  final List<String> favoriteStyles;
  final List<String> favoriteColors;
  final String? preferredMood;
  final String artComplexity;

  /// Context permissions (GDPR-compliant, all opt-in by default)
  final bool enableLocationContext;
  final bool enableWeatherContext;
  final bool enableCalendarContext;
  final bool enableMusicContext;
  final bool enableTimeContext;
  final String locationPrecision;

  /// Generation preferences
  final String defaultResolution;
  final String defaultAspectRatio;
  final bool enableNSFWFilter;
  final String generationQuality;

  /// UI/UX preferences
  final String preferredLanguage;
  final String theme;
  final bool notificationsEnabled;
  final bool emailNotificationsEnabled;

  /// Privacy settings
  final int? dataRetentionPeriod;
  final bool allowDataForTraining;
  final bool shareGenerationsPublicly;

  /// Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastStyleUpdate;

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'favoriteStyles': favoriteStyles,
      'favoriteColors': favoriteColors,
      'preferredMood': preferredMood,
      'artComplexity': artComplexity,
      'enableLocationContext': enableLocationContext,
      'enableWeatherContext': enableWeatherContext,
      'enableCalendarContext': enableCalendarContext,
      'enableMusicContext': enableMusicContext,
      'enableTimeContext': enableTimeContext,
      'locationPrecision': locationPrecision,
      'defaultResolution': defaultResolution,
      'defaultAspectRatio': defaultAspectRatio,
      'enableNSFWFilter': enableNSFWFilter,
      'generationQuality': generationQuality,
      'preferredLanguage': preferredLanguage,
      'theme': theme,
      'notificationsEnabled': notificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'dataRetentionPeriod': dataRetentionPeriod,
      'allowDataForTraining': allowDataForTraining,
      'shareGenerationsPublicly': shareGenerationsPublicly,
    };
  }

  /// Create from JSON response from API
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      id: json['id'] as String?,
      favoriteStyles: List<String>.from(json['favoriteStyles'] as List? ?? []),
      favoriteColors: List<String>.from(json['favoriteColors'] as List? ?? []),
      preferredMood: json['preferredMood'] as String?,
      artComplexity: json['artComplexity'] as String? ?? 'moderate',
      enableLocationContext: json['enableLocationContext'] as bool? ?? false,
      enableWeatherContext: json['enableWeatherContext'] as bool? ?? false,
      enableCalendarContext: json['enableCalendarContext'] as bool? ?? false,
      enableMusicContext: json['enableMusicContext'] as bool? ?? false,
      enableTimeContext: json['enableTimeContext'] as bool? ?? true,
      locationPrecision: json['locationPrecision'] as String? ?? 'city',
      defaultResolution: json['defaultResolution'] as String? ?? '1024x1024',
      defaultAspectRatio: json['defaultAspectRatio'] as String? ?? 'square',
      enableNSFWFilter: json['enableNSFWFilter'] as bool? ?? true,
      generationQuality: json['generationQuality'] as String? ?? 'balanced',
      preferredLanguage: json['preferredLanguage'] as String? ?? 'fr',
      theme: json['theme'] as String? ?? 'auto',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      emailNotificationsEnabled:
          json['emailNotificationsEnabled'] as bool? ?? false,
      dataRetentionPeriod: json['dataRetentionPeriod'] as int? ?? 365,
      allowDataForTraining: json['allowDataForTraining'] as bool? ?? true,
      shareGenerationsPublicly:
          json['shareGenerationsPublicly'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      lastStyleUpdate: json['lastStyleUpdate'] != null
          ? DateTime.parse(json['lastStyleUpdate'] as String)
          : null,
    );
  }

  /// Create a copy with some fields replaced
  UserPreferences copyWith({
    String? id,
    List<String>? favoriteStyles,
    List<String>? favoriteColors,
    String? preferredMood,
    String? artComplexity,
    bool? enableLocationContext,
    bool? enableWeatherContext,
    bool? enableCalendarContext,
    bool? enableMusicContext,
    bool? enableTimeContext,
    String? locationPrecision,
    String? defaultResolution,
    String? defaultAspectRatio,
    bool? enableNSFWFilter,
    String? generationQuality,
    String? preferredLanguage,
    String? theme,
    bool? notificationsEnabled,
    bool? emailNotificationsEnabled,
    int? dataRetentionPeriod,
    bool? allowDataForTraining,
    bool? shareGenerationsPublicly,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastStyleUpdate,
  }) {
    return UserPreferences(
      id: id ?? this.id,
      favoriteStyles: favoriteStyles ?? this.favoriteStyles,
      favoriteColors: favoriteColors ?? this.favoriteColors,
      preferredMood: preferredMood ?? this.preferredMood,
      artComplexity: artComplexity ?? this.artComplexity,
      enableLocationContext:
          enableLocationContext ?? this.enableLocationContext,
      enableWeatherContext: enableWeatherContext ?? this.enableWeatherContext,
      enableCalendarContext:
          enableCalendarContext ?? this.enableCalendarContext,
      enableMusicContext: enableMusicContext ?? this.enableMusicContext,
      enableTimeContext: enableTimeContext ?? this.enableTimeContext,
      locationPrecision: locationPrecision ?? this.locationPrecision,
      defaultResolution: defaultResolution ?? this.defaultResolution,
      defaultAspectRatio: defaultAspectRatio ?? this.defaultAspectRatio,
      enableNSFWFilter: enableNSFWFilter ?? this.enableNSFWFilter,
      generationQuality: generationQuality ?? this.generationQuality,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      dataRetentionPeriod: dataRetentionPeriod ?? this.dataRetentionPeriod,
      allowDataForTraining: allowDataForTraining ?? this.allowDataForTraining,
      shareGenerationsPublicly:
          shareGenerationsPublicly ?? this.shareGenerationsPublicly,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastStyleUpdate: lastStyleUpdate ?? this.lastStyleUpdate,
    );
  }
}

/// Predefined style options
class StyleOptions {
  static const List<String> availableStyles = [
    'Abstract',
    'Impressionist',
    'Cubist',
    'Surrealist',
    'Realist',
    'Modern',
    'Minimalist',
    'Cyberpunk',
    'Steampunk',
    'Fantasy',
    'Pixel Art',
    'Oil Painting',
    'Watercolor',
    'Digital Art',
    'Anime',
    'Comic',
    'Sketch',
    'Vintage',
  ];

  static const List<String> availableColors = [
    'Warm',
    'Cool',
    'Pastel',
    'Vibrant',
    'Monochrome',
    'Sepia',
    'Neon',
    'Earth Tones',
    'Jewel Tones',
    'Rainbow',
  ];

  static const List<String> availableMoods = [
    'Calm',
    'Energetic',
    'Mysterious',
    'Peaceful',
    'Chaotic',
    'Romantic',
    'Bold',
    'Delicate',
    'Dramatic',
    'Whimsical',
  ];

  static const List<String> complexityLevels = [
    'minimal',
    'moderate',
    'detailed',
  ];

  static const List<String> generations = ['fast', 'balanced', 'quality'];

  static const List<String> languages = ['fr', 'en', 'ar'];

  static const List<String> themes = ['light', 'dark', 'auto'];
}
