import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import 'api_client.dart';

class ProjectsApi {
  ProjectsApi(this._ref);
  final Ref _ref;

  Future<List<Project>> list() async {
    final dio = _ref.read(dioProvider);
    final res = await dio.get<List<dynamic>>('/api/projects');
    return (res.data ?? [])
        .map((e) => Project.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Project> create(Map<String, dynamic> payload) async {
    final dio = _ref.read(dioProvider);
    final res = await dio.post('/api/projects', data: payload);
    return Project.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Project> update(String id, Map<String, dynamic> payload) async {
    final dio = _ref.read(dioProvider);
    final res = await dio.patch('/api/projects/$id', data: payload);
    return Project.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    final dio = _ref.read(dioProvider);
    await dio.delete('/api/projects/$id');
  }
}

final projectsApiProvider = Provider<ProjectsApi>((ref) => ProjectsApi(ref));

final projectsListProvider = FutureProvider.autoDispose<List<Project>>((ref) {
  return ref.watch(projectsApiProvider).list();
});

final projectByIdProvider =
    FutureProvider.autoDispose.family<Project, String>((ref, id) async {
  final list = await ref.watch(projectsListProvider.future);
  return list.firstWhere((p) => p.id == id);
});
