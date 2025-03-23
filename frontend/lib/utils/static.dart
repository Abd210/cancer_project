class ClassUtil {
  // Base API URL
  static const String baseUrl = 'http://localhost:3000/api';

  // -------------------------
  // AUTHENTICATION ROUTES
  // -------------------------
  // Use the same endpoint for all roles (superadmin, admin, doctor, patient)
  static const String loginRoute = '/auth/login';
  static const String registerRoute = '/auth/register';

  // -------------------------
  // HOSPITAL ROUTES
  // -------------------------
  // GET (retrieve hospital data; supports filters via query parameters)
  static const String hospitalDataRoute = '/hospital/data';
  // CREATE (register a new hospital)
  static const String hospitalRegisterRoute = '/hospital/register';
  // UPDATE hospital data
  static const String hospitalUpdateRoute = '/hospital/data/update';
  // DELETE a hospital
  static const String hospitalDeleteRoute = '/hospital/delete';

  // -------------------------
  // ADMIN ROUTES
  // -------------------------
  // GET (retrieve admin data; supports filters via query parameters)
  static const String adminDataRoute = '/admin/data';
  // UPDATE admin data
  static const String adminDataUpdateRoute = '/admin/data/update';
  // DELETE an admin
  static const String adminDeleteRoute = '/admin/delete';

  // -------------------------
  // DOCTOR ROUTES
  // -------------------------
  // GET (retrieve doctor data; supports filters like specific doctor or by hospital)
  static const String doctorDataRoute = '/doctor/data';
  // GET (public data for doctor)
  static const String doctorPublicDataRoute = '/doctor/public-data';
  // UPDATE doctor data
  static const String doctorDataUpdateRoute = '/doctor/data/update';
  // DELETE a doctor
  static const String doctorDeleteRoute = '/doctor/delete';

  // -------------------------
  // PATIENT ROUTES
  // -------------------------
  // GET (retrieve personal data for a patient)
  static const String patientPersonalDataRoute = '/patient/personal-data';
  // UPDATE (update personal data for a patient)
  static const String patientPersonalDataUpdateRoute = '/patient/personal-data/update';
  // DELETE a patient
  static const String patientDeleteRoute = '/patient/delete';
  // GET (retrieve patient diagnosis)
  static const String patientDiagnosisRoute = '/patient/diagnosis';

  // -------------------------
  // APPOINTMENT ROUTES
  // -------------------------
  // CREATE (schedule a new appointment)
  static const String appointmentNewRoute = '/appointment/new';
  // CANCEL an appointment
  static const String appointmentCancelRoute = '/appointment/cancel';
  // UPDATE appointment data
  static const String appointmentUpdateRoute = '/appointment/update';
  // DELETE an appointment
  static const String appointmentDeleteRoute = '/appointment/delete';
  // GET (retrieve upcoming appointments)
  static const String appointmentUpcomingRoute = '/appointment/upcoming';
  // GET (retrieve appointment history)
  static const String appointmentHistoryRoute = '/appointment/history';

  // -------------------------
  // TEST ROUTES
  // -------------------------
  // CREATE (schedule a new test)
  static const String testNewRoute = '/test/new';
  // UPDATE test details
  static const String testUpdateRoute = '/test/update';
  // DELETE a test
  static const String testDeleteRoute = '/test/delete';
  // GET (retrieve test details; supports filtering via role and ID)
  static const String testDetailsRoute = '/test/details';

  /// Builds the base headers for requests.
  /// If a [token] is provided, it sets the `authentication` header.
  static Map<String, String> baseHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['authentication'] = token;
    }
    return headers;
  }
}
