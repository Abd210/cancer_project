import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/models/appointment_data.dart';
import 'package:frontend/utils/static.dart';

class AppointmentProvider {
  // ------------------------------------------------------------------
  // HISTORY   /appointment/history
  // ------------------------------------------------------------------
  Future<List<AppointmentData>> getAppointmentsHistory({
    required String token,
    required String suspendfilter,   // all | suspended | unsuspended
    String? filterByRole,            // patient | doctor
    String? filterById,
  }) async {
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentHistoryRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['suspendfilter'] = suspendfilter;
    if (_notEmpty(filterByRole)) headers['filterbyrole'] = filterByRole!;
    if (_notEmpty(filterById))   headers['filterbyid']   = filterById!;

    final res = await http.get(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception(
        'History GET failed [${res.statusCode}]: ${res.body}',
      );
    }
    return (json.decode(res.body) as List)
        .map<AppointmentData>((e) => AppointmentData.fromJson(e))
        .toList();
  }

  // ------------------------------------------------------------------
  // CREATE  /appointment/new
  // ------------------------------------------------------------------
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
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentNewRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    final body = jsonEncode({
      'patient': patientId,
      'doctor': doctorId,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'purpose': purpose,
      'status': status,
      'suspended': suspended,
    });

    final res = await http.post(url, headers: headers, body: body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
        'Create failed [${res.statusCode}]: ${res.body}',
      );
    }
    return AppointmentData.fromJson(json.decode(res.body));
  }

  // ------------------------------------------------------------------
  // UPDATE  /appointment/update
  // ------------------------------------------------------------------
  Future<void> updateAppointment({
    required String token,
    required String appointmentId,
    required Map<String, dynamic> updatedFields,
  }) async {
    print('DEBUG UPDATE: appointmentId = $appointmentId');
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentUpdateRoute}');
    final headers =
        ClassUtil.baseHeaders(token: token)..['appointmentid'] = appointmentId;
    
    print('DEBUG UPDATE: Headers = $headers');
    print('DEBUG UPDATE: Body = ${jsonEncode(updatedFields)}');

    final res =
        await http.put(url, headers: headers, body: jsonEncode(updatedFields));
    print('DEBUG UPDATE: Status code = ${res.statusCode}');
    print('DEBUG UPDATE: Response body = ${res.body}');
    
    if (res.statusCode != 200) {
      throw Exception(
        'Update failed [${res.statusCode}]: ${res.body}',
      );
    }
  }

  // ------------------------------------------------------------------
  // CANCEL  /appointment/cancel
  // ------------------------------------------------------------------
  Future<void> cancelAppointment({
    required String token,
    required String appointmentId,
  }) async {
    print('DEBUG CANCEL: appointmentId = $appointmentId');
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentCancelRoute}');
    final headers =
        ClassUtil.baseHeaders(token: token)..['appointment_id'] = appointmentId;
    
    print('DEBUG CANCEL: Headers = $headers');

    final res = await http.post(url, headers: headers);
    print('DEBUG CANCEL: Status code = ${res.statusCode}');
    print('DEBUG CANCEL: Response body = ${res.body}');
    
    if (res.statusCode != 200) {
      throw Exception(
        'Cancel failed [${res.statusCode}]: ${res.body}',
      );
    }
  }

  // ------------------------------------------------------------------
  // DELETE  /appointment/delete
  // ------------------------------------------------------------------
  Future<void> deleteAppointment({
    required String token,
    required String appointmentId,
  }) async {
    print('DEBUG DELETE: appointmentId = $appointmentId');
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentDeleteRoute}');
    final headers =
        ClassUtil.baseHeaders(token: token)..['appointment_id'] = appointmentId;
    
    print('DEBUG DELETE: Headers = $headers');

    final res = await http.delete(url, headers: headers);
    print('DEBUG DELETE: Status code = ${res.statusCode}');
    print('DEBUG DELETE: Response body = ${res.body}');
    
    if (res.statusCode != 200) {
      throw Exception(
        'Delete failed [${res.statusCode}]: ${res.body}',
      );
    }
  }

  // ------------------------------------------------------------------
  // UPCOMING (entity)  /appointment/upcoming
  // ------------------------------------------------------------------
  Future<List<AppointmentData>> getUpcoming({
    required String token,
    required String entityRole,   // patient | doctor
    required String entityId,
    String suspendfilter = 'all',
  }) async {
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentUpcomingRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['entity_role']   = entityRole
      ..['entity_id']     = entityId
      ..['suspendfilter'] = suspendfilter;

    final res = await http.get(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception(
        'Upcoming GET failed [${res.statusCode}]: ${res.body}',
      );
    }
    return (json.decode(res.body) as List)
        .map<AppointmentData>((e) => AppointmentData.fromJson(e))
        .toList();
  }

  // ------------------------------------------------------------------
  // UPCOMING (all)  /appointment/upcoming/all
  // ------------------------------------------------------------------
  Future<List<AppointmentData>> getUpcomingAll({
    required String token,
    String suspendfilter = 'all',
  }) async {
    final url = Uri.parse(
        '${ClassUtil.baseUrl}${ClassUtil.appointmentUpcomingAllRoute}');
    final headers =
        ClassUtil.baseHeaders(token: token)..['suspendfilter'] = suspendfilter;

    final res = await http.get(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception(
        'UpcomingAll GET failed [${res.statusCode}]: ${res.body}',
      );
    }
    return (json.decode(res.body) as List)
        .map<AppointmentData>((e) => AppointmentData.fromJson(e))
        .toList();
  }

  // ------------------------------------------------------------------
  // UPCOMING (hospital)  /appointment/hospital/upcoming
  // ------------------------------------------------------------------
  Future<List<AppointmentData>> getHospitalUpcoming({
    required String token,
    required String hospitalId,
    String suspendfilter = 'all',
  }) async {
    final url = Uri.parse(
        '${ClassUtil.baseUrl}${ClassUtil.appointmentHospitalUpcomingRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['hospitalid']   = hospitalId
      ..['suspendfilter'] = suspendfilter;

    final res = await http.get(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception(
        'Hospital upcoming failed [${res.statusCode}]: ${res.body}',
      );
    }
    return (json.decode(res.body) as List)
        .map<AppointmentData>((e) => AppointmentData.fromJson(e))
        .toList();
  }

  // ------------------------------------------------------------------
  // HISTORY (hospital)  /appointment/hospital/history
  // ------------------------------------------------------------------
  Future<List<AppointmentData>> getHospitalHistory({
    required String token,
    required String hospitalId,
    String suspendfilter = 'all',
  }) async {
    final url = Uri.parse(
        '${ClassUtil.baseUrl}${ClassUtil.appointmentHospitalHistoryRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['hospitalid']   = hospitalId
      ..['suspendfilter'] = suspendfilter;

    final res = await http.get(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception(
        'Hospital history failed [${res.statusCode}]: ${res.body}',
      );
    }
    return (json.decode(res.body) as List)
        .map<AppointmentData>((e) => AppointmentData.fromJson(e))
        .toList();
  }

  // helper ------------------------------------------------------------
  bool _notEmpty(String? v) => v != null && v.trim().isNotEmpty;
}
