// lib/providers/appointment_provider.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/models/appointment_data.dart';
import 'package:frontend/utils/static.dart';

class AppointmentProvider {
  // Helper function to convert any ID to string
  String _toStringId(dynamic id) {
    if (id == null) return '';
    return id.toString();
  }

  Future<List<AppointmentData>> getAppointmentsHistory({
    required String token,
    required String suspendfilter,
    required String filterbyrole,
    required String filterbyid,
  }) async {
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentHistoryRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    headers["suspendfilter"] = suspendfilter;
    headers["filterbyrole"] = filterbyrole;
    headers["filterbyid"] = _toStringId(filterbyid);

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          final list = decoded.map((item) {
            // Convert numeric IDs to strings before creating AppointmentData
            if (item['id'] is int) {
              item['id'] = item['id'].toString();
            }
            if (item['patient'] is Map) {
              if (item['patient']['id'] is int) {
                item['patient']['id'] = item['patient']['id'].toString();
              }
            }
            if (item['doctor'] is Map) {
              if (item['doctor']['id'] is int) {
                item['doctor']['id'] = item['doctor']['id'].toString();
              }
            }
            return AppointmentData.fromJson(item);
          }).toList();
          return List<AppointmentData>.from(list);
        } else {
          throw Exception(
              'Unexpected format while fetching appointments history');
        }
      } else if (response.statusCode == 500) {
        // Handle Firestore index error specifically
        final error = json.decode(response.body);
        final errorMessage = error['error']?.toString() ?? '';
        if (errorMessage.contains('requires an index')) {
          throw Exception(
              'Database index needs to be created. Please contact the administrator.');
        }
        throw Exception('Server error: ${response.body}');
      } else {
        throw Exception(
          'Failed to get appointment history [${response.statusCode}]: ${response.body}',
        );
      }
    } catch (e) {
      if (e.toString().contains('requires an index')) {
        throw Exception(
            'Database index needs to be created. Please contact the administrator.');
      }
      rethrow;
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
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentNewRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    final body = {
      "patient": _toStringId(patientId),
      "doctor": _toStringId(doctorId),
      "appointmentDate": date.toIso8601String().split("T").first,
      "purpose": purpose,
      "status": status,
      "suspended": suspended,
    };

    final response =
        await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded["new_appointment"] != null) {
        // Convert numeric IDs to strings
        final appointment = decoded["new_appointment"];
        if (appointment['id'] is int) {
          appointment['id'] = appointment['id'].toString();
        }
        return AppointmentData.fromJson(appointment);
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
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentUpdateRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    // Convert IDs to strings
    updatedFields["appointmentid"] = _toStringId(appointmentId);
    if (updatedFields["patient"] != null) {
      updatedFields["patient"] = _toStringId(updatedFields["patient"]);
    }
    if (updatedFields["doctor"] != null) {
      updatedFields["doctor"] = _toStringId(updatedFields["doctor"]);
    }

    final response =
        await http.put(url, headers: headers, body: jsonEncode(updatedFields));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      // Convert numeric IDs to strings
      if (decoded['id'] is int) {
        decoded['id'] = decoded['id'].toString();
      }
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
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.appointmentDeleteRoute}');
    final headers = ClassUtil.baseHeaders(token: token);

    headers["appointmentid"] = _toStringId(appointmentId);

    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete appointment [${response.statusCode}]: ${response.body}',
      );
    }
  }
}
