// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/api_endpoints.dart';
import '../../core/secure_storage_service.dart';
import '../models/attendance_model.dart';

/// State management for the employee home screen — today's attendance.
class EmployeeHomeProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  AttendanceModel? _attendance;
  bool _isLoading = false;
  String? _error;
  int? _lastStatusCode;
  Map<String, dynamic>? _lastErrorData;

  AttendanceModel? get attendance => _attendance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get lastStatusCode => _lastStatusCode;
  Map<String, dynamic>? get lastErrorData => _lastErrorData;

  /// Fetch today's attendance status via GET /api/attendance?employee_id=...&date=...
  Future<void> fetchTodayAttendance({String? employeeId}) async {
    _isLoading = true;
    _error = null;
    _lastStatusCode = null;
    _lastErrorData = null;
    notifyListeners();

    try {
      // Resolve employee_id from parameter, stored user data, or stored JWT
      String? empId = employeeId;
      if (empId == null) {
        final userData = await _storage.getUserData();
        empId = (userData?['employee_id'] ?? userData?['employeeId'])?.toString();
        if (empId == null) {
          final token = await _storage.getToken();
          if (token != null) {
            empId = _extractEmployeeIdFromJwt(token);
          }
        }
      }

      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final queryParams = <String, dynamic>{
        'date': todayStr,
        if (empId != null && empId.isNotEmpty) 'employee_id': empId,
      };

      final response = await _api.dio.get(
        ApiEndpoints.attendance,
        queryParameters: queryParams,
      );

      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['attendance'] is List) {
        list = data['attendance'] as List;
      } else if (data is Map && data['records'] is List) {
        list = data['records'] as List;
      } else if (data is Map<String, dynamic>) {
        list = [data];
      } else {
        list = [];
      }

      if (list.isNotEmpty && list.first is Map<String, dynamic>) {
        _attendance =
            AttendanceModel.fromJson(list.first as Map<String, dynamic>);
      } else {
        // No record yet today — employee has not checked in
        _attendance = AttendanceModel();
      }
    } catch (e) {
      _extractError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Extracts employee_id claim from JWT token payload.
  String? _extractEmployeeIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length >= 2) {
        final normalized = base64Url.normalize(parts[1]);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final map = jsonDecode(decoded);
        if (map is Map) {
          return map['employee_id']?.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Submit a QR check-in with GPS verification data.
  Future<bool> checkIn(
    String qrCode, {
    double? latitude,
    double? longitude,
    double? accuracy_m,
    bool is_mock_location = false,
  }) async {
    _isLoading = true;
    _error = null;
    _lastStatusCode = null;
    _lastErrorData = null;
    notifyListeners();

    final Map<String, dynamic> requestData = {
      'qr_code': qrCode,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_m': accuracy_m,
      'is_mock_location': is_mock_location,
    };

    // If QR payload contains session JSON, unpack fields for backend verification pipeline
    try {
      final decoded = jsonDecode(qrCode);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('id') || decoded.containsKey('qr_session_id')) {
          requestData['qr_session_id'] =
              decoded['qr_session_id'] ?? decoded['id'];
        }
        if (decoded.containsKey('code') || decoded.containsKey('code_value')) {
          requestData['code_value'] =
              decoded['code_value'] ?? decoded['code'];
        }
        if (decoded.containsKey('sig') || decoded.containsKey('signature')) {
          requestData['signature'] =
              decoded['signature'] ?? decoded['sig'];
        }
      }
    } catch (_) {
      // Non-JSON QR payload
    }

    try {
      final response = await _api.dio.post(
        ApiEndpoints.checkIn,
        data: requestData,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final attendanceData =
            data['attendance'] as Map<String, dynamic>? ?? data;
        _attendance = AttendanceModel.fromJson(attendanceData);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Submit a QR check-out with GPS verification data.
  Future<bool> checkOut(
    String qrCode, {
    double? latitude,
    double? longitude,
    double? accuracy_m,
    bool is_mock_location = false,
  }) async {
    _isLoading = true;
    _error = null;
    _lastStatusCode = null;
    _lastErrorData = null;
    notifyListeners();

    final Map<String, dynamic> requestData = {
      'qr_code': qrCode,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_m': accuracy_m,
      'is_mock_location': is_mock_location,
    };

    // If QR payload contains session JSON, unpack fields for backend verification pipeline
    try {
      final decoded = jsonDecode(qrCode);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('id') || decoded.containsKey('qr_session_id')) {
          requestData['qr_session_id'] =
              decoded['qr_session_id'] ?? decoded['id'];
        }
        if (decoded.containsKey('code') || decoded.containsKey('code_value')) {
          requestData['code_value'] =
              decoded['code_value'] ?? decoded['code'];
        }
        if (decoded.containsKey('sig') || decoded.containsKey('signature')) {
          requestData['signature'] =
              decoded['signature'] ?? decoded['sig'];
        }
      }
    } catch (_) {
      // Non-JSON QR payload
    }

    try {
      final response = await _api.dio.post(
        ApiEndpoints.checkOut,
        data: requestData,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final attendanceData =
            data['attendance'] as Map<String, dynamic>? ?? data;
        _attendance = AttendanceModel.fromJson(attendanceData);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      _lastStatusCode = e.response?.statusCode;
      if (e.response?.data is Map) {
        _lastErrorData = Map<String, dynamic>.from(e.response!.data as Map);
        _error = (_lastErrorData!['message'] ??
                _lastErrorData!['error'] ??
                'Request failed')
            .toString();
        return _error!;
      }
    }
    _error = e.toString();
    return _error!;
  }
}
