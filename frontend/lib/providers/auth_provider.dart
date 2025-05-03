// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/utils/static.dart';
import 'package:frontend/models/login_response.dart';

class AuthProvider {
  /// Performs /auth/login and returns parsed [LoginResponse].
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.loginRoute}');

    final res = await http.post(
      url,
      headers: ClassUtil.baseHeaders(),
      body   : jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode == 200) {
      final Map<String,dynamic> body = json.decode(res.body);
      return LoginResponse.fromJson(body);
    }
    throw Exception('Login failed [${res.statusCode}]: ${res.body}');
  }
}
