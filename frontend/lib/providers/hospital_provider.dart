// lib/providers/hospital_provider.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/utils/static.dart';
import 'package:frontend/models/hospital_data.dart';

class HospitalProvider {
  // GET /api/hospital/data
  Future<List<HospitalData>> getHospitals({
    required String token,
    required String hospitalId,
    required String filter, // "suspended" or "unsuspended"
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.hospitalDataRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    if (hospitalId.isNotEmpty) {
      headers['hospitalid'] = hospitalId;
    }
    headers['filter'] = filter;

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        return decoded.map((item) => HospitalData.fromJson(item)).toList();
      } else {
        throw Exception('Unexpected response format: $decoded');
      }
    } else {
      throw Exception('Failed to fetch hospitals: ${response.body}');
    }
  }

  // POST /api/hospital/register
  Future<HospitalData> createHospital({
    required String token,
    required String hospitalName,
    required String hospitalAddress,
    required List<String> mobileNumbers,
    required List<String> emails,
  }) async {
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.hospitalRegisterRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    final body = {
      'hospital_name': hospitalName,
      'hospital_address': hospitalAddress,
      'mobile_numbers': mobileNumbers,
      'emails': emails,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return HospitalData.fromJson(decoded);
    } else {
      throw Exception('Failed to create hospital: ${response.body}');
    }
  }

  // PUT /api/hospital/data/update  (instead of POST)
  // Must pass hospitalId in headers, and the updated fields in body.
  Future<HospitalData> updateHospital({
    required String token,
    required String hospitalId,
    required Map<String, dynamic> updatedFields,
  }) async {
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.hospitalUpdateRoute}');
    final headers = ClassUtil.baseHeaders(token: token);
    headers['hospitalid'] = hospitalId; // Must be set

    // The backend expects a PUT, not POST
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(updatedFields),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return HospitalData.fromJson(decoded);
    } else {
      throw Exception('Failed to update hospital: ${response.body}');
    }
  }

  // DELETE /api/hospital/delete
  Future<void> deleteHospital({
    required String token,
    required String hospitalId,
  }) async {
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.hospitalDeleteRoute}');
    final headers = ClassUtil.baseHeaders(token: token);
    headers['hospitalid'] = hospitalId;

    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete hospital: ${response.body}');
    }
  }
}
