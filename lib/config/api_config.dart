/// Base URLs for Innovator backend services.
///
/// Chat Swagger: http://36.253.137.34:8014/swagger/index.html
/// Auth Swagger: http://36.253.137.34:8010/swagger/index.html
/// Profile Swagger: http://36.253.137.34:8011/swagger/index.html
/// Search Swagger: http://36.253.137.34:8015/swagger/index.html
class ApiConfig {
  ApiConfig._();

  static const authBaseUrl = 'http://36.253.137.34:8010';
  static const chatBaseUrl = 'http://36.253.137.34:8014';
  static const profileBaseUrl = 'http://36.253.137.34:8011';
  static const searchBaseUrl = 'http://36.253.137.34:8015';

  static const connectTimeout = Duration(seconds: 20);

  /// Google Cloud **Web** OAuth client ID (used as `serverClientId`).
  /// From Firebase project `innovator-250f8` (`client_type: 3`).
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: googleServerClientIdFallback,
  );

  /// Optional iOS/macOS/Web *app* client ID.
  /// Leave empty on Android — Play Services uses package name + SHA-1.
  static const googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: googleClientIdFallback,
  );

  /// Web client ID from google-services.json (client_type 3).
  static const googleServerClientIdFallback =
      '565447947765-2n94vokrmnc8p6c8k4c8as3krqc8qmgk.apps.googleusercontent.com';

  static const googleClientIdFallback = '';
}
