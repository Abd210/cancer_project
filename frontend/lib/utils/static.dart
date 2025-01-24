// lib/utils/static.dart

class ClassUtil {
  // Base API URL
  static const String baseUrl = 'http://localhost:3000/api';

  // Authentication
  static const String loginRoute = '/auth/login';

  // Hospitals: GET data
  static const String hospitalDataRoute = '/hospital/data';

  // Hospitals: CREATE (register)
  static const String hospitalRegisterRoute = '/hospital/register';

  // Hospitals: UPDATE
  static const String hospitalUpdateRoute = '/hospital/data/update';

  // Hospitals: DELETE
  static const String hospitalDeleteRoute = '/hospital/delete';

  /// Builds base headers. If a [token] is provided, it sets the `authentication` header.
  static Map<String, String> baseHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['authentication'] = token; // match your backend requirement
    }
    return headers;
  }
}
