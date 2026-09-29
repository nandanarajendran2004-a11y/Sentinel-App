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

  /// Location permission & GPS status messages
  static const String locationPermissionDenied =
      'Location permission denied. Location is required for attendance.';
  static const String locationPermissionPermanentlyDenied =
      'Location permission permanently denied. Please enable it in Settings.';
  static const String locationServiceDisabled =
      'Location is required, please enable GPS';
  static const String mockLocationDetected =
      'Mock location detected - please disable it and try again';
  static const String gpsSignalWeak =
      'GPS signal too weak, move to open sky and retry';
}
