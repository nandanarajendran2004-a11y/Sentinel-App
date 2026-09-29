/// Model for an individual team member's attendance record.
class TeamAttendanceModel {
  final String? attendanceId;
  final String? employeeId;
  final String? employeeName;
  final String? employeeEmail;
  final String? date;
  final String? checkInTime;
  final String? checkOutTime;
  final double? workingHours;
  final String status;
  final String? designation;
  final String? verificationMethod;

  TeamAttendanceModel({
    this.attendanceId,
    this.employeeId,
    this.employeeName,
    this.employeeEmail,
    this.date,
    this.checkInTime,
    this.checkOutTime,
    this.workingHours,
    this.status = 'not_checked_in',
    this.designation,
    this.verificationMethod,
  });

  factory TeamAttendanceModel.fromJson(Map<String, dynamic> json) {
    return TeamAttendanceModel(
      attendanceId: (json['attendance_id'] ?? json['_id'])?.toString(),
      employeeId: json['employee_id']?.toString(),
      employeeName: (json['employee_name'] ??
              json['employee']?['name'] ??
              json['name'])
          ?.toString(),
      employeeEmail: json['employee_email']?.toString(),
      date: json['date']?.toString(),
      checkInTime: json['check_in_time']?.toString(),
      checkOutTime: json['check_out_time']?.toString(),
      workingHours: json['working_hours'] != null
          ? double.tryParse(json['working_hours'].toString())
          : null,
      status: (json['status'] ?? 'not_checked_in').toString(),
      designation: (json['designation'] ?? json['employee']?['designation'])
          ?.toString(),
      verificationMethod: json['verification_method']?.toString(),
    );
  }
}
