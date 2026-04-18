import 'dart:io';

import 'package:dio/dio.dart';

/// Anonymous image upload via Catbox.moe (no API key).
/// Response body is the image URL as plain text.
class CatboxUploadService {
  CatboxUploadService({final Dio? dio}) : _dio = dio ?? Dio();

  static const String _uploadUrl = 'https://catbox.moe/user/api.php';

  final Dio _dio;

  /// Uploads [file] to Catbox.moe and returns the direct image URL.
  /// Throws on non-200 or empty response.
  Future<String> uploadImage(final File file) async {
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'reqtype': 'fileupload',
      'fileToUpload': await MultipartFile.fromFile(file.path),
    });

    final Response<String> response = await _dio.post<String>(
      _uploadUrl,
      data: formData,
      options: Options(responseType: ResponseType.plain),
    );

    final String? url = response.data?.trim();
    if (url == null || url.isEmpty) {
      throw Exception('Catbox upload failed: empty response');
    }
    return url;
  }
}
