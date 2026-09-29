/// Centralized API endpoint paths for the Sentinel backend.
///
/// All paths are relative to the API base URL configured in [AppConstants].
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ──────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String totpSetup = '/auth/totp/setup';
  static const String totpVerify = '/auth/totp/verify';

  // ── Attendance ────────────────────────────────────────
  /// Query attendance records: GET /attendance?employee_id=...&date=... or ?date=...
  static const String attendance = '/attendance';
  static const String checkIn = '/attendance/checkin';
  static const String checkOut = '/attendance/checkout';

  // ── Leave ─────────────────────────────────────────────
  static const String leaveRequests = '/leave';
  static const String leaveBalance = '/leave/balance';
  static String leaveApprove(String id) => '/leave/$id/approve';
  static String leaveReject(String id) => '/leave/$id/reject';

  // ── Dashboard / Manager ───────────────────────────────
  static const String dashboardSummary = '/dashboard/summary';

  // ── Profile ───────────────────────────────────────────
  static const String profile = '/employees/me';
}
