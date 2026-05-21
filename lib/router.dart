import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth/auth_provider.dart';
import 'screens/dashboard.dart';
import 'screens/design_system.dart';
import 'screens/keywords/keyword_editor.dart';
import 'screens/keywords/keywords_list.dart';
import 'screens/posts/post_editor.dart';
import 'screens/posts/posts_list.dart';
import 'screens/notifications.dart';
import 'screens/sections/section_editor.dart';
import 'screens/sections/sections_list.dart';
import 'screens/skills/skill_editor.dart';
import 'screens/skills/skills_list.dart';
import 'screens/projects/project_editor.dart';
import 'screens/projects/projects_list.dart';
import 'screens/sign_in.dart';
import 'screens/splash.dart';
import 'screens/stub_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      // Still bootstrapping from secure storage.
      if (auth.isLoading) return '/splash';

      final token = auth.value;
      final isSignedIn = token != null && token.isNotEmpty;
      final atSignIn = state.matchedLocation == '/sign-in';
      final atSplash = state.matchedLocation == '/splash';

      if (!isSignedIn && !atSignIn) return '/sign-in';
      if (isSignedIn && (atSignIn || atSplash)) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
      GoRoute(
        path: '/projects',
        builder: (_, __) => const ProjectsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, __) => const ProjectEditorScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                ProjectEditorScreen(id: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: '/skills',
        builder: (_, __) => const SkillsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, __) => const SkillEditorScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                SkillEditorScreen(id: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: '/posts',
        builder: (_, __) => const PostsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, __) => const PostEditorScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                PostEditorScreen(id: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: '/keywords',
        builder: (_, __) => const KeywordsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, __) => const KeywordEditorScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                KeywordEditorScreen(id: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: '/sections',
        builder: (_, __) => const SectionsListScreen(),
        routes: [
          GoRoute(
            path: ':name',
            builder: (_, state) =>
                SectionEditorScreen(name: state.pathParameters['name']!),
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(path: '/search', builder: (_, __) => Stubs.search),
      GoRoute(path: '/settings', builder: (_, __) => Stubs.settings),
      GoRoute(
          path: '/design-system',
          builder: (_, __) => const DesignSystemScreen()),
    ],
  );
});

/// Bridges Riverpod's auth state into go_router's Listenable contract.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}
