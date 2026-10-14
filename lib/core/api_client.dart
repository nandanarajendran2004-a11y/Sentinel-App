import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'constants.dart';
import 'secure_storage_service.dart';

/// Singleton Dio HTTP client with JWT auth interceptor and 401 handling.
///
/// On any 401 response, the stored JWT is cleared and the user is navigated
/// back to the login screen via [navigatorKey].
class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio dio;
  final SecureStorageService _storage = SecureStorageService();

  /// Global navigator key — set from [MaterialApp] to enable 401 → login redirect.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  ApiClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('[API] $obj'),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.clearAll();
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Current configured API base URL.
  String get currentBaseUrl => dio.options.baseUrl;

  /// Loads custom base URL from persistent secure storage if previously configured.
  Future<void> init() async {
    try {
      final savedUrl = await _storage.getBaseUrl();
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        dio.options.baseUrl = savedUrl.trim();
        debugPrint('[API] Loaded persisted base URL: ${dio.options.baseUrl}');
      }
    } catch (e) {
      debugPrint('[API] Failed to load persisted base URL: $e');
    }
  }

  /// Normalizes and updates the active Base URL in-memory and in secure storage.
  Future<void> updateBaseUrl(String newUrl) async {
    final normalized = normalizeUrl(newUrl);
    dio.options.baseUrl = normalized;
    await _storage.saveBaseUrl(normalized);
    debugPrint('[API] Base URL updated to: $normalized');
  }

  /// Resets to default compile-time URL and deletes persisted override.
  Future<void> resetBaseUrl() async {
    dio.options.baseUrl = AppConstants.apiBaseUrl;
    await _storage.deleteBaseUrl();
    debugPrint('[API] Base URL reset to default: ${AppConstants.apiBaseUrl}');
  }

  /// Normalizes user-entered URL (adds scheme if missing, removes trailing slashes, appends /api).
  static String normalizeUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return AppConstants.apiBaseUrl;

    // Default to https if no protocol specified
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    // Strip trailing slashes
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    // Ensure /api suffix
    if (!url.endsWith('/api')) {
      url = '$url/api';
    }

    return url;
  }

  /// Tests connectivity to the given URL by pinging the `/health` endpoint.
  Future<({bool success, String message, int latencyMs})> testConnection(
    String targetUrl,
  ) async {
    final normalized = normalizeUrl(targetUrl);
    final stopwatch = Stopwatch()..start();

    try {
      final testDio = Dio(
        BaseOptions(
          baseUrl: normalized,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      final response = await testDio.get('/health');
      stopwatch.stop();

      if (response.statusCode == 200) {
        return (
          success: true,
          message: 'Connected successfully (HTTP 200 OK)',
          latencyMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        return (
          success: false,
          message: 'Server returned HTTP ${response.statusCode}',
          latencyMs: stopwatch.elapsedMilliseconds,
        );
      }
    } on DioException catch (e) {
      stopwatch.stop();
      String message = 'Connection failed';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Connection timed out';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Could not reach server. Verify Ngrok tunnel is online.';
      } else if (e.response != null) {
        message = 'Server error HTTP ${e.response?.statusCode}';
      }
      return (
        success: false,
        message: message,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return (
        success: false,
        message: 'Error: $e',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
}
