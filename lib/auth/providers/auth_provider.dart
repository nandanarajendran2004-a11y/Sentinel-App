import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/api_endpoints.dart';
import '../../core/secure_storage_service.dart';
import '../models/user_model.dart';

/// Central auth state manager.
///
/// Handles login, TOTP verification, token persistence, and logout.
class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  // Temporary token for TOTP flow — not saved to storage until TOTP is done.
  String? _pendingToken;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String? get pendingToken => _pendingToken;

  /// Try to restore a session from stored JWT + user data.
  Future<bool> tryAutoLogin() async {
    final token = await _storage.getToken();
    if (token == null) return false;

    final userData = await _storage.getUserData();
    if (userData == null) {
      await _storage.clearAll();
      return false;
    }

    _user = UserModel.fromJson(userData);
    notifyListeners();
    return true;
  }

  /// Log in with email + password.
  ///
  /// Returns a [LoginResult] indicating what the caller should do next.
  Future<LoginResult> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _api.dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
          'platform': 'mobile',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data);

      // Admin accounts cannot use mobile
      if (user.isAdmin) {
        _setLoading(false);
        return LoginResult.adminBlocked;
      }

      // Manager with TOTP required
      if (user.isManager && user.totpRequired) {
        _pendingToken = user.token ?? data['token']?.toString();
        _user = user;
        _setLoading(false);

        if (!user.totpEnabled) {
          return LoginResult.totpSetupRequired;
        }
        return LoginResult.totpVerifyRequired;
      }

      // Employee or manager without TOTP — complete login
      await _completeLogin(user, data);
      _setLoading(false);
      return user.isManager
          ? LoginResult.managerSuccess
          : LoginResult.employeeSuccess;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _setLoading(false);
      return LoginResult.error;
    }
  }

  /// Verify a 6-digit TOTP code (for managers who already have TOTP set up).
  Future<bool> verifyTotp(String code) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _api.dio.post(
        ApiEndpoints.totpVerify,
        data: {'token': code},
        options: Options(
          headers: {
            if (_pendingToken != null)
              'Authorization': 'Bearer $_pendingToken',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      // Server may issue a new final token after TOTP verification
      final finalToken =
          data['token']?.toString() ?? _pendingToken;

      if (_user != null && finalToken != null) {
        await _storage.saveToken(finalToken);
        await _storage.saveUserData(_user!.toJson());
        _pendingToken = null;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  /// Set up TOTP — requests a new secret from the backend.
  Future<Map<String, dynamic>?> setupTotp() async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.totpSetup,
        options: Options(
          headers: {
            if (_pendingToken != null)
              'Authorization': 'Bearer $_pendingToken',
          },
        ),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  /// Log out — clear all stored data and reset state.
  Future<void> logout() async {
    await _storage.clearAll();
    _user = null;
    _pendingToken = null;
    _error = null;
    notifyListeners();
  }

  // ── Helpers ─────────────────────────────────────────────

  Future<void> _completeLogin(
      UserModel user, Map<String, dynamic> data) async {
    final token = user.token ?? data['token']?.toString();
    if (token != null) {
      await _storage.saveToken(token);
    }
    await _storage.saveUserData(user.toJson());
    _user = user;
    _pendingToken = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final data = error.response!.data as Map;
        return (data['message'] ?? data['error'] ?? 'Login failed').toString();
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Check your network.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Cannot reach the server. Check the API URL.';
      }
      return error.message ?? 'An unexpected error occurred.';
    }
    return error.toString();
  }
}

/// Result of a login attempt — tells the UI what screen to navigate to.
enum LoginResult {
  employeeSuccess,
  managerSuccess,
  totpSetupRequired,
  totpVerifyRequired,
  adminBlocked,
  error,
}
