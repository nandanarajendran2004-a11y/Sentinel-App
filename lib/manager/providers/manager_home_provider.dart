import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/api_endpoints.dart';
import '../models/team_summary_model.dart';

/// State management for the manager home screen — team summary for today.
class ManagerHomeProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  TeamSummaryModel? _summary;
  bool _isLoading = false;
  String? _error;

  TeamSummaryModel? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch today's department attendance summary.
  Future<void> fetchTeamSummary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get(ApiEndpoints.dashboardSummary);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Handle nested { summary: {...} } or flat
        final summaryData =
            data['summary'] as Map<String, dynamic>? ??
            data['attendance'] as Map<String, dynamic>? ??
            data;
        _summary = TeamSummaryModel.fromJson(summaryData);
      }
    } catch (e) {
      _error = _extractError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data is Map) {
      final data = e.response!.data as Map;
      return (data['message'] ?? data['error'] ?? 'Request failed').toString();
    }
    return e.toString();
  }
}
