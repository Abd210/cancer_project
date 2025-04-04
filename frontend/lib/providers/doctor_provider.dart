// lib/providers/doctor_provider.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/models/doctor_data.dart';
import 'package:frontend/utils/static.dart';
import 'package:flutter/foundation.dart';

class DoctorProvider {
  /// GET /api/doctor/data
  /// - If "doctorid" is passed in headers, get a single doctor.
  /// - Otherwise, return a list.
  Future<List<DoctorData>> getDoctors({
    required String token,
    String? doctorId,
    String? filter,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.doctorDataRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    if (doctorId != null && doctorId.isNotEmpty) {
      headers['doctorid'] = doctorId;
    }
    if (filter != null && filter.isNotEmpty) {
      headers['filter'] = filter;
    }

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(response.body);

        if (decoded is List) {
          return decoded.map<DoctorData>((json) {
            try {
              return DoctorData.fromJson(json);
            } catch (e) {
              rethrow;
            }
          }).toList();
        } else if (decoded is Map<String, dynamic>) {
          return [DoctorData.fromJson(decoded)];
        } else {
          throw Exception('Unexpected doctor data format: $decoded');
        }
      } catch (e) {
        throw Exception('Failed to process doctor data: $e');
      }
    } else {
      throw Exception(
        'Failed to GET doctors (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// POST /api/auth/register (role=doctor)
  /// Using camelCase keys to match your updated model.
  Future<DoctorData> createDoctor({
    required String token,
    required String persId,
    required String name,
    required String password,
    required String email,
    required String mobileNumber,
    required String birthDate,
    required List<String> licenses,
    required String description,
    required String hospitalId,
    required bool suspended,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.registerRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    final body = {
      "persId": persId,
      "name": name,
      "role": "doctor",
      "password": password,
      "email": email,
      "mobileNumber": mobileNumber,
      "birthDate": birthDate,
      "licenses": licenses,
      "description": description,
      "hospital": hospitalId,
      "suspended": suspended,
    };

    final response =
        await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(response.body);
      return DoctorData.fromJson(decoded);
    } else {
      throw Exception(
        'Failed to create doctor (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// PUT /api/doctor/data/update
  /// - Must include "doctorid" in headers.
  /// - The updatedFields map should use camelCase keys.
  Future<DoctorData> updateDoctor({
    required String token,
    required String doctorId,
    required Map<String, dynamic> updatedFields,
  }) async {
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.doctorDataUpdateRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    headers['doctorid'] = doctorId;

    final response =
        await http.put(url, headers: headers, body: jsonEncode(updatedFields));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return DoctorData.fromJson(decoded);
    } else {
      throw Exception(
        'Failed to update doctor (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// DELETE /api/doctor/delete
  /// - Must include "doctorid" in headers.
  Future<void> deleteDoctor({
    required String token,
    required String doctorId,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.doctorDeleteRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    headers['doctorid'] = doctorId;

    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete doctor (${response.statusCode}): ${response.body}',
      );
    }
  }
}
