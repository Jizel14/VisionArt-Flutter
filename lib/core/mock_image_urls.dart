/// Curated mock image URLs for feed and marketplace — AI / abstract / digital art.
/// Uses Unsplash (free to use, no attribution required).
/// See: https://unsplash.com/license
abstract class MockImageUrls {
  static const List<String> aiArtImages = [
    'https://images.unsplash.com/photo-1558591710-4b4a1ae0f04d?w=600&q=80',
    'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=600&q=80',
    'https://images.unsplash.com/photo-1557672172-298e090bd0f1?w=600&q=80',
    'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=600&q=80',
    'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=600&q=80',
    'https://images.unsplash.com/photo-1536924940846-227afb31e2a5?w=600&q=80',
    'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&q=80',
    'https://images.unsplash.com/photo-1561214115-f2f134cc4912?w=600&q=80',
  ];

  /// Returns a URL by index (wraps around).
  static String at(int index) {
    return aiArtImages[index % aiArtImages.length];
  }
}
