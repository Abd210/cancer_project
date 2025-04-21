// lib/models/login_response.dart
/// ---------------------------------------------------------------------------
///  MODEL SHAPED TO MATCH the API response shown in BC‑Project PDF
///  {
///     "token":   "...",
///     "message": "Login successful",
///     "user": {
///        "id":        "...",
///        "role":      "superadmin" | "admin" | "doctor" | "patient",
///        "hospital":  "abc123"          // present for admin / doctor / patient
///     }
///  }
/// ---------------------------------------------------------------------------
class LoginResponse {
  final String token;
  final String role;
  final String userId;
  final String? hospitalId;   // null for super‑admin
  final String? message;

  LoginResponse({
    required this.token,
    required this.role,
    required this.userId,
    this.hospitalId,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String,dynamic>? ?? {};
    return LoginResponse(
      token      : json['token']  ?? '',
      message    : json['message'],
      role       : user['role']   ?? '',
      userId     : user['id']     ?? user['_id'] ?? '',
      hospitalId : user['hospital'],    // may be null / absent for superadmin
    );
  }
}
