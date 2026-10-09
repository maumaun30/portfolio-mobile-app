import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// GitHub OAuth via PKCE.
///
/// We only run the `authorize` step on-device — the code-for-token swap
/// happens on the Next.js side via `POST /api/auth/exchange`, because
/// GitHub OAuth Apps require `client_secret` even with PKCE and we don't
/// want to ship the secret in the APK.
class AuthService {
  AuthService();

  static const _githubAuthEndpoint = 'https://github.com/login/oauth/authorize';
  static const _githubTokenEndpoint =
      'https://github.com/login/oauth/access_token';

  static const _clientId = String.fromEnvironment('GITHUB_CLIENT_ID');
  static const redirectUri =
      String.fromEnvironment('OAUTH_REDIRECT_URI',
          defaultValue: 'portfolio-admin://oauth/callback');

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = 'api_token';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> signOut() => _storage.delete(key: _tokenKey);

  /// Run the authorize step. Returns `(code, codeVerifier)` to hand to the
  /// backend exchange endpoint.
  Future<({String code, String codeVerifier})> authorizeWithGitHub() async {
    if (_clientId.isEmpty) {
      throw StateError(
        'GITHUB_CLIENT_ID is not set. Pass via --dart-define=GITHUB_CLIENT_ID=...',
      );
    }
    final result = await _appAuth.authorize(
      AuthorizationRequest(
        _clientId,
        redirectUri,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: _githubAuthEndpoint,
          tokenEndpoint: _githubTokenEndpoint,
        ),
        scopes: const ['read:user'],
      ),
    );
    final code = result.authorizationCode;
    final verifier = result.codeVerifier;
    if (code == null || verifier == null) {
      throw StateError('GitHub authorize returned no code/verifier');
    }
    return (code: code, codeVerifier: verifier);
  }
}
