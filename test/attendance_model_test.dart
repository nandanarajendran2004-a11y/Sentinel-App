import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/employee/models/attendance_model.dart';
import 'package:sentinel_app/manager/models/team_attendance_model.dart';

void main() {
  group('AttendanceModel Parsing Tests', () {
    test('parses backend GET /api/attendance record shape', () {
      final json = {
        '_id': '6741f0a2e4b02a1d4c8e9012',
        'employee_id': '6741f0a2e4b02a1d4c8e9010',
        'employee_name': 'Mary Lee',
        'employee_email': 'mary.lee@sentinel.com',
        'designation': 'Software Engineer',
        'date': '2026-09-29T00:00:00.000Z',
        'check_in_time': '2026-09-29T09:05:00.000Z',
        'check_out_time': '2026-09-29T17:30:00.000Z',
        'working_hours': 8.42,
        'status': 'on-time',
        'verification_method': 'qr_geo',
      };

      final model = AttendanceModel.fromJson(json);

      expect(model.attendanceId, '6741f0a2e4b02a1d4c8e9012');
      expect(model.employeeId, '6741f0a2e4b02a1d4c8e9010');
      expect(model.date, '2026-09-29T00:00:00.000Z');
      expect(model.checkInTime, '2026-09-29T09:05:00.000Z');
      expect(model.checkOutTime, '2026-09-29T17:30:00.000Z');
      expect(model.workingHours, 8.42);
      expect(model.status, 'on-time');
      expect(model.verificationMethod, 'qr_geo');
      expect(model.isCheckedIn, isFalse);
      expect(model.isCheckedOut, isTrue);
      expect(model.isNotCheckedIn, isFalse);
    });

    test('default empty AttendanceModel represents not checked in', () {
      final model = AttendanceModel();
      expect(model.isNotCheckedIn, isTrue);
      expect(model.isCheckedIn, isFalse);
      expect(model.isCheckedOut, isFalse);
      expect(model.statusLabel, 'Not Checked In');
    });
  });

  group('TeamAttendanceModel Parsing Tests', () {
    test('parses backend GET /api/attendance department record shape', () {
      final json = {
        '_id': '6741f0a2e4b02a1d4c8e9012',
        'employee_id': '6741f0a2e4b02a1d4c8e9010',
        'employee_name': 'Mary Lee',
        'employee_email': 'mary.lee@sentinel.com',
        'designation': 'Software Engineer',
        'date': '2026-09-29T00:00:00.000Z',
        'check_in_time': '2026-09-29T09:05:00.000Z',
        'check_out_time': null,
        'working_hours': null,
        'status': 'incomplete',
        'verification_method': 'qr_only',
      };

      final model = TeamAttendanceModel.fromJson(json);

      expect(model.attendanceId, '6741f0a2e4b02a1d4c8e9012');
      expect(model.employeeId, '6741f0a2e4b02a1d4c8e9010');
      expect(model.employeeName, 'Mary Lee');
      expect(model.employeeEmail, 'mary.lee@sentinel.com');
      expect(model.designation, 'Software Engineer');
      expect(model.checkInTime, '2026-09-29T09:05:00.000Z');
      expect(model.checkOutTime, isNull);
      expect(model.status, 'incomplete');
      expect(model.verificationMethod, 'qr_only');
    });
  });
}
