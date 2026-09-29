import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/api_endpoints.dart';
import '../models/team_attendance_model.dart';

/// State management for the manager's team attendance view.
class TeamAttendanceProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<TeamAttendanceModel> _records = [];
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  List<TeamAttendanceModel> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;

  /// Fetch department attendance for a given date via GET /api/attendance?date=...
  Future<void> fetchTeamAttendance({DateTime? date}) async {
    if (date != null) _selectedDate = date;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final response = await _api.dio.get(
        ApiEndpoints.attendance,
        queryParameters: {'date': dateStr},
      );

      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['attendance'] is List) {
        list = data['attendance'] as List;
      } else if (data is Map && data['records'] is List) {
        list = data['records'] as List;
      } else {
        list = [];
      }

      _records = list
          .map((e) => TeamAttendanceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = _extractError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  void setDate(DateTime date) {
    fetchTeamAttendance(date: date);
  }

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data is Map) {
      final data = e.response!.data as Map;
      return (data['message'] ?? data['error'] ?? 'Request failed').toString();
    }
    return e.toString();
  }
}
