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
  static const String attendanceToday = '/attendance/today';
  static const String checkIn = '/attendance/check-in';
  static const String checkOut = '/attendance/check-out';

  // ── Leave ─────────────────────────────────────────────
  static const String leaveRequests = '/leave';
  static const String leaveBalance = '/leave/balance';
  static String leaveApprove(String id) => '/leave/$id/approve';
  static String leaveReject(String id) => '/leave/$id/reject';

  // ── Dashboard / Manager ───────────────────────────────
  static const String dashboardSummary = '/dashboard/summary';
  static const String teamAttendance = '/attendance/department';

  // ── Profile ───────────────────────────────────────────
  static const String profile = '/employees/me';
}
