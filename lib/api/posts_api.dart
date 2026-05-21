import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import 'api_client.dart';

class PostsApi {
  PostsApi(this._ref);
  final Ref _ref;

  Future<List<Post>> list({PostType? type}) async {
    final dio = _ref.read(dioProvider);
    final res = await dio.get<List<dynamic>>(
      '/api/posts',
      queryParameters: type == null ? null : {'type': type.apiValue},
    );
    return (res.data ?? [])
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Post> create(Map<String, dynamic> payload) async {
    final dio = _ref.read(dioProvider);
    final res = await dio.post('/api/posts', data: payload);
    return Post.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Post> update(String id, Map<String, dynamic> payload) async {
    final dio = _ref.read(dioProvider);
    final res = await dio.patch('/api/posts/$id', data: payload);
    return Post.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    final dio = _ref.read(dioProvider);
    await dio.delete('/api/posts/$id');
  }
}

final postsApiProvider = Provider<PostsApi>((ref) => PostsApi(ref));

final postsListProvider = FutureProvider.autoDispose<List<Post>>((ref) {
  return ref.watch(postsApiProvider).list();
});

final postByIdProvider =
    FutureProvider.autoDispose.family<Post, String>((ref, id) async {
  final list = await ref.watch(postsListProvider.future);
  return list.firstWhere((p) => p.id == id);
});
