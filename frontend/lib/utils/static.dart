// lib/utils/static.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ClassUtil {
  /// ------------------------------------------------------------------
  ///  BASE URL CONFIGURATION
  /// ------------------------------------------------------------------
  // For Android emulators, 10.0.2.2 points to the host machine's localhost
  // For iOS simulators, localhost works fine
  // For physical devices, use the actual IP address of your development machine
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }

  /// ------------------------------------------------------------------
  ///  AUTH
  /// ------------------------------------------------------------------
  static const String loginRoute = '/auth/login';
  static const String registerRoute = '/auth/register';

  /// ------------------------------------------------------------------
  ///  HOSPITAL
  /// ------------------------------------------------------------------
  static const String hospitalDataRoute = '/hospital/data';
  static const String hospitalRegisterRoute = '/hospital/register';
  static const String hospitalUpdateRoute = '/hospital/data/update';
  static const String hospitalDeleteRoute = '/hospital/delete';

  /// ------------------------------------------------------------------
  ///  ADMIN
  /// ------------------------------------------------------------------
  static const String adminDataRoute = '/admin/data';
  static const String adminDataUpdateRoute = '/admin/data/update';
  static const String adminDeleteRoute = '/admin/delete';

  /// ------------------------------------------------------------------
  ///  DOCTOR
  /// ------------------------------------------------------------------
  static const String doctorDataRoute = '/doctor/data';
  static const String doctorPublicDataRoute = '/doctor/public-data';
  static const String doctorDataUpdateRoute = '/doctor/data/update';
  static const String doctorDeleteRoute = '/doctor/delete';
  static const String doctorPatientsRoute = '/doctor/patients';

  /// ------------------------------------------------------------------
  ///  PATIENT
  /// ------------------------------------------------------------------
  static const String patientPersonalDataRoute = '/patient/personal-data';
  static const String patientPersonalDataUpdateRoute =
      '/patient/personal-data/update';
  static const String patientDeleteRoute = '/patient/delete';
  static const String patientDiagnosisRoute = '/patient/diagnosis';

  /// ------------------------------------------------------------------
  ///  DEVICE
  /// ------------------------------------------------------------------
  static const String deviceDataRoute = '/device/data';
  static const String deviceNewRoute = '/device/new';
  static const String deviceUpdateRoute = '/device/update';
  static const String deviceDeleteRoute = '/device/delete';

  /// ------------------------------------------------------------------
  ///  APPOINTMENT
  /// ------------------------------------------------------------------
  static const String appointmentNewRoute = '/appointment/new';
  static const String appointmentCancelRoute = '/appointment/cancel';
  static const String appointmentUpdateRoute = '/appointment/update';
  static const String appointmentDeleteRoute = '/appointment/delete';
  static const String appointmentUpcomingRoute = '/appointment/upcoming';
  static const String appointmentUpcomingAllRoute = '/appointment/upcoming/all';
  static const String appointmentHistoryRoute = '/appointment/history';
  static const String appointmentHospitalUpcomingRoute =
      '/appointment/hospital/upcoming';
  static const String appointmentHospitalHistoryRoute =
      '/appointment/hospital/history';

  /// ------------------------------------------------------------------
  ///  TEST
  /// ------------------------------------------------------------------
  static const String testNewRoute = '/test/new';
  static const String testUpdateRoute = '/test/update';
  static const String testDeleteRoute = '/test/delete';
  static const String testDetailsRoute = '/test/details';

  /// ------------------------------------------------------------------
  ///  COMMON HELPERS
  /// ------------------------------------------------------------------
  static Map<String, String> baseHeaders({String? token}) {
    final hdr = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) hdr['authentication'] = token;
    return hdr;
  }

  /// Converts any nullable/num ID to a non‑null String.
  static String strId(dynamic id) => id == null ? '' : id.toString();
}
