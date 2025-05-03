// lib/providers/admin_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/utils/static.dart';
import 'package:frontend/models/admin_data.dart'; // make sure this model exists

class AdminProvider {
  //--------------------------------------------------------------------
  // GET
  //--------------------------------------------------------------------
  Future<List<AdminData>> getAdmins({
    required String token,
    String? adminId,
    String? filter,
    String? hospitalId,
  }) async {
    final url     = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.adminDataRoute}');
    final headers = ClassUtil.baseHeaders(token: token);
    if (adminId    != null) headers['adminid']   = adminId;
    if (filter     != null) headers['filter']    = filter;
    if (hospitalId != null) headers['hospitalid']= hospitalId;

    final res = await http.get(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Admin GET failed [${res.statusCode}]: ${res.body}');
    }
    final data = json.decode(res.body);
    if (data is List) {
      return data.map<AdminData>((e) => AdminData.fromJson(e)).toList();
    } else if (data is Map<String,dynamic>) {
      return [AdminData.fromJson(data)];
    } else {
      throw Exception('Unexpected admin payload: $data');
    }
  }

  //--------------------------------------------------------------------
  // UPDATE
  //--------------------------------------------------------------------
  Future<void> updateAdmin({
    required String token,
    required String adminId,
    required Map<String,dynamic> updatedFields,
  }) async {
    final url     = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.adminDataUpdateRoute}');
    final headers = ClassUtil.baseHeaders(token: token)..['adminid'] = adminId;

    final res = await http.put(url,
        headers: headers, body: jsonEncode(updatedFields));
    if (res.statusCode != 200) {
      throw Exception('Admin update failed [${res.statusCode}]: ${res.body}');
    }
  }

  //--------------------------------------------------------------------
  // DELETE
  //--------------------------------------------------------------------
  Future<void> deleteAdmin({
    required String token,
    required String adminId,
  }) async {
    final url     = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.adminDeleteRoute}');
    final headers = ClassUtil.baseHeaders(token: token)..['adminid'] = adminId;

    final res = await http.delete(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Admin delete failed [${res.statusCode}]: ${res.body}');
    }
  }
}
