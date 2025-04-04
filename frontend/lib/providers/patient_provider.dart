// lib/providers/patient_provider.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/utils/static.dart';
import 'package:frontend/models/patient_data.dart';
import 'package:flutter/foundation.dart';

class PatientProvider {
  /// -------------------------------------------------
  /// GET /api/patient/personal-data
  ///    - If we pass "patientid" in headers, we get 1
  ///    - If we pass "filter" or none, we can get multiple
  /// -------------------------------------------------
  Future<List<PatientData>> getPatients({
    required String token,
    String? patientId,
    String? filter,
  }) async {
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.patientPersonalDataRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    if (patientId != null && patientId.isNotEmpty) {
      headers['patientid'] = patientId;
    }
    if (filter != null && filter.isNotEmpty) {
      headers['filter'] = filter;
    }

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(response.body);

        if (decoded is List) {
          return decoded.map<PatientData>((json) {
            try {
              return PatientData.fromJson(json);
            } catch (e) {
              rethrow;
            }
          }).toList();
        } else if (decoded is Map<String, dynamic>) {
          return [PatientData.fromJson(decoded)];
        } else {
          throw Exception('Unexpected patient data format: $decoded');
        }
      } catch (e) {
        throw Exception('Failed to process patient data: $e');
      }
    } else {
      throw Exception(
        'Failed to GET patients (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// -------------------------------------------------
  /// POST => /api/auth/register (role=patient)
  /// The request body is now built using camelCase keys.
  /// -------------------------------------------------
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

    final body = {
      "persId": persId,
      "name": name,
      "role": "patient",
      "password": password,
      "mobileNumber": mobileNumber,
      "email": email,
      "status": status,
      "diagnosis": diagnosis,
      "birthDate": birthDate,
      "medicalHistory": medicalHistory,
      "hospital": hospitalId,
      "suspended": suspended,
    };

    final response =
        await http.post(url, headers: headers, body: jsonEncode(body));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else {
      throw Exception(
        'Failed to create patient (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// -------------------------------------------------
  /// PUT => /api/patient/personal-data/update
  ///    - Must pass "patientid" in headers
  ///    - Updated fields in JSON using camelCase keys.
  /// -------------------------------------------------
  Future<PatientData> updatePatient({
    required String token,
    required String patientId,
    required Map<String, dynamic> updatedFields,
  }) async {
    final url = Uri.parse(
        '${ClassUtil.baseUrl}${ClassUtil.patientPersonalDataUpdateRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    headers['patientid'] = patientId;

    final response =
        await http.put(url, headers: headers, body: jsonEncode(updatedFields));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return PatientData.fromJson(decoded);
    } else {
      throw Exception(
        'Failed to update patient (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// -------------------------------------------------
  /// DELETE => /api/patient/delete
  ///    - Must pass "patientid" in headers
  /// -------------------------------------------------
  Future<void> deletePatient({
    required String token,
    required String patientId,
  }) async {
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.patientDeleteRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    headers['patientid'] = patientId;

    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete patient (${response.statusCode}): ${response.body}',
      );
    }
  }
}
