import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// GitHub OAuth via PKCE.
///
/// The portfolio API is currently NextAuth-cookie-based, so this flow
/// expects a small endpoint on the Next.js side that exchanges a GitHub
/// access token for a long-lived API token (see README.md). For local dev
/// the wiring is in place but auth is gated behind a debug "skip" button
/// on the sign-in screen until that endpoint exists.
class AuthService {
  AuthService();

  static const _githubAuthEndpoint = 'https://github.com/login/oauth/authorize';
  static const _githubTokenEndpoint =
      'https://github.com/login/oauth/access_token';

  // TODO: move to .env / --dart-define
  static const _clientId = String.fromEnvironment('GITHUB_CLIENT_ID');
  static const _redirectUri =
      String.fromEnvironment('OAUTH_REDIRECT_URI',
          defaultValue: 'portfolio-admin://oauth/callback');

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = 'api_token';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> signOut() => _storage.delete(key: _tokenKey);

  /// Run the OAuth dance. Returns the GitHub access token on success.
  /// The caller is responsible for swapping it for an API token via the
  /// backend exchange endpoint (not yet implemented on the API side).
  Future<String> signInWithGitHub() async {
    if (_clientId.isEmpty) {
      throw StateError(
        'GITHUB_CLIENT_ID is not set. Pass via --dart-define=GITHUB_CLIENT_ID=...',
      );
    }
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _clientId,
        _redirectUri,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: _githubAuthEndpoint,
          tokenEndpoint: _githubTokenEndpoint,
        ),
        scopes: const ['read:user'],
      ),
    );
    final token = result.accessToken;
    if (token == null) throw StateError('GitHub returned no access token');
    return token;
  }
}
