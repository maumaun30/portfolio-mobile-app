import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'keywords_api.dart';
import 'posts_api.dart';
import 'projects_api.dart';
import 'skills_api.dart';

class DashboardStats {
  const DashboardStats({
    required this.projects,
    required this.skills,
    required this.posts,
    required this.keywords,
  });
  final int projects;
  final int skills;
  final int posts;
  final int keywords;
}

/// Cheap "real" dashboard counts: parallel reads of the four list providers
/// the app already uses elsewhere. Reuses their caches when available.
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final results = await Future.wait([
    ref.watch(projectsApiProvider).list(),
    ref.watch(skillsApiProvider).list(),
    ref.watch(postsApiProvider).list(),
    ref.watch(keywordsApiProvider).list(),
  ]);
  return DashboardStats(
    projects: results[0].length,
    skills: results[1].length,
    posts: results[2].length,
    keywords: results[3].length,
  );
});
