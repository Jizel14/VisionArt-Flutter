// Dependency removed: no flutter_vision_craft import needed.

/// Aspect ratios available for art generation.
enum ArtAspectRatio {
  square,
  portrait,
  landscape,
  widescreen,
}

extension ArtAspectRatioExt on ArtAspectRatio {
  String get label {
    switch (this) {
      case ArtAspectRatio.square:
        return '1:1';
      case ArtAspectRatio.portrait:
        return '2:3';
      case ArtAspectRatio.landscape:
        return '3:2';
      case ArtAspectRatio.widescreen:
        return '16:9';
    }
  }

  String get icon {
    switch (this) {
      case ArtAspectRatio.square:
        return '⬜';
      case ArtAspectRatio.portrait:
        return '📱';
      case ArtAspectRatio.landscape:
        return '🖼️';
      case ArtAspectRatio.widescreen:
        return '🎬';
    }
  }
}

/// Visual style options in step 2 with display info.
class VisualStyleOption {
  const VisualStyleOption({
    required this.label,
    required this.emoji,
    required this.description,
    required this.styleName,
    this.negativePromptHint = '',
  });

  final String label;
  final String emoji;
  final String description;
  final String styleName;
  final String negativePromptHint;
}

/// The 3 curated visual styles available to the user.
const List<VisualStyleOption> kVisualStyles = [
  VisualStyleOption(
    label: 'Anime',
    emoji: '🎌',
    description: 'Japanese anime, vivid & expressive',
    styleName: 'anime',
    negativePromptHint: 'realistic, photography, 3d render',
  ),
  VisualStyleOption(
    label: 'Ghibli',
    emoji: '🌿',
    description: 'Studio Ghibli soft, dreamy magic',
    styleName: 'dreamescape',
    negativePromptHint: 'dark, gritty, photorealistic, harsh shadows',
  ),
  VisualStyleOption(
    label: 'Sketch',
    emoji: '✏️',
    description: 'Clean pencil lines, hand-drawn feel',
    styleName: 'lineArt',
    negativePromptHint: 'color, photo-realistic, 3d, blurry',
  ),
];

/// The full art creation configuration gathered from both steps.
class ArtCreationConfig {
  ArtCreationConfig({
    this.prompt = '',
    this.negativePrompt = '',
    this.useNegativePrompt = false,
    this.selectedVisualStyle,
    this.aspectRatio = ArtAspectRatio.square,
    this.quality = 3,
    this.useUserPersonality = true,
  });

  String prompt;
  String negativePrompt;
  bool useNegativePrompt;
  VisualStyleOption? selectedVisualStyle;
  ArtAspectRatio aspectRatio;
  int quality; // 1–5
  bool useUserPersonality;

  /// Build an intelligent enhanced prompt combining user input + personality.
  String buildEnhancedPrompt({
    List<String> userSubjects = const [],
    List<String> userStyles = const [],
    List<String> userColors = const [],
    String? userMood,
    int? userComplexity,
  }) {
    final parts = <String>[prompt.trim()];

    if (useUserPersonality) {
      // Inject user art personality
      if (userColors.isNotEmpty && !_promptContains(prompt, userColors)) {
        parts.add('color palette: ${userColors.join(', ')}');
      }
      if (userMood != null && userMood.isNotEmpty) {
        parts.add('${userMood.toLowerCase()} mood');
      }
      final complexity = userComplexity ?? 3;
      if (complexity >= 4) {
        parts.add('highly detailed, intricate');
      } else if (complexity <= 2) {
        parts.add('simple, clean');
      }
    }

    // Quality boost words
    final q = quality;
    if (q >= 4) {
      parts.add('masterpiece, best quality, ultra-detailed, 8k');
    } else if (q >= 3) {
      parts.add('high quality, detailed');
    }

    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  /// Build the effective negative prompt.
  String buildNegativePrompt({String? styleHint}) {
    final base = <String>[
      'deformed', 'bad anatomy', 'blurry', 'low quality', 'watermark', 'text',
    ];
    if (useNegativePrompt && negativePrompt.trim().isNotEmpty) {
      base.addAll(negativePrompt.trim().split(',').map((s) => s.trim()));
    }
    if (styleHint != null && styleHint.isNotEmpty) {
      base.addAll(styleHint.split(',').map((s) => s.trim()));
    }
    return base.toSet().join(', ');
  }

  bool _promptContains(String prompt, List<String> keywords) {
    final lower = prompt.toLowerCase();
    return keywords.any((k) => lower.contains(k.toLowerCase()));
  }
}
