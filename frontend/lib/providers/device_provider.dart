import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/models/device_data.dart'; // Assuming DeviceData model exists
import 'package:frontend/utils/static.dart';

class DeviceProvider {
  // ------------------------------------------------------------------
  // GET DATA   /device/data
  // ------------------------------------------------------------------
  Future<List<DeviceData>> getDevices({
    required String token,
    String? filter, // all | suspended | unsuspended
    String? deviceId,
    String? patientId,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.deviceDataRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    if (_notEmpty(filter)) headers['filter'] = filter!;
    if (_notEmpty(deviceId)) headers['deviceid'] = deviceId!;
    if (_notEmpty(patientId)) headers['patientid'] = patientId!;

    final res = await http.get(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception(
        'Device GET failed [${res.statusCode}]: ${res.body}',
      );
    }
    // If a specific deviceId was requested, the response is a single object, not a list
    if (_notEmpty(deviceId)) {
      return [DeviceData.fromJson(json.decode(res.body))];
    }
    // Otherwise, it's a list
    return (json.decode(res.body) as List)
        .map<DeviceData>((e) => DeviceData.fromJson(e))
        .toList();
  }

  // ------------------------------------------------------------------
  // CREATE  /device/new
  // ------------------------------------------------------------------
  Future<DeviceData> createDevice({
    required String token,
    required String type,
    String? patientId,
    bool suspended = false,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.deviceNewRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    final body = jsonEncode({
      'type': type,
      if (_notEmpty(patientId)) 'patient': patientId,
      'suspended': suspended,
    });

    final res = await http.post(url, headers: headers, body: body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
        'Device Create failed [${res.statusCode}]: ${res.body}',
      );
    }
    return DeviceData.fromJson(json.decode(res.body));
  }

  // ------------------------------------------------------------------
  // UPDATE  /device/update
  // ------------------------------------------------------------------
  Future<void> updateDevice({
    required String token,
    required String deviceId,
    required Map<String, dynamic> updatedFields,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.deviceUpdateRoute}');
    final headers = ClassUtil.baseHeaders(token: token)..['deviceid'] = deviceId;

    // Ensure patient field is handled correctly (allow setting to null/empty)
    if (updatedFields.containsKey('patient') && updatedFields['patient'] == null) {
      updatedFields['patient'] = ''; // Send empty string if unassigning
    }

    final res =
        await http.put(url, headers: headers, body: jsonEncode(updatedFields));
    if (res.statusCode != 200) {
      throw Exception(
        'Device Update failed [${res.statusCode}]: ${res.body}',
      );
    }
  }

  // ------------------------------------------------------------------
  // DELETE  /device/delete
  // ------------------------------------------------------------------
  Future<void> deleteDevice({
    required String token,
    required String deviceId,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.deviceDeleteRoute}');
    final headers = ClassUtil.baseHeaders(token: token)..['deviceid'] = deviceId;

    final res = await http.delete(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception(
        'Device Delete failed [${res.statusCode}]: ${res.body}',
      );
    }
  }

  // helper ------------------------------------------------------------
  bool _notEmpty(String? v) => v != null && v.trim().isNotEmpty;
}

