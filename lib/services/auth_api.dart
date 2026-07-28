import '../config/api_config.dart';
import '../models/api_response.dart';
import 'api_client.dart';
import 'auth_session.dart';
import 'google_auth_service.dart';
import 'profile_api.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    this.username,
    this.email,
    this.role,
    this.isEmailVerified = false,
  });

  final String id;
  final String? username;
  final String? email;
  final String? role;
  final bool isEmailVerified;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      isEmailVerified: json['isEmailVerified'] == true,
    );
  }
}

class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AuthUser user;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      user: AuthUser.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      ),
    );
  }
}

/// Auth service — http://36.253.137.34:8010/swagger
class AuthApi {
  AuthApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final envelope = await _client.post<AuthResult>(
      ApiConfig.authBaseUrl,
      '/api/auth/sso/login',
      auth: false,
      body: {'email': email, 'password': password},
      parse: (raw) => AuthResult.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) throw ApiException(envelope.message ?? 'Login failed');
    await AuthSession.instance.save(
      accessToken: data.accessToken,
      refreshToken: data.refreshToken,
      userId: data.user.id,
      username: data.user.username ?? '',
      email: data.user.email ?? email,
    );
    await _ensureProfile(data.user);
    return data;
  }

  /// Google SSO — `POST /api/auth/sso/google` with `{ google_token }`.
  ///
  /// Tries the ID token first (correct for most backends), then the access
  /// token if the server rejects the ID token.
  Future<AuthResult> loginWithGoogle() async {
    final tokens = await GoogleAuthService.instance.obtainTokens();
    try {
      return await _exchangeGoogleToken(tokens.idToken);
    } on ApiException catch (e) {
      final access = tokens.accessToken?.trim();
      final looksInvalid = e.message.toLowerCase().contains('invalid google');
      if (!looksInvalid || access == null || access.isEmpty) {
        if (looksInvalid) {
          throw ApiException(
            'Invalid Google token. The auth server must verify tokens using '
            'this Web Client ID:\n'
            '${ApiConfig.googleServerClientId}\n'
            'Ask the backend team to update their Google OAuth Client ID '
            '(and secret) to match, then try again.',
          );
        }
        rethrow;
      }
      try {
        return await _exchangeGoogleToken(access);
      } on ApiException catch (_) {
        throw ApiException(
          'Invalid Google token. The auth server must verify tokens using '
          'this Web Client ID:\n'
          '${ApiConfig.googleServerClientId}\n'
          'Ask the backend team to update their Google OAuth Client ID '
          '(and secret) to match, then try again.',
        );
      }
    }
  }

  Future<AuthResult> _exchangeGoogleToken(String googleToken) async {
    final envelope = await _client.post<AuthResult>(
      ApiConfig.authBaseUrl,
      '/api/auth/sso/google',
      auth: false,
      body: {'google_token': googleToken},
      parse: (raw) => AuthResult.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Google sign-in failed');
    }
    await AuthSession.instance.save(
      accessToken: data.accessToken,
      refreshToken: data.refreshToken,
      userId: data.user.id,
      username: data.user.username ?? '',
      email: data.user.email ?? '',
    );
    await _ensureProfile(data.user);
    return data;
  }

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    String? phone,
    String role = 'user',
  }) async {
    final envelope = await _client.post<AuthResult>(
      ApiConfig.authBaseUrl,
      '/api/auth/register',
      auth: false,
      body: {
        'username': username,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      },
      parse: (raw) => AuthResult.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Registration failed');
    }
    await AuthSession.instance.save(
      accessToken: data.accessToken,
      refreshToken: data.refreshToken,
      userId: data.user.id,
      username: data.user.username ?? username,
      email: data.user.email ?? email,
    );
    await _ensureProfile(data.user);
    return data;
  }

  Future<void> _ensureProfile(AuthUser user) async {
    try {
      await ProfileApi().ensureProfile(
        authUserId: user.id,
        username: user.username,
        email: user.email,
        role: user.role ?? 'user',
      );
    } catch (_) {
      // Profile can still be ensured on first ProfileSection load.
    }
  }

  Future<void> logout() async {
    try {
      if (AuthSession.instance.isSignedIn) {
        await _client.post<Object?>(
          ApiConfig.authBaseUrl,
          '/api/auth/logout',
          parse: (_) => null,
        );
      }
    } catch (_) {
      // Still clear local session.
    }
    await GoogleAuthService.instance.signOut();
    await AuthSession.instance.clear();
  }
}
