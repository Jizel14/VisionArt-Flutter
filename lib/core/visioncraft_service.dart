import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'app_config.dart';

// ── Enums (previously from flutter_vision_craft package) ─────────────────────

enum AIStyles {
  abstract,
  anime,
  cartoon,
  cyberpunk,
  digitalArt,
  fantasy,
  hyperRealistic,
  impressionism,
  manga,
  oilPainting,
  pixelArt,
  portrait,
  sciFi,
  sketch,
  surrealism,
  watercolor,
}

enum AIModels {
  dreamshaper,
  juggernautXL,
  realvisXL,
  sdXL,
  sdv15,
}

enum Samplers {
  dpmPlusPlus2MAkarasz,
  dpmPlusPlus2M,
  euler,
  eulerA,
  heun,
  lms,
}

// ── VisionCraftService ────────────────────────────────────────────────────────

class VisionCraftService {
  VisionCraftService({String? apiKey, String? baseUrl})
    : _apiKey = apiKey ?? AppConfig.visionCraftApiKey,
      _baseUrl = (baseUrl ?? AppConfig.visionCraftBaseUrl).replaceAll(RegExp(r'/$'), '');

  final String _apiKey;
  final String _baseUrl;

  bool get isConfigured => _apiKey.isNotEmpty;

  Dio get _dio => Dio(BaseOptions(
    baseUrl: _baseUrl,
    headers: {
      'X-API-KEY': _apiKey,
      'Content-Type': 'application/json',
    },
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 90),
    responseType: ResponseType.bytes,
  ));

  /// Generate an image from a text prompt. Returns PNG bytes or null.
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
      final body = <String, dynamic>{
        'prompt': prompt,
        'style': _styleValue(aiStyle),
        'watermark': watermark,
        'nsfw_filter': nsfwFilter,
        if (negativePrompt != null && negativePrompt.isNotEmpty)
          'negative_prompt': negativePrompt,
        if (model != null) 'model': _modelValue(model),
        if (sampler != null) 'sampler': _samplerValue(sampler),
        if (steps != null) 'steps': steps,
        if (cfgScale != null) 'cfg_scale': cfgScale,
      };

      final response = await _dio.post<List<int>>('/generate', data: jsonEncode(body));
      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data!);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Fetch image bytes from a URL.
  Future<Uint8List?> fetchImage(String imageUrl) async {
    if (!isConfigured) return null;
    try {
      final response = await Dio().get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data!);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Analyze a base64-encoded sketch/drawing and return a descriptive prompt.
  Future<String?> analyzeDrawing(String base64Image) async {
    if (!isConfigured) return null;
    try {
      final response = await Dio(BaseOptions(
        baseUrl: _baseUrl,
        headers: {'X-API-KEY': _apiKey, 'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        responseType: ResponseType.json,
      )).post<dynamic>('/analyze', data: jsonEncode({'image': base64Image}));

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map) return data['prompt'] as String?;
        if (data is String) return data;
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// All available styles for the Create UI.
  static List<AIStyles> get availableStyles => AIStyles.values;

  // ── Private helpers ────────────────────────────────────────────────────────

  static String _styleValue(AIStyles s) {
    switch (s) {
      case AIStyles.abstract:       return 'Abstract';
      case AIStyles.anime:          return 'Anime';
      case AIStyles.cartoon:        return 'Cartoon';
      case AIStyles.cyberpunk:      return 'Cyberpunk';
      case AIStyles.digitalArt:     return 'Digital Art';
      case AIStyles.fantasy:        return 'Fantasy';
      case AIStyles.hyperRealistic: return 'Hyper Realistic';
      case AIStyles.impressionism:  return 'Impressionism';
      case AIStyles.manga:          return 'Manga';
      case AIStyles.oilPainting:    return 'Oil Painting';
      case AIStyles.pixelArt:       return 'Pixel Art';
      case AIStyles.portrait:       return 'Portrait';
      case AIStyles.sciFi:          return 'Sci-Fi';
      case AIStyles.sketch:         return 'Sketch';
      case AIStyles.surrealism:     return 'Surrealism';
      case AIStyles.watercolor:     return 'Watercolor';
    }
  }

  static String _modelValue(AIModels m) {
    switch (m) {
      case AIModels.dreamshaper:   return 'dreamshaper';
      case AIModels.juggernautXL:  return 'juggernaut-xl';
      case AIModels.realvisXL:     return 'realvis-xl';
      case AIModels.sdXL:          return 'sdxl';
      case AIModels.sdv15:         return 'sd-v1-5';
    }
  }

  static String _samplerValue(Samplers s) {
    switch (s) {
      case Samplers.dpmPlusPlus2MAkarasz: return 'DPM++ 2M Karras';
      case Samplers.dpmPlusPlus2M:        return 'DPM++ 2M';
      case Samplers.euler:                return 'Euler';
      case Samplers.eulerA:               return 'Euler a';
      case Samplers.heun:                 return 'Heun';
      case Samplers.lms:                  return 'LMS';
    }
  }
}
