// lib/providers/auth_provider.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/utils/static.dart';
import 'package:frontend/models/login_response.dart';

class AuthProvider {
  Future<LoginResponse> login({
    required String email,
    required String password,
    required String role,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.loginRoute}');

    final response = await http.post(
      url,
      headers: ClassUtil.baseHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return LoginResponse.fromJson(data);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }
}
