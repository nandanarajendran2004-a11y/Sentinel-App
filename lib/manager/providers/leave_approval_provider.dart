import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/api_endpoints.dart';
import '../models/leave_approval_model.dart';

/// State management for manager's leave approval workflow.
class LeaveApprovalProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<LeaveApprovalModel> _pendingRequests = [];
  bool _isLoading = false;
  String? _error;

  List<LeaveApprovalModel> get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch pending leave requests for the manager's department.
  Future<void> fetchPendingRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get(
        ApiEndpoints.leaveRequests,
        queryParameters: {'status': 'pending'},
      );

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

      _pendingRequests = list
          .map((e) => LeaveApprovalModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = _extractError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Approve a leave request.
  Future<bool> approveRequest(String leaveId) async {
    try {
      await _api.dio.put(ApiEndpoints.leaveApprove(leaveId));
      _pendingRequests.removeWhere((r) => r.leaveId == leaveId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  /// Reject a leave request.
  Future<bool> rejectRequest(String leaveId) async {
    try {
      await _api.dio.put(ApiEndpoints.leaveReject(leaveId));
      _pendingRequests.removeWhere((r) => r.leaveId == leaveId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
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
