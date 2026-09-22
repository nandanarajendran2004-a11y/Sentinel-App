/// Model for today's attendance status.
class AttendanceModel {
  final String? attendanceId;
  final String? employeeId;
  final String? date;
  final String? checkInTime;
  final String? checkOutTime;
  final double? workingHours;
  final String status; // on-time, late, early-leave, on-leave, incomplete

  AttendanceModel({
    this.attendanceId,
    this.employeeId,
    this.date,
    this.checkInTime,
    this.checkOutTime,
    this.workingHours,
    this.status = 'not_checked_in',
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      attendanceId:
          (json['attendance_id'] ?? json['_id'])?.toString(),
      employeeId: json['employee_id']?.toString(),
      date: json['date']?.toString(),
      checkInTime: json['check_in_time']?.toString(),
      checkOutTime: json['check_out_time']?.toString(),
      workingHours: json['working_hours'] != null
          ? double.tryParse(json['working_hours'].toString())
          : null,
      status: (json['status'] ?? 'not_checked_in').toString(),
    );
  }

  /// Not yet checked in today.
  bool get isNotCheckedIn =>
      checkInTime == null && status == 'not_checked_in';

  /// Checked in but not yet checked out.
  bool get isCheckedIn =>
      checkInTime != null && checkOutTime == null;

  /// Both check-in and check-out recorded.
  bool get isCheckedOut =>
      checkInTime != null && checkOutTime != null;

  /// Returns a human-readable label for the current state.
  String get statusLabel {
    if (isNotCheckedIn) return 'Not Checked In';
    if (isCheckedIn) return 'Checked In';
    if (isCheckedOut) return 'Checked Out';
    return status.replaceAll('_', ' ').replaceAll('-', ' ');
  }
}
