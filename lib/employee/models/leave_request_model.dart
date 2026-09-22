/// Model for an employee's leave request.
class LeaveRequestModel {
  final String leaveId;
  final String? employeeId;
  final String? employeeName;
  final String leaveType; // sick, casual, earned
  final String startDate;
  final String endDate;
  final String? reason;
  final String status; // pending, approved, denied
  final String? approvedBy;
  final String? appliedAt;
  final String? department;

  LeaveRequestModel({
    required this.leaveId,
    this.employeeId,
    this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    this.reason,
    this.status = 'pending',
    this.approvedBy,
    this.appliedAt,
    this.department,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      leaveId: (json['leave_id'] ?? json['_id'] ?? '').toString(),
      employeeId: json['employee_id']?.toString(),
      employeeName: (json['employee_name'] ??
              json['employee']?['name'] ??
              json['name'])
          ?.toString(),
      leaveType: (json['leave_type'] ?? 'casual').toString(),
      startDate: (json['start_date'] ?? '').toString(),
      endDate: (json['end_date'] ?? '').toString(),
      reason: json['reason']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      approvedBy: json['approved_by']?.toString(),
      appliedAt: json['applied_at']?.toString(),
      department: (json['department'] ?? json['department_name'])?.toString(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isDenied => status == 'denied';
}
