import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/keyword.dart';
import 'api_client.dart';

class GeneratedPostResult {
  const GeneratedPostResult({
    required this.slug,
    required this.url,
    required this.keyword,
  });
  final String slug;
  final String url;
  final String keyword;
}

class KeywordsApi {
  KeywordsApi(this._ref);
  final Ref _ref;

  Future<List<Keyword>> list() async {
    final dio = _ref.read(dioProvider);
    final res = await dio.get<List<dynamic>>('/api/keywords');
    return (res.data ?? [])
        .map((e) => Keyword.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Keyword> create({required String term, bool enabled = true}) async {
    final dio = _ref.read(dioProvider);
    final res = await dio.post(
      '/api/keywords',
      data: {'term': term, 'enabled': enabled},
    );
    return Keyword.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Keyword> update(
    String id, {
    String? term,
    bool? enabled,
  }) async {
    final dio = _ref.read(dioProvider);
    final res = await dio.patch(
      '/api/keywords/$id',
      data: {
        if (term != null) 'term': term,
        if (enabled != null) 'enabled': enabled,
      },
    );
    return Keyword.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    final dio = _ref.read(dioProvider);
    await dio.delete('/api/keywords/$id');
  }

  /// Fire `/api/blog/generate`. `keywordId` null → server picks the next one.
  Future<GeneratedPostResult> generate({String? keywordId}) async {
    final dio = _ref.read(dioProvider);
    final res = await dio.post<Map<String, dynamic>>(
      '/api/blog/generate',
      data: keywordId != null ? {'keywordId': keywordId} : {},
      options: dio.options.copyWith(
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );
    final data = res.data ?? const {};
    return GeneratedPostResult(
      slug: data['slug'] as String? ?? '',
      url: data['url'] as String? ?? '',
      keyword: data['keyword'] as String? ?? '',
    );
  }
}

final keywordsApiProvider = Provider<KeywordsApi>((ref) => KeywordsApi(ref));

final keywordsListProvider = FutureProvider.autoDispose<List<Keyword>>((ref) {
  return ref.watch(keywordsApiProvider).list();
});

final keywordByIdProvider =
    FutureProvider.autoDispose.family<Keyword, String>((ref, id) async {
  final list = await ref.watch(keywordsListProvider.future);
  return list.firstWhere((k) => k.id == id);
});
