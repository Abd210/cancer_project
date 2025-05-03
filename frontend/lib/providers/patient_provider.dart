import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/utils/static.dart';
import 'package:frontend/models/patient_data.dart';
import 'package:flutter/foundation.dart';

class PatientProvider {
  // ------------------------------------------------------------------
  // GET  /api/patient/personal-data
  // Optional headers:
  //   • patientid   – return single record
  //   • filter      – suspended | unsuspended | all
  //   • hospitalid  – restrict to one hospital
  // ------------------------------------------------------------------
  Future<List<PatientData>> getPatients({
    required String token,
    String? patientId,
    String? filter,
    String? hospitalId,
  }) async {
    final url = Uri.parse(
        '${ClassUtil.baseUrl}${ClassUtil.patientPersonalDataRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    if (_isNotEmpty(patientId))  headers['patientid']  = patientId!;
    if (_isNotEmpty(filter))     headers['filter']     = filter!;
    if (_isNotEmpty(hospitalId)) headers['hospitalid'] = hospitalId!;

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
    final headers =
        ClassUtil.baseHeaders(token: token)..['patientid'] = patientId;

    final res =
        await http.put(url, headers: headers, body: jsonEncode(updatedFields));
    if (res.statusCode == 200) {
      return PatientData.fromJson(json.decode(res.body));
    }
    throw Exception(
      'Patient update failed [${res.statusCode}]: ${res.body}',
    );
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
    final headers =
        ClassUtil.baseHeaders(token: token)..['patientid'] = patientId;

    final res = await http.delete(url, headers: headers);
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
        'Patient delete failed [${res.statusCode}]: ${res.body}',
      );
    }
  }

  // helper ------------------------------------------------------------
  bool _isNotEmpty(String? v) => v != null && v.trim().isNotEmpty;
}
