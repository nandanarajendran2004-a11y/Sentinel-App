import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/api_endpoints.dart';
import '../models/attendance_model.dart';

/// State management for the employee home screen — today's attendance.
class EmployeeHomeProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  AttendanceModel? _attendance;
  bool _isLoading = false;
  String? _error;

  AttendanceModel? get attendance => _attendance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch today's attendance status.
  Future<void> fetchTodayAttendance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get(ApiEndpoints.attendanceToday);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Handle both direct data and nested { attendance: {...} }
        final attendanceData =
            data['attendance'] as Map<String, dynamic>? ?? data;
        _attendance = AttendanceModel.fromJson(attendanceData);
      } else {
        // No record yet today
        _attendance = AttendanceModel();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // No attendance record for today — not checked in yet
        _attendance = AttendanceModel();
      } else {
        _error = _extractError(e);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Submit a QR check-in.
  Future<bool> checkIn(String qrCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.post(
        ApiEndpoints.checkIn,
        data: {'qr_code': qrCode},
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
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Submit a QR check-out.
  Future<bool> checkOut(String qrCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.post(
        ApiEndpoints.checkOut,
        data: {'qr_code': qrCode},
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
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data is Map) {
      final data = e.response!.data as Map;
      return (data['message'] ?? data['error'] ?? 'Request failed').toString();
    }
    return e.toString();
  }
}
