// lib/utils/static.dart

class ClassUtil {
  // Base API URL
  static const String baseUrl = 'http://localhost:3000/api';

  // -------------------------
  // AUTHENTICATION ROUTES
  // -------------------------
  static const String loginRoute = '/auth/login';
  static const String registerRoute = '/auth/register';

  // -------------------------
  // HOSPITAL ROUTES
  // -------------------------
  // GET (data)
  static const String hospitalDataRoute = '/hospital/data';
  // CREATE (register)
  static const String hospitalRegisterRoute = '/hospital/register';
  // UPDATE
  static const String hospitalUpdateRoute = '/hospital/data/update';
  // DELETE
  static const String hospitalDeleteRoute = '/hospital/delete';

  // -------------------------
  // ADMIN ROUTES
  // -------------------------
  // GET (data)
  static const String adminDataRoute = '/admin/data';
  // UPDATE
  static const String adminDataUpdateRoute = '/admin/data/update';
  // DELETE
  static const String adminDeleteRoute = '/admin/delete';

  // -------------------------
  // DOCTOR ROUTES
  // -------------------------
  // GET (data)
  static const String doctorDataRoute = '/doctor/data';
  // GET (public data)
  static const String doctorPublicDataRoute = '/doctor/public-data';
  // UPDATE
  static const String doctorDataUpdateRoute = '/doctor/data/update';
  // DELETE
  static const String doctorDeleteRoute = '/doctor/delete';

  // -------------------------
  // PATIENT ROUTES
  // -------------------------
  // GET (personal data)
  static const String patientPersonalDataRoute = '/patient/personal-data';
  // UPDATE (personal data)
  static const String patientPersonalDataUpdateRoute = '/patient/personal-data/update';
  // DELETE
  static const String patientDeleteRoute = '/patient/delete';
  // GET (diagnosis)
  static const String patientDiagnosisRoute = '/patient/diagnosis';

  // -------------------------
  // APPOINTMENT ROUTES
  // -------------------------
  // CREATE (schedule)
  static const String appointmentNewRoute = '/appointment/new';
  // CANCEL
  static const String appointmentCancelRoute = '/appointment/cancel';
  // UPDATE
  static const String appointmentUpdateRoute = '/appointment/update';
  // DELETE
  static const String appointmentDeleteRoute = '/appointment/delete';
  // GET (upcoming)
  static const String appointmentUpcomingRoute = '/appointment/upcoming';
  // GET (history)
  static const String appointmentHistoryRoute = '/appointment/history';

  // -------------------------
  // TEST ROUTES
  // -------------------------
  // CREATE
  static const String testNewRoute = '/test/new';
  // UPDATE
  static const String testUpdateRoute = '/test/update';
  // DELETE
  static const String testDeleteRoute = '/test/delete';
  // GET (details)
  static const String testDetailsRoute = '/test/details';

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
