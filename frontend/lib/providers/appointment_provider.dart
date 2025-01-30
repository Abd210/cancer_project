// lib/providers/appointment_provider.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/models/appointment_data.dart';
import 'package:frontend/utils/static.dart';

class AppointmentProvider {
  /// GET => /api/appointment/history
  /// with custom headers:
  ///   suspendfilter, filterbyrole, filterbyid
  Future<List<AppointmentData>> getAppointmentsHistory({
    required String token,
    required String suspendfilter,   // "unsuspended" or "suspended"
    required String filterbyrole,    // "patient", "doctor", or "admin"? ...
    required String filterbyid,      // e.g. "67731e4f23997df9d739418a"
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentHistoryRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    headers["suspendfilter"] = suspendfilter;
    headers["filterbyrole"] = filterbyrole;
    headers["filterbyid"] = filterbyid;

    print('[DEBUG] GET history appointments => headers=$headers');

    final response = await http.get(url, headers: headers);
    print('[DEBUG] response status=${response.statusCode}, body=${response.body}');

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        final list = decoded.map((item) => AppointmentData.fromJson(item)).toList();
        print('[DEBUG] parsed appointments length=${list.length}');
        return List<AppointmentData>.from(list);
      } else {
        print('[DEBUG] Unexpected format: $decoded');
        throw Exception('Unexpected format while fetching appointments history');
      }
    } else {
      throw Exception(
        'Failed to get appointment history [${response.statusCode}]: ${response.body}',
      );
    }
  }

  /// POST => /api/appointment/new
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
      "appointment_date": date.toIso8601String().split("T").first,
      "purpose": purpose,
      "status": status,
      "suspended": suspended,
    };
    print('[DEBUG] Creating appointment => body=$body');

    final response = await http.post(url, headers: headers, body: jsonEncode(body));
    print('[DEBUG] create response => code=${response.statusCode}, body=${response.body}');

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

  /// PUT => /api/appointment/update
  Future<AppointmentData> updateAppointment({
    required String token,
    required String appointmentId,
    required Map<String, dynamic> updatedFields,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentUpdateRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    // According to your doc, we might pass appointmentid in the body
    updatedFields["appointmentid"] = appointmentId;
    print('[DEBUG] Updating appt $appointmentId => fields=$updatedFields');

    final response = await http.put(url, headers: headers, body: jsonEncode(updatedFields));
    print('[DEBUG] update response => code=${response.statusCode}, body=${response.body}');

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return AppointmentData.fromJson(decoded);
    } else {
      throw Exception(
        'Failed to update appointment [${response.statusCode}]: ${response.body}',
      );
    }
  }

  /// DELETE => /api/appointment/delete
  Future<void> deleteAppointment({
    required String token,
    required String appointmentId,
  }) async {
    final url = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentDeleteRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    headers["appointmentid"] = appointmentId;
    print('[DEBUG] Deleting appt $appointmentId => headers=$headers');

    final response = await http.delete(url, headers: headers);
    print('[DEBUG] delete response => code=${response.statusCode}, body=${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete appointment [${response.statusCode}]: ${response.body}',
      );
    }
  }
}
