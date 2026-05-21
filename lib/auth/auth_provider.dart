import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import 'auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Holds the current API token (or null when signed out).
/// Bootstrapped from secure storage on app start.
class AuthController extends StateNotifier<AsyncValue<String?>> {
  AuthController(this._svc, this._ref) : super(const AsyncValue.loading()) {
    _bootstrap();
  }

  final AuthService _svc;
  final Ref _ref;

  Future<void> _bootstrap() async {
    try {
      final token = await _svc.readToken();
      state = AsyncValue.data(token);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn() async {
    state = const AsyncValue.loading();
    try {
      final githubToken = await _svc.signInWithGitHub();
      final apiToken = await _exchange(githubToken);
      await _svc.writeToken(apiToken);
      state = AsyncValue.data(apiToken);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Swap a GitHub access token for an API bearer token via
  /// `POST /api/auth/exchange`. Server enforces the ADMIN_GITHUB_LOGIN gate.
  Future<String> _exchange(String githubAccessToken) async {
    final dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      headers: {'Accept': 'application/json'},
    ));
    final res = await dio.post<Map<String, dynamic>>(
      '/api/auth/exchange',
      data: {
        'githubAccessToken': githubAccessToken,
        'label': 'mobile',
      },
    );
    final token = res.data?['token'];
    if (token is! String || token.isEmpty) {
      throw StateError('Exchange did not return a token');
    }
    return token;
  }

  /// Bypass for local development — uses a static placeholder token.
  /// Requires the server to allow it (it won't; gated behind real auth).
  void devSignIn() {
    _svc.writeToken('dev-token');
    state = const AsyncValue.data('dev-token');
  }

  Future<void> signOut() async {
    await _svc.signOut();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<String?>>(
        (ref) => AuthController(ref.watch(authServiceProvider), ref));
