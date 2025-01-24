// lib/models/login_response.dart

class LoginResponse {
  final String? token;
  final String? message;

  LoginResponse({this.token, this.message});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String?,
      message: json['message'] as String?,
    );
  }
}
