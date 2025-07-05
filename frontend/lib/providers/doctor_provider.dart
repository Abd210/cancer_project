import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/models/doctor_data.dart';
import 'package:frontend/utils/static.dart';

class DoctorProvider {
  // ------------------------------------------------------------------
  // GET  /api/doctor/data
  // ------------------------------------------------------------------
  Future<List<DoctorData>> getDoctors({
    required String token,
    String? doctorId,
    String? filter,
    String? hospitalId,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.doctorDataRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    if (_isNotEmpty(doctorId)) headers['doctorid'] = doctorId!;
    if (_isNotEmpty(filter)) headers['filter'] = filter!;
    if (_isNotEmpty(hospitalId)) headers['hospitalid'] = hospitalId!;

    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      if (decoded is List) {
        return decoded.map<DoctorData>((e) => DoctorData.fromJson(e)).toList();
      } else if (decoded is Map<String, dynamic>) {
        return [DoctorData.fromJson(decoded)];
      }
      throw Exception('Unexpected doctor payload: $decoded');
    }
    throw Exception(
      'Doctor GET failed [${res.statusCode}]: ${res.body}',
    );
  }

  // ------------------------------------------------------------------
  // GET  /api/doctor/public-data
  // ------------------------------------------------------------------
  Future<DoctorData> getDoctorPublicData({
    required String token,
    required String doctorId,
  }) async {
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.doctorPublicDataRoute}');
    final headers = ClassUtil.baseHeaders(token: token);
    headers['doctorid'] = doctorId;

    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      if (decoded is Map<String, dynamic>) {
        return DoctorData.fromJson(decoded);
      }
      throw Exception('Unexpected doctor public data payload: $decoded');
    }
    throw Exception(
      'Doctor public data GET failed [${res.statusCode}]: ${res.body}',
    );
  }

  // ------------------------------------------------------------------
  // POST  /api/auth/register  (role = doctor)
  // ------------------------------------------------------------------
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
    List<String> patients = const [],
    List<Map<String, String>> schedule = const [],
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.registerRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    final body = jsonEncode({
      'persId': persId,
      'name': name,
      'role': 'doctor',
      'password': password,
      'email': email,
      'mobileNumber': mobileNumber,
      'birthDate': birthDate,
      'licenses': licenses,
      'description': description,
      'hospital': hospitalId,
      'suspended': suspended,
      'patients': patients,
      'schedule': schedule,
    });

    final res = await http.post(url, headers: headers, body: body);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return DoctorData.fromJson(json.decode(res.body));
    }
    throw Exception(
      'Doctor create failed [${res.statusCode}]: ${res.body}',
    );
  }

  // ------------------------------------------------------------------
  // PUT  /api/doctor/data/update
  // ------------------------------------------------------------------
  Future<bool> updateDoctor({
    required String token,
    required String doctorId,
    required Map<String, dynamic> updatedFields,
  }) async {
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.doctorDataUpdateRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['doctorid'] = doctorId;

    final res =
        await http.put(url, headers: headers, body: jsonEncode(updatedFields));
    if (res.statusCode == 200) {
      // Success - the response might be a string or a DoctorData object
      // We just return true to indicate success
      return true;
    }
    throw Exception(
      'Doctor update failed [${res.statusCode}]: ${res.body}',
    );
  }

  // ------------------------------------------------------------------
  // DELETE  /api/doctor/delete
  // ------------------------------------------------------------------
  Future<void> deleteDoctor({
    required String token,
    required String doctorId,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.doctorDeleteRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['doctorid'] = doctorId;

    final res = await http.delete(url, headers: headers);
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
        'Doctor delete failed [${res.statusCode}]: ${res.body}',
      );
    }
  }

  // helper ------------------------------------------------------------
  bool _isNotEmpty(String? v) => v != null && v.trim().isNotEmpty;
}
