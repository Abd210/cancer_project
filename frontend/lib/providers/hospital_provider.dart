import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/utils/static.dart';
import 'package:frontend/models/hospital_data.dart';

class HospitalProvider {
  Future<List<HospitalData>> getHospitals({
    required String token,
    String? hospitalId,
    String? filter,
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
      if (decoded is List) {
        return decoded.map((e) => HospitalData.fromJson(e)).toList();
      } else if (decoded is Map<String, dynamic>) {
        return [HospitalData.fromJson(decoded)];
      }
    }
    throw Exception('Failed to fetch hospitals: ${response.statusCode}');
  }

  Future<HospitalData> createHospital({
    required String token,
    required String hospitalName,
    required String hospitalAddress,
    required List<String> mobileNumbers,
    required List<String> emails,
    bool suspended = false,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.hospitalRegisterRoute}');
    final headers = ClassUtil.baseHeaders(token: token);
    final body = jsonEncode({
      'name': hospitalName,
      'address': hospitalAddress,
      'mobileNumbers': mobileNumbers,
      'emails': emails,
      'suspended': suspended,
    });

    final resp = await http.post(url, headers: headers, body: body);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return HospitalData.fromJson(json.decode(resp.body));
    }
    throw Exception('Failed to create hospital: ${resp.statusCode}');
  }

  /// NOTE: backend just returns a success message, so we lose the returned data.
  Future<void> updateHospital({
    required String token,
    required String hospitalId,
    required Map<String, dynamic> updatedFields,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.hospitalUpdateRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['hospitalid'] = hospitalId;
    final resp = await http.put(url, headers: headers, body: jsonEncode(updatedFields));
    if (resp.statusCode != 200) {
      throw Exception('Failed to update hospital: ${resp.statusCode}');
    }
  }

  Future<void> deleteHospital({
    required String token,
    required String hospitalId,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.hospitalDeleteRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['hospitalid'] = hospitalId;
    final resp = await http.delete(url, headers: headers);
    // Accept 200 OK OR 204 No Content
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Failed to delete hospital: ${resp.statusCode}');
    }
  }
}
