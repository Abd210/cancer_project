import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/models/appointment_data.dart';
import 'package:frontend/utils/static.dart';
import 'package:frontend/main.dart'
    show httpClient, Logger; // Import custom Logger and httpClient

class AppointmentProvider {
  // ------------------------------------------------------------------
  // HISTORY   /appointment/history
  // ------------------------------------------------------------------
  Future<List<AppointmentData>> getAppointmentsHistory({
    required String token,
    required String suspendfilter, // all | suspended | unsuspended
    String? filterByRole, // patient | doctor
    String? filterById,
  }) async {
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentHistoryRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    // IMPORTANT: The backend expects these exact lowercase header keys
    headers['filterbyid'] = filterById ?? '';
    headers['filterbyrole'] = filterByRole ?? '';
    headers['suspendfilter'] = suspendfilter;

    try {
      Logger.log('Fetching appointment history: $url, headers: $headers');
      final res = await httpClient.get(url, headers: headers);
      // Only log a small part of the body to avoid huge logs
      if (res.body.isNotEmpty) {
        Logger.log(
            'Appointment history response: ${res.statusCode} - ${res.body.substring(0, min(100, res.body.length))}...');
      } else {
        Logger.log(
            'Appointment history response: ${res.statusCode} - Empty body');
      }

      if (res.statusCode != 200) {
        throw Exception(
          'History GET failed [${res.statusCode}]: ${res.body}',
        );
      }

      final bodyJson = json.decode(res.body);
      Logger.log(
          'Successfully decoded appointment history JSON, found ${bodyJson is List ? bodyJson.length : 0} appointments');

      return (bodyJson as List)
          .map<AppointmentData>((e) => AppointmentData.fromJson(e))
          .toList();
    } catch (e) {
      Logger.log('Error in getAppointmentsHistory: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  // GET DOCTOR APPOINTMENTS - combines upcoming and history
  // ------------------------------------------------------------------
  Future<List<AppointmentData>> getAppointmentsForDoctor({
    required String token,
    required String doctorId,
    String suspendfilter = 'unsuspended',
  }) async {
    try {
      Logger.log('getAppointmentsForDoctor: Starting with doctorId=$doctorId');

      // Get upcoming appointments
      List<AppointmentData> upcomingList = await getUpcoming(
        token: token,
        entityRole: 'doctor',
        entityId: doctorId,
        suspendfilter: suspendfilter,
      );
      Logger.log(
          'getAppointmentsForDoctor: Got ${upcomingList.length} upcoming appointments');

      // Get past appointments
      final pastList = await getAppointmentsHistory(
        token: token,
        suspendfilter: suspendfilter,
        filterByRole: 'doctor',
        filterById: doctorId,
      );
      Logger.log(
          'getAppointmentsForDoctor: Got ${pastList.length} past appointments');

      // Combine both lists
      final allAppointments = [...pastList, ...upcomingList];

      // Sort by date (newest first)
      allAppointments.sort((a, b) => b.start.compareTo(a.start));

      Logger.log(
          'getAppointmentsForDoctor: Returning ${allAppointments.length} total appointments');
      return allAppointments;
    } catch (e) {
      Logger.log('Error in getAppointmentsForDoctor: $e');
      rethrow;
    }
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

    try {
      final res = await httpClient.post(url, headers: headers, body: body);
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception(
          'Create failed [${res.statusCode}]: ${res.body}',
        );
      }
      return AppointmentData.fromJson(json.decode(res.body));
    } catch (e) {
      Logger.log('Error in createAppointment: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  // UPDATE  /appointment/update
  // ------------------------------------------------------------------
  Future<void> updateAppointment({
    required String token,
    required String appointmentId,
    required Map<String, dynamic> updatedFields,
  }) async {
    Logger.log('DEBUG UPDATE: appointmentId = $appointmentId');
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentUpdateRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['appointmentid'] = appointmentId;

    Logger.log('DEBUG UPDATE: Headers = $headers');
    Logger.log('DEBUG UPDATE: Body = ${jsonEncode(updatedFields)}');

    try {
      final res = await httpClient.put(url,
          headers: headers, body: jsonEncode(updatedFields));
      Logger.log('DEBUG UPDATE: Status code = ${res.statusCode}');
      Logger.log('DEBUG UPDATE: Response body = ${res.body}');

      if (res.statusCode != 200) {
        throw Exception(
          'Update failed [${res.statusCode}]: ${res.body}',
        );
      }
    } catch (e) {
      Logger.log('Error in updateAppointment: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  // CANCEL  /appointment/cancel
  // ------------------------------------------------------------------
  Future<void> cancelAppointment({
    required String token,
    required String appointmentId,
  }) async {
    Logger.log('DEBUG CANCEL: appointmentId = $appointmentId');
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentCancelRoute}');
    final headers = {
      'authentication': token,
      'appointment_id': appointmentId,
      'Content-Type': 'application/json',
    };

    Logger.log('DEBUG CANCEL: Headers = $headers');

    try {
      final res = await httpClient.post(url, headers: headers);
      Logger.log('DEBUG CANCEL: Status code = ${res.statusCode}');
      Logger.log('DEBUG CANCEL: Response body = ${res.body}');

      if (res.statusCode != 200) {
        throw Exception(
          'Cancel failed [${res.statusCode}]: ${res.body}',
        );
      }
    } catch (e) {
      Logger.log('Error in cancelAppointment: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  // DELETE  /appointment/delete
  // ------------------------------------------------------------------
  Future<void> deleteAppointment({
    required String token,
    required String appointmentId,
  }) async {
    Logger.log('DEBUG DELETE: appointmentId = $appointmentId');
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentDeleteRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['appointment_id'] = appointmentId;

    Logger.log('DEBUG DELETE: Headers = $headers');

    try {
      final res = await httpClient.delete(url, headers: headers);
      Logger.log('DEBUG DELETE: Status code = ${res.statusCode}');
      Logger.log('DEBUG DELETE: Response body = ${res.body}');

      if (res.statusCode != 200) {
        throw Exception(
          'Delete failed [${res.statusCode}]: ${res.body}',
        );
      }
    } catch (e) {
      Logger.log('Error in deleteAppointment: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  // UPCOMING (entity)  /appointment/upcoming
  // ------------------------------------------------------------------
  Future<List<AppointmentData>> getUpcoming({
    required String token,
    required String entityRole, // patient | doctor
    required String entityId,
    String suspendfilter = 'all',
  }) async {
    final url = Uri.parse(
        '${ClassUtil.baseUrl}${ClassUtil.appointmentUpcomingRoute}/specific');
    final headers = ClassUtil.baseHeaders(token: token);

    // IMPORTANT: The backend expects these exact lowercase header keys
    headers['entity_id'] = entityId;
    headers['entity_role'] = entityRole;
    headers['suspendfilter'] = suspendfilter;

    try {
      Logger.log('Fetching upcoming appointments: $url, headers: $headers');
      final res = await httpClient.get(url, headers: headers);
      // Only log a small part of the body to avoid huge logs
      if (res.body.isNotEmpty) {
        Logger.log(
            'Upcoming appointments response: ${res.statusCode} - ${res.body.substring(0, min(100, res.body.length))}...');
      } else {
        Logger.log(
            'Upcoming appointments response: ${res.statusCode} - Empty body');
      }

      if (res.statusCode != 200) {
        throw Exception(
          'Upcoming GET failed [${res.statusCode}]: ${res.body}',
        );
      }

      final bodyJson = json.decode(res.body);
      Logger.log(
          'Successfully decoded upcoming appointments JSON, found ${bodyJson is List ? bodyJson.length : 0} appointments');

      return (bodyJson as List)
          .map<AppointmentData>((e) => AppointmentData.fromJson(e))
          .toList();
    } catch (e) {
      Logger.log('Error in getUpcoming: $e');
      rethrow;
    }
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
    final headers = ClassUtil.baseHeaders(token: token)
      ..['suspendfilter'] = suspendfilter;

    try {
      Logger.log('Fetching all upcoming appointments: $url, headers: $headers');
      final res = await httpClient.get(url, headers: headers);
      Logger.log(
          'All upcoming appointments response: ${res.statusCode} - ${res.body.substring(0, min(100, res.body.length))}...');

      if (res.statusCode != 200) {
        throw Exception(
          'UpcomingAll GET failed [${res.statusCode}]: ${res.body}',
        );
      }
      return (json.decode(res.body) as List)
          .map<AppointmentData>((e) => AppointmentData.fromJson(e))
          .toList();
    } catch (e) {
      Logger.log('Error in getUpcomingAll: $e');
      rethrow;
    }
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
      ..['hospitalid'] = hospitalId
      ..['suspendfilter'] = suspendfilter;

    try {
      final res = await httpClient.get(url, headers: headers);
      if (res.statusCode != 200) {
        throw Exception(
          'Hospital upcoming failed [${res.statusCode}]: ${res.body}',
        );
      }
      return (json.decode(res.body) as List)
          .map<AppointmentData>((e) => AppointmentData.fromJson(e))
          .toList();
    } catch (e) {
      Logger.log('Error in getHospitalUpcoming: $e');
      rethrow;
    }
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
      ..['hospitalid'] = hospitalId
      ..['suspendfilter'] = suspendfilter;

    try {
      final res = await httpClient.get(url, headers: headers);
      if (res.statusCode != 200) {
        throw Exception(
          'Hospital history failed [${res.statusCode}]: ${res.body}',
        );
      }
      return (json.decode(res.body) as List)
          .map<AppointmentData>((e) => AppointmentData.fromJson(e))
          .toList();
    } catch (e) {
      Logger.log('Error in getHospitalHistory: $e');
      rethrow;
    }
  }

  // helper ------------------------------------------------------------
  bool _notEmpty(String? v) => v != null && v.trim().isNotEmpty;

  // Helper to get minimum of two integers (for substring operation)
  int min(int a, int b) => a < b ? a : b;
}
