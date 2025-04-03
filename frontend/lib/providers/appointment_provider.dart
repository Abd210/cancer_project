// lib/providers/appointment_provider.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/models/appointment_data.dart';
import 'package:frontend/utils/static.dart';

class AppointmentProvider {
  Future<List<AppointmentData>> getAppointmentsHistory({
    required String token,
    required String suspendfilter,
    required String filterbyrole,
    required String filterbyid,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentHistoryRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    headers["suspendfilter"] = suspendfilter;
    headers["filterbyrole"] = filterbyrole;
    headers["filterbyid"] = filterbyid;

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        final list = decoded.map((item) => AppointmentData.fromJson(item)).toList();
        return List<AppointmentData>.from(list);
      } else {
        throw Exception('Unexpected format while fetching appointments history');
      }
    } else {
      throw Exception(
        'Failed to get appointment history [${response.statusCode}]: ${response.body}',
      );
    }
  }

  Future<AppointmentData> createAppointment({
    required String token,
    required String patientId,
    required String doctorId,
    required DateTime date,
    required String purpose,
    required String status,
    bool suspended = false,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentNewRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    final body = {
      "patient": patientId,
      "doctor": doctorId,
      "appointmentDate": date.toIso8601String().split("T").first,
      "purpose": purpose,
      "status": status,
      "suspended": suspended,
    };

    final response = await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded["new_appointment"] != null) {
        return AppointmentData.fromJson(decoded["new_appointment"]);
      } else {
        throw Exception('Unexpected create response: $decoded');
      }
    } else {
      throw Exception(
        'Failed to create appointment [${response.statusCode}]: ${response.body}',
      );
    }
  }

  Future<AppointmentData> updateAppointment({
    required String token,
    required String appointmentId,
    required Map<String, dynamic> updatedFields,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentUpdateRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    // Pass appointmentId in updatedFields if required
    updatedFields["appointmentid"] = appointmentId;

    final response = await http.put(url, headers: headers, body: jsonEncode(updatedFields));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return AppointmentData.fromJson(decoded);
    } else {
      throw Exception(
        'Failed to update appointment [${response.statusCode}]: ${response.body}',
      );
    }
  }

  Future<void> deleteAppointment({
    required String token,
    required String appointmentId,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentDeleteRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    headers["appointmentid"] = appointmentId;

    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete appointment [${response.statusCode}]: ${response.body}',
      );
    }
  }
}
