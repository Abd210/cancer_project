// lib/providers/hospital_provider.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/utils/static.dart';
import 'package:frontend/models/hospital_data.dart';

class HospitalProvider {
  /// ---------------------------------------------------------------
  ///  GET /api/hospital/data
  ///     - If "hospitalid" is set, we may get a single object (Map).
  ///     - If "filter" is set, or no hospitalid, we often get a list.
  /// ---------------------------------------------------------------
  Future<List<HospitalData>> getHospitals({
    required String token,
    String? hospitalId, // made optional
    String? filter,     // made optional
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.hospitalDataRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    if (hospitalId != null && hospitalId.isNotEmpty) {
      headers['hospitalid'] = hospitalId;
    }
    if (filter != null && filter.isNotEmpty) {
      headers['filter'] = filter;
    }

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      // 1) If the backend returned a List => parse each item.
      if (decoded is List) {
        return decoded.map((item) => HospitalData.fromJson(item)).toList();
      }
      // 2) If the backend returned a single object => wrap it in a List of length 1
      else if (decoded is Map<String, dynamic>) {
        return [HospitalData.fromJson(decoded)];
      }
      // 3) Otherwise => unknown response format
      else {
        throw Exception('Unexpected response format: $decoded');
      }
    } else {
      throw Exception(
        'Failed to fetch hospitals: ${response.statusCode}, body: ${response.body}',
      );
    }
  }

  /// ---------------------------------------------------------------
  ///  POST /api/hospital/register
  /// ---------------------------------------------------------------
  Future<HospitalData> createHospital({
    required String token,
    required String hospitalName,
    required String hospitalAddress,
    required List<String> mobileNumbers,
    required List<String> emails,
    bool suspended = false, // optionally allow specifying suspension
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.hospitalRegisterRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    final body = {
      'hospital_name': hospitalName,
      'hospital_address': hospitalAddress,
      'mobile_numbers': mobileNumbers,
      'emails': emails,
      // If you need to pass a "suspended" field upon creation:
      'suspended': suspended,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    // In your original API doc, the response can be 200 or 201. 
    // Use whichever your backend truly returns. 
    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(response.body);
      return HospitalData.fromJson(decoded);
    } else {
      throw Exception(
        'Failed to create hospital (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// ---------------------------------------------------------------
  ///  PUT /api/hospital/data/update
  ///     - Must pass hospitalId in headers, body in JSON.
  /// ---------------------------------------------------------------
  Future<HospitalData> updateHospital({
    required String token,
    required String hospitalId,
    required Map<String, dynamic> updatedFields,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.hospitalUpdateRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    headers['hospitalid'] = hospitalId;

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(updatedFields),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return HospitalData.fromJson(decoded);
    } else {
      throw Exception(
        'Failed to update hospital (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// ---------------------------------------------------------------
  ///  DELETE /api/hospital/delete
  ///     - Must pass hospitalId in headers
  /// ---------------------------------------------------------------
  Future<void> deleteHospital({
    required String token,
    required String hospitalId,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.hospitalDeleteRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    headers['hospitalid'] = hospitalId;

    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete hospital (${response.statusCode}): ${response.body}',
      );
    }
  }
}
