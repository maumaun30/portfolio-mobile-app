import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

/// `page_sections` is a jsonb-keyed kv store (one row per section name).
/// The server route `/api/content/[name]` GETs the raw payload and PUTs
/// validate it through the section-specific Zod schema before persisting.
class SectionsApi {
  SectionsApi(this._ref);
  final Ref _ref;

  Future<dynamic> read(String name) async {
    final dio = _ref.read(dioProvider);
    final res = await dio.get('/api/content/$name');
    return res.data;
  }

  /// Returns Zod issues on 400 so the editor can surface field-level errors.
  Future<void> save(String name, dynamic payload) async {
    final dio = _ref.read(dioProvider);
    await dio.put('/api/content/$name', data: payload);
  }
}

final sectionsApiProvider = Provider<SectionsApi>((ref) => SectionsApi(ref));

final sectionPayloadProvider =
    FutureProvider.autoDispose.family<dynamic, String>((ref, name) {
  return ref.watch(sectionsApiProvider).read(name);
});

/// Extracts Zod-style issue list from a Dio error response, when present.
List<String> issuesFromDioError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['issues'] is List) {
      return (data['issues'] as List).map((i) {
        final path = (i['path'] as List?)?.join('.') ?? '';
        final msg = i['message'] ?? '';
        return path.isEmpty ? '$msg' : '$path: $msg';
      }).toList();
    }
    if (data is Map && data['error'] is String) {
      return [data['error'] as String];
    }
    return [e.message ?? 'Request failed'];
  }
  return [e.toString()];
}
