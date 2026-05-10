import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../api_client.dart';
import '../models/presigned_upload_model.dart';

class StorageService {
  late final Dio _api = ApiClient.instance;

  final Dio _uploadDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.plain,
      headers: const {},
    ),
  );

  Future<PresignedUploadModel> presignUpload({
    required String contentType,
    String prefix = 'uploads',
    String? fileExt,
  }) async {
    final response = await _api.post(
      '/storage/presign',
      data: {'contentType': contentType, 'prefix': prefix, 'fileExt': fileExt},
    );

    return PresignedUploadModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> uploadBytes({
    required Uint8List bytes,
    required String contentType,
    String prefix = 'uploads',
    String? fileExt,
  }) async {
    final presigned = await presignUpload(
      contentType: contentType,
      prefix: prefix,
      fileExt: fileExt,
    );

    await _uploadDio.put(
      presigned.uploadUrl,
      data: bytes,
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': bytes.length.toString(),
        },
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    final fallbackUrl = presigned.uploadUrl.split('?').first;
    return presigned.publicUrl.isNotEmpty ? presigned.publicUrl : fallbackUrl;
  }
}
