import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/api_endpoints.dart';
import '../models/leave_request_model.dart';

/// State management for the employee's leave requests.
class LeaveProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<LeaveRequestModel> _requests = [];
  bool _isLoading = false;
  String? _error;
  bool _isSubmitting = false;

  List<LeaveRequestModel> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSubmitting => _isSubmitting;

  /// Fetch the employee's own leave requests.
  Future<void> fetchLeaveRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get(ApiEndpoints.leaveRequests);
      final data = response.data;
      List<dynamic> list;

      if (data is List) {
        list = data;
      } else if (data is Map && data['leaves'] is List) {
        list = data['leaves'] as List;
      } else if (data is Map && data['leaveRequests'] is List) {
        list = data['leaveRequests'] as List;
      } else {
        list = [];
      }

      _requests = list
          .map((e) => LeaveRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = _extractError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Submit a new leave request.
  Future<bool> submitLeaveRequest({
    required String leaveType,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _api.dio.post(
        ApiEndpoints.leaveRequests,
        data: {
          'leave_type': leaveType,
          'start_date': startDate,
          'end_date': endDate,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      _isSubmitting = false;
      notifyListeners();
      // Refresh the list after submitting
      await fetchLeaveRequests();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isSubmitting = false;
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
