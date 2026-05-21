import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

class UploadResult {
  const UploadResult({required this.url, required this.pathname});
  final String url;
  final String pathname;
}

class UploadApi {
  UploadApi(this._ref);
  final Ref _ref;

  /// POST /api/upload as multipart/form-data.
  /// `folder` namespaces the blob (`projects`, `posts`, etc.).
  Future<UploadResult> uploadFile({
    required File file,
    String folder = 'uploads',
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final dio = _ref.read(dioProvider);
    final name = file.path.split(RegExp(r'[\\/]')).last;
    final form = FormData.fromMap({
      'folder': folder,
      'file': await MultipartFile.fromFile(file.path, filename: name),
    });

    final res = await dio.post<Map<String, dynamic>>(
      '/api/upload',
      data: form,
      onSendProgress: onProgress,
      cancelToken: cancelToken,
    );
    final data = res.data ?? const {};
    return UploadResult(
      url: data['url'] as String,
      pathname: data['pathname'] as String,
    );
  }
}

final uploadApiProvider = Provider<UploadApi>((ref) => UploadApi(ref));
