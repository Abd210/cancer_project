// lib/providers/test_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/utils/static.dart';

class TestProvider {
  //--------------------------------------------------------------------
  // CREATE
  //--------------------------------------------------------------------
  Future<void> createTest({
    required String token,
    required String patientId,
    required String doctorId,
    required String purpose,
    required String resultDate, // yyyy‑MM‑dd
    required String status,
    required String review,
    bool suspended = false,
  }) async {
    final url     = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.testNewRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    final body = jsonEncode({
      'patient'   : patientId,
      'doctor'    : doctorId,
      'purpose'   : purpose,
      'resultDate': resultDate,
      'status'    : status,
      'review'    : review,
      'suspended' : suspended,
    });

    final res = await http.post(url, headers: headers, body: body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Test create failed [${res.statusCode}]: ${res.body}');
    }
  }

  //--------------------------------------------------------------------
  // UPDATE
  //--------------------------------------------------------------------
  Future<void> updateTest({
    required String token,
    required String testId,
    required Map<String,dynamic> updatedFields,
  }) async {
    final url     = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.testUpdateRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['testid'] = testId;

    final res = await http.put(url,
        headers: headers, body: jsonEncode(updatedFields));
    if (res.statusCode != 200) {
      throw Exception('Test update failed [${res.statusCode}]: ${res.body}');
    }
  }

  //--------------------------------------------------------------------
  // DELETE
  //--------------------------------------------------------------------
  Future<void> deleteTest({
    required String token,
    required String testId,
  }) async {
    final url     = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.testDeleteRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['testid'] = testId;

    final res = await http.delete(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Test delete failed [${res.statusCode}]: ${res.body}');
    }
  }
}
