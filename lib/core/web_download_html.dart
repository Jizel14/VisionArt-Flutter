import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';

void downloadWebImage(Uint8List bytes, String filename) {
  final base64Url = base64Encode(bytes);
  final url = 'data:image/png;base64,$base64Url';
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
}
