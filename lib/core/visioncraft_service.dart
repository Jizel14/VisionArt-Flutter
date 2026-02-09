import 'dart:typed_data';

import 'package:flutter_vision_craft/flutter_vision_craft.dart';

import 'app_config.dart';

/// Wrapper around [VisionCraft] for AI image generation in VisionArt.
///
/// Uses API key from [app_config] (set via --dart-define=VISIONCRAFT_API_KEY).
/// Get your key from the VisionCraft Telegram bot: https://t.me/Metimol
class VisionCraftService {
  VisionCraftService({
    String? apiKey,
    String? baseUrl,
  })  : _apiKey = apiKey ?? kVisionCraftApiKey,
        _baseUrl = baseUrl ?? kVisionCraftBaseUrl {
    if (_apiKey.isNotEmpty) {
      _client = VisionCraft(
        apiKey: _apiKey,
        baseUrl: _baseUrl,
      );
    }
  }

  final String _apiKey;
  final String _baseUrl;
  VisionCraft? _client;

  bool get isConfigured => _apiKey.isNotEmpty && _client != null;

  /// Generate an image from a text prompt.
  /// Returns image bytes on success, or null if key is missing / request fails.
  Future<Uint8List?> generateImage({
    required String prompt,
    AIStyles aiStyle = AIStyles.abstract,
    String? negativePrompt,
    bool watermark = false,
    bool nsfwFilter = true,
    AIModels? model,
    Samplers? sampler,
    int? steps,
    int? cfgScale,
  }) async {
    if (!isConfigured) return null;
    try {
      final result = await _client!.generateImage(
        prompt: prompt,
        aiStyle: aiStyle,
        negativePrompt: negativePrompt,
        watermark: watermark,
        nsfw_filter: nsfwFilter,
        model: model,
        sampler: sampler,
        steps: steps,
        cfgScale: cfgScale,
      );
      return result;
    } on Object {
      rethrow;
    }
  }

  /// Fetch image bytes from a URL (e.g. from text2gif).
  Future<Uint8List?> fetchImage(String imageUrl) async {
    if (!isConfigured) return null;
    try {
      return await _client!.fetchImage(imageUrl);
    } on Object {
      return null;
    }
  }

  /// All available styles for the Create UI.
  static List<AIStyles> get availableStyles => AIStyles.values;
}
