import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/api_config.dart';
import '../models/api_response.dart';

class GoogleAuthTokens {
  const GoogleAuthTokens({required this.idToken, this.accessToken});

  final String idToken;
  final String? accessToken;
}

/// Obtains Google tokens for `POST /api/auth/sso/google`.
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  static const _scopes = <String>[
    'email',
    'profile',
    'openid',
  ];

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;

    final serverClientId = ApiConfig.googleServerClientId.trim();
    final clientId = ApiConfig.googleClientId.trim();

    if (serverClientId.isEmpty &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      throw ApiException(
        'Google Sign-In is not configured. Set GOOGLE_SERVER_CLIENT_ID '
        '(Web client ID from Google Cloud Console).',
      );
    }

    await GoogleSignIn.instance.initialize(
      clientId: clientId.isEmpty ? null : clientId,
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
    _initialized = true;
  }

  /// Interactive Google account picker → ID token (+ optional access token).
  Future<GoogleAuthTokens> obtainTokens() async {
    await ensureInitialized();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw ApiException(
        'Google Sign-In is not supported on this platform. '
        'Use Android, iOS, or Web.',
      );
    }

    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: _scopes,
      );
      final idToken = account.authentication.idToken?.trim() ?? '';
      if (idToken.isEmpty) {
        throw ApiException(
          'Google did not return an ID token. Confirm GOOGLE_SERVER_CLIENT_ID '
          'is your Web OAuth client ID.',
        );
      }

      String? accessToken;
      try {
        final authz = await account.authorizationClient.authorizationForScopes(
          _scopes,
        );
        accessToken = authz?.accessToken;
        if (accessToken == null || accessToken.isEmpty) {
          final prompted =
              await account.authorizationClient.authorizeScopes(_scopes);
          accessToken = prompted.accessToken;
        }
      } catch (_) {
        // ID token alone is enough for most backends.
      }

      return GoogleAuthTokens(idToken: idToken, accessToken: accessToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw ApiException('Google sign-in canceled');
      }
      final detail = (e.description ?? e.toString()).toLowerCase();
      if (detail.contains('developer') ||
          detail.contains('console') ||
          detail.contains('10:') ||
          e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw ApiException(
          'Google Developer Console is not set up correctly. '
          'Create a Web application OAuth client (not Android) and paste '
          'that Client ID into the app. Android client alone is not enough.',
        );
      }
      throw ApiException(e.description ?? e.toString());
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Local session clear still proceeds.
    }
  }
}
