/// App-wide constants for the Sentinel mobile app.
class AppConstants {
  AppConstants._();

  /// API base URL — configurable via `--dart-define=API_BASE_URL=...`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  /// Secure storage keys
  static const String jwtStorageKey = 'sentinel_jwt';
  static const String userDataKey = 'sentinel_user';

  /// Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  /// QR scan result display duration before auto-navigating back
  static const Duration scanResultDisplayDuration = Duration(seconds: 2);
}
