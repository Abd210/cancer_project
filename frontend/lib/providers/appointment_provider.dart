// lib/providers/appointment_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/models/appointment_data.dart';
import 'package:frontend/utils/static.dart';

class AppointmentProvider {
  //--------------------------------------------------------------------
  // HISTORY
  //--------------------------------------------------------------------
  Future<List<AppointmentData>> getAppointmentsHistory({
    required String token,
    required String suspendfilter,   // all | suspended | unsuspended
    String? filterByRole,            // patient | doctor (optional)
    String? filterById,              // entity ID when filterByRole set
  }) async {
    final url     = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentHistoryRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['suspendfilter'] = suspendfilter;
    if (filterByRole != null) headers['filterbyrole'] = filterByRole;
    if (filterById   != null) headers['filterbyid']   = ClassUtil.strId(filterById);

    final res = await http.get(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception('History GET failed [${res.statusCode}]: ${res.body}');
    }
    final body = json.decode(res.body);
    return (body as List)
        .map<AppointmentData>((e) => AppointmentData.fromJson(e))
        .toList();
  }

  //--------------------------------------------------------------------
  // CREATE
  //--------------------------------------------------------------------
  Future<AppointmentData> createAppointment({
    required String token,
    required String patientId,
    required String doctorId,
    required DateTime start,
    required DateTime end,
    required String purpose,
    required String status,
    bool suspended = false,
  }) async {
    final url     = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentNewRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    final body = jsonEncode({
      'patient'  : patientId,
      'doctor'   : doctorId,
      'start'    : start.toIso8601String(),
      'end'      : end.toIso8601String(),
      'purpose'  : purpose,
      'status'   : status,
      'suspended': suspended,
    });

    final res = await http.post(url, headers: headers, body: body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Create failed [${res.statusCode}]: ${res.body}');
    }
    return AppointmentData.fromJson(json.decode(res.body));
  }

  //--------------------------------------------------------------------
  // UPDATE
  //--------------------------------------------------------------------
  Future<void> updateAppointment({
    required String token,
    required String appointmentId,
    required Map<String,dynamic> updatedFields,
  }) async {
    final url     = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentUpdateRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['appointmentid'] = appointmentId;

    final res = await http.put(url,
        headers: headers, body: jsonEncode(updatedFields));
    if (res.statusCode != 200) {
      throw Exception('Update failed [${res.statusCode}]: ${res.body}');
    }
  }

  //--------------------------------------------------------------------
  // CANCEL (soft‑delete via POST)  ------------------------------------
  Future<void> cancelAppointment({
    required String token,
    required String appointmentId,
  }) async {
    final url     = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentCancelRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['appointmentid'] = appointmentId;

    final res = await http.post(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Cancel failed [${res.statusCode}]: ${res.body}');
    }
  }

  //--------------------------------------------------------------------
  // HARD DELETE -------------------------------------------------------
  Future<void> deleteAppointment({
    required String token,
    required String appointmentId,
  }) async {
    final url     = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentDeleteRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['appointmentid'] = appointmentId;

    final res = await http.delete(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Delete failed [${res.statusCode}]: ${res.body}');
    }
  }

  //--------------------------------------------------------------------
  // UPCOMING (entity) -------------------------------------------------
  Future<List<AppointmentData>> getUpcoming({
    required String token,
    required String entityRole,   // patient | doctor
    required String entityId,
    String suspendfilter = 'all', // default same as backend
  }) async {
    final url     = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentUpcomingRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['entity_role']   = entityRole
      ..['entity_id']     = entityId
      ..['suspendfilter'] = suspendfilter;

    final res = await http.get(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Upcoming GET failed [${res.statusCode}]: ${res.body}');
    }
    return (json.decode(res.body) as List)
        .map<AppointmentData>((e) => AppointmentData.fromJson(e))
        .toList();
  }

  //--------------------------------------------------------------------
  // UPCOMING (all) ----------------------------------------------------
  Future<List<AppointmentData>> getUpcomingAll({
    required String token,
    String suspendfilter = 'all',
  }) async {
    final url     = Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentUpcomingAllRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['suspendfilter'] = suspendfilter;

    final res = await http.get(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception('UpcomingAll GET failed [${res.statusCode}]: ${res.body}');
    }
    return (json.decode(res.body) as List)
        .map<AppointmentData>((e) => AppointmentData.fromJson(e))
        .toList();
  }
}
