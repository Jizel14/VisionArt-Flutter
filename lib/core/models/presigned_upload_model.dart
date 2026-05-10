class PresignedUploadModel {
  const PresignedUploadModel({
    required this.key,
    required this.uploadUrl,
    required this.publicUrl,
    required this.expiresInSeconds,
  });

  final String key;
  final String uploadUrl;
  final String publicUrl;
  final int expiresInSeconds;

  factory PresignedUploadModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return PresignedUploadModel(
      key: (json['key'] ?? '').toString(),
      uploadUrl: (json['uploadUrl'] ?? '').toString(),
      publicUrl: (json['publicUrl'] ?? '').toString(),
      expiresInSeconds: parseInt(json['expiresInSeconds']),
    );
  }
}
