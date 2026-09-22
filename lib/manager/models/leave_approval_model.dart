import '../../employee/models/leave_request_model.dart';

/// Re-export [LeaveRequestModel] as the approval model.
///
/// Manager leave approvals use the same data shape as employee leave requests,
/// just displayed differently (with approve/reject actions). This alias
/// keeps the manager module's imports self-documenting.
typedef LeaveApprovalModel = LeaveRequestModel;
