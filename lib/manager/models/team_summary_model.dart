/// Model for the manager's team summary (today's department snapshot).
class TeamSummaryModel {
  final int onTime;
  final int late_;
  final int onLeave;
  final int notCheckedIn;
  final int total;

  TeamSummaryModel({
    this.onTime = 0,
    this.late_ = 0,
    this.onLeave = 0,
    this.notCheckedIn = 0,
    this.total = 0,
  });

  factory TeamSummaryModel.fromJson(Map<String, dynamic> json) {
    return TeamSummaryModel(
      onTime: _parseInt(json['on_time'] ?? json['onTime']),
      late_: _parseInt(json['late'] ?? json['lateCount']),
      onLeave: _parseInt(json['on_leave'] ?? json['onLeave']),
      notCheckedIn:
          _parseInt(json['not_checked_in'] ?? json['notCheckedIn'] ?? json['absent']),
      total: _parseInt(json['total'] ?? json['totalEmployees']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
