/// Represents the authenticated user data returned from the login API.
class UserModel {
  final String userId;
  final String name;
  final String email;
  final String role; // 'employee' | 'manager' | 'admin'
  final bool totpEnabled;
  final bool totpRequired;
  final String? token;
  final String? department;
  final String? designation;
  final String? employeeId;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.totpEnabled = false,
    this.totpRequired = false,
    this.token,
    this.department,
    this.designation,
    this.employeeId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user object if present
    final user = json['user'] as Map<String, dynamic>? ?? json;
    return UserModel(
      userId: (user['user_id'] ?? user['_id'] ?? '').toString(),
      name: (user['name'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
      role: (user['role'] ?? 'employee').toString().toLowerCase(),
      totpEnabled: user['totp_enabled'] == true,
      totpRequired: user['totp_required'] == true,
      token: json['token']?.toString(),
      department: (user['department'] ?? user['department_name'])?.toString(),
      designation: user['designation']?.toString(),
      employeeId: (user['employee_id'] ?? user['employeeId'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'email': email,
        'role': role,
        'totp_enabled': totpEnabled,
        'totp_required': totpRequired,
        'department': department,
        'designation': designation,
        'employee_id': employeeId,
      };

  bool get isEmployee => role == 'employee';
  bool get isManager => role == 'manager';
  bool get isAdmin => role == 'admin';
}
