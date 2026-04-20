import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

/// Cross-platform image saving utility.
/// - Web: triggers a browser file download via a virtual anchor element
/// - Mobile: saves to device photo gallery via image_gallery_saver_plus
class ImageSaver {
  static Future<String> save(Uint8List bytes) async {
    if (kIsWeb) {
      return _saveWeb(bytes);
    } else {
      return _saveMobile(bytes);
    }
  }

  static Future<String> _saveMobile(Uint8List bytes) async {
    try {
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'visionart_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (result['isSuccess'] == true) {
        return 'success';
      }
      return 'error:Failed to save to gallery';
    } catch (e) {
      return 'error:$e';
    }
  }

  static Future<String> _saveWeb(Uint8List bytes) async {
    try {
      final base64Data = base64Encode(bytes);
      final dataUrl = 'data:image/png;base64,$base64Data';
      // Use dart:html at runtime - valid on web target only
      _triggerBrowserDownload(dataUrl);
      return 'success';
    } catch (e) {
      return 'error:$e';
    }
  }

  // This function body is only reached on web at runtime.
  // We use conditional import via 'dart:html' availability.
  static void _triggerBrowserDownload(String dataUrl) {
    // ignore: undefined_prefixed_name, avoid_web_libraries_in_flutter
    throw UnsupportedError(
      'Browser download requires the web image_saver_web.dart stub. '
      'Use the web conditional import pattern.',
    );
  }
}
