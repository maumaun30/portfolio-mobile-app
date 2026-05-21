import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_hit.dart';
import 'api_client.dart';

class SearchApi {
  SearchApi(this._ref);
  final Ref _ref;

  Future<List<SearchHit>> query(String q) async {
    final trimmed = q.trim();
    if (trimmed.length < 2) return const [];
    final dio = _ref.read(dioProvider);
    final res = await dio.get<Map<String, dynamic>>(
      '/api/search',
      queryParameters: {'q': trimmed},
    );
    final hits = (res.data?['hits'] as List?) ?? const [];
    return hits
        .map((e) => SearchHit.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final searchApiProvider = Provider<SearchApi>((ref) => SearchApi(ref));
