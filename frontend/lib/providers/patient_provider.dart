import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:frontend/utils/static.dart';
import 'package:frontend/models/patient_data.dart';
import 'package:frontend/models/appointment_data.dart';
import 'package:frontend/providers/appointment_provider.dart';

import 'package:frontend/main.dart'
    show httpClient, Logger; // Import our custom Logger

class PatientProvider {
  // ------------------------------------------------------------------
  // GET  /api/patient/personal-data
  // Optional headers:
  //   • patientid   – return single record
  //   • filter      – suspended | unsuspended | all
  //   • hospitalid  – restrict to one hospital
  //   • doctorid    - restrict to one doctor
  // ------------------------------------------------------------------
  Future<List<PatientData>> getPatients({
    required String token,
    String? patientId,
    String? filter,
    String? hospitalId,
    String? doctorId,
  }) async {
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.patientPersonalDataRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    if (_isNotEmpty(patientId)) headers['patientid'] = patientId!;
    if (_isNotEmpty(filter)) headers['filter'] = filter!;
    if (_isNotEmpty(hospitalId)) headers['hospitalid'] = hospitalId!;
    if (_isNotEmpty(doctorId)) headers['doctorid'] = doctorId!;

    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      if (decoded is List) {
        return decoded
            .map<PatientData>((e) => PatientData.fromJson(e))
            .toList();
      } else if (decoded is Map<String, dynamic>) {
        return [PatientData.fromJson(decoded)];
      }
      throw Exception('Unexpected patient payload: $decoded');
    }
    throw Exception(
      'Patient GET failed [${res.statusCode}]: ${res.body}',
    );
  }

  // ------------------------------------------------------------------
  // GET  /api/doctor/patients
  // Header parameters:
  //   • doctorid    - ID of the doctor to get patients for
  //   • filter      - optional filtering (all, suspended, unsuspended)
  // ------------------------------------------------------------------
  Future<List<PatientData>> getPatientsForDoctor({
    required String token,
    required String doctorId,
    String? filter,
  }) async {
    try {
      final url =
          Uri.parse('${ClassUtil.baseUrl}${ClassUtil.doctorPatientsRoute}');
      final headers = ClassUtil.baseHeaders(token: token);

      // Add doctorId to the headers - both variants for compatibility
      headers['doctorid'] = doctorId;
      headers['doctor_id'] = doctorId;

      // Add filter if provided
      if (_isNotEmpty(filter)) {
        headers['filter'] = filter!;
      }

      try {
        final res = await httpClient.get(url, headers: headers);

        if (res.statusCode != 200) {
          throw Exception(
              'Doctor patients GET failed [${res.statusCode}]: ${res.body}');
        }

        final decoded = json.decode(res.body);

        if (decoded is List) {
          final patients = decoded.map((e) => PatientData.fromJson(e)).toList();
          return patients;
        } else if (decoded is Map<String, dynamic>) {
          // In case the server wraps a single patient in an object
          return [PatientData.fromJson(decoded)];
        } else {
          throw Exception('Unexpected payload type: ${decoded.runtimeType}');
        }
      } catch (networkError) {
        rethrow; // Rethrow to let the UI handle it
      }
    } catch (outerError) {
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  // POST  /api/auth/register  (role = patient)
  // ------------------------------------------------------------------
  Future<void> createPatient({
    required String token,
    required String persId,
    required String name,
    required String password,
    required String mobileNumber,
    required String email,
    required String status,
    required String diagnosis,
    required String birthDate,
    required List<String> medicalHistory,
    required String hospitalId,
    List<String> doctorIds = const [],
    required bool suspended,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.registerRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    final body = jsonEncode({
      'persId': persId,
      'name': name,
      'role': 'patient',
      'password': password,
      'mobileNumber': mobileNumber,
      'email': email,
      'status': status,
      'diagnosis': diagnosis,
      'birthDate': birthDate,
      'medicalHistory': medicalHistory,
      'hospital': hospitalId,
      'doctors': doctorIds,
      'suspended': suspended,
    });

    final res = await http.post(url, headers: headers, body: body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
        'Patient create failed [${res.statusCode}]: ${res.body}',
      );
    }
  }

  // ------------------------------------------------------------------
  // PUT  /api/patient/personal-data/update
  // ------------------------------------------------------------------
  Future<PatientData> updatePatient({
    required String token,
    required String patientId,
    required Map<String, dynamic> updatedFields,
  }) async {
    final url = Uri.parse(
        '${ClassUtil.baseUrl}${ClassUtil.patientPersonalDataUpdateRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['patientid'] = patientId;

    final res =
        await http.put(url, headers: headers, body: jsonEncode(updatedFields));
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);

      // Handle both string and object responses
      if (decoded is String) {
        // If we got a success message but no patient data, fetch the updated patient
        return await _fetchPatientAfterUpdate(token, patientId);
      } else if (decoded is Map<String, dynamic>) {
        // If we got back the patient data directly, use it
        return PatientData.fromJson(decoded);
      } else {
        throw Exception('Unexpected response type: ${decoded.runtimeType}');
      }
    }
    throw Exception(
      'Patient update failed [${res.statusCode}]: ${res.body}',
    );
  }

  // Helper to fetch the patient data after an update
  Future<PatientData> _fetchPatientAfterUpdate(
      String token, String patientId) async {
    final patients = await getPatients(
      token: token,
      patientId: patientId,
    );

    if (patients.isEmpty) {
      throw Exception('Failed to fetch updated patient data');
    }

    return patients.first;
  }

  // ------------------------------------------------------------------
  // DELETE  /api/patient/delete
  // ------------------------------------------------------------------
  Future<void> deletePatient({
    required String token,
    required String patientId,
  }) async {
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.patientDeleteRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['patientid'] = patientId;

    final res = await http.delete(url, headers: headers);
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
        'Patient delete failed [${res.statusCode}]: ${res.body}',
      );
    }
  }

  // ------------------------------------------------------------------
  // GET PATIENT APPOINTMENTS HISTORY
  // ------------------------------------------------------------------
  Future<List<AppointmentData>> getPatientAppointmentHistory({
    required String token,
    required String patientId,
    String suspendfilter = 'unsuspended',
  }) async {
    try {
      Logger.log(
          'getPatientAppointmentHistory: Starting with patientId=$patientId');

      final historyList = await AppointmentProvider().getAppointmentsHistory(
        token: token,
        suspendfilter: suspendfilter,
        filterByRole: 'patient',
        filterById: patientId,
      );
      Logger.log(
          'getPatientAppointmentHistory: Got ${historyList.length} history appointments');
      return historyList;
    } catch (e) {
      Logger.log('Error in getPatientAppointmentHistory: $e');
      rethrow;
    }
  }

  // helper ------------------------------------------------------------
  bool _isNotEmpty(String? v) => v != null && v.trim().isNotEmpty;

  Future<PatientData> getPatientById({
    required String token,
    required String patientId,
  }) async {
    try {
      final url = Uri.parse(
          '${ClassUtil.baseUrl}${ClassUtil.patientPersonalDataRoute}');
      final headers = ClassUtil.baseHeaders(token: token)
        ..['patientid'] = patientId;

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          if (decoded.isEmpty) {
            throw Exception('Patient not found');
          }
          return PatientData.fromJson(decoded.first);
        } else if (decoded is Map<String, dynamic>) {
          return PatientData.fromJson(decoded);
        }
        throw Exception('Unexpected response format');
      } else {
        throw Exception(
            'Failed to fetch patient details: ${response.statusCode}');
      }
    } catch (e) {
      Logger.log('Error fetching patient details: $e', name: 'PATIENT_API');
      rethrow;
    }
  }
}
