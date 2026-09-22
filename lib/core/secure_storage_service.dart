import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

/// Wrapper around [FlutterSecureStorage] for JWT and user data persistence.
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._();
  factory SecureStorageService() => _instance;
  SecureStorageService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── JWT ────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.jwtStorageKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.jwtStorageKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.jwtStorageKey);
  }

  // ── User Data ──────────────────────────────────────────

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(
      key: AppConstants.userDataKey,
      value: jsonEncode(userData),
    );
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: AppConstants.userDataKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  /// Clears all stored data (JWT + user data) — used on logout and 401.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
