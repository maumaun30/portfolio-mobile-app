import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/skill.dart';
import 'api_client.dart';

class SkillsApi {
  SkillsApi(this._ref);
  final Ref _ref;

  Future<List<Skill>> list() async {
    final dio = _ref.read(dioProvider);
    final res = await dio.get<List<dynamic>>('/api/skills');
    return (res.data ?? [])
        .map((e) => Skill.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Skill> create({
    required String slug,
    required String label,
    int sort = 0,
  }) async {
    final dio = _ref.read(dioProvider);
    final res = await dio.post(
      '/api/skills',
      data: {'slug': slug, 'label': label, 'sort': sort},
    );
    return Skill.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Skill> update(
    String id, {
    String? slug,
    String? label,
    int? sort,
  }) async {
    final dio = _ref.read(dioProvider);
    final res = await dio.patch(
      '/api/skills/$id',
      data: {
        if (slug != null) 'slug': slug,
        if (label != null) 'label': label,
        if (sort != null) 'sort': sort,
      },
    );
    return Skill.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    final dio = _ref.read(dioProvider);
    await dio.delete('/api/skills/$id');
  }
}

final skillsApiProvider = Provider<SkillsApi>((ref) => SkillsApi(ref));

final skillsListProvider = FutureProvider.autoDispose<List<Skill>>((ref) {
  return ref.watch(skillsApiProvider).list();
});

final skillByIdProvider =
    FutureProvider.autoDispose.family<Skill, String>((ref, id) async {
  final list = await ref.watch(skillsListProvider.future);
  return list.firstWhere((s) => s.id == id);
});
