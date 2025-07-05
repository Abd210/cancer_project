import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/utils/static.dart';
import 'package:frontend/models/hospital_data.dart';
import 'package:frontend/main.dart' show httpClient;

class HospitalProvider {
  Future<List<HospitalData>> getHospitals({
    required String token,
    String? hospitalId,
    String? filter,
  }) async {
    try {
      // Use the direct hospital route for all cases
      final url =
          Uri.parse('${ClassUtil.baseUrl}${ClassUtil.hospitalDataRoute}');
      final headers = ClassUtil.baseHeaders(token: token);

      // Ensure correct header name as required by backend (lowercase 'hospitalid')
      if (hospitalId != null && hospitalId.isNotEmpty) {
        headers['hospitalid'] = hospitalId;
      }

      if (filter != null && filter.isNotEmpty) {
        headers['filter'] = filter;
      }

      print('HOSPITAL PROVIDER: Request headers: $headers');
      final response = await httpClient.get(url, headers: headers);
      print('HOSPITAL PROVIDER: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('HOSPITAL PROVIDER: Decoded response: $decoded');

        if (decoded is List) {
          return decoded.map((e) => HospitalData.fromJson(e)).toList();
        } else if (decoded is Map<String, dynamic>) {
          return [HospitalData.fromJson(decoded)];
        }
      } else {
        throw Exception(
            'Failed to fetch hospital: HTTP ${response.statusCode} - ${response.body}');
      }

      // Fallback - If we couldn't get the hospital data, create a dummy entry with the ID
      if (hospitalId != null && hospitalId.isNotEmpty) {
        return [
          HospitalData(
            id: hospitalId,
            name: 'Hospital #$hospitalId',
            address: 'Unknown Location',
            mobileNumbers: [],
            emails: [],
            adminId: '',
            suspended: false,
          )
        ];
      }

      throw Exception('Failed to fetch hospitals: ${response.statusCode}');
    } catch (e) {
      print('HOSPITAL PROVIDER: Error: $e');

      // Add fallback for error case too
      if (hospitalId != null && hospitalId.isNotEmpty) {
        return [
          HospitalData(
            id: hospitalId,
            name: 'Hospital #$hospitalId',
            address: 'Unknown Location',
            mobileNumbers: [],
            emails: [],
            adminId: '',
            suspended: false,
          )
        ];
      }
      rethrow;
    }
  }

  Future<HospitalData> createHospital({
    required String token,
    required String hospitalName,
    required String hospitalAddress,
    required List<String> mobileNumbers,
    required List<String> emails,
    bool suspended = false,
    String? admin,
  }) async {
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.hospitalRegisterRoute}');
    final headers = ClassUtil.baseHeaders(token: token);
    final body = {
      'name': hospitalName,
      'address': hospitalAddress,
      'mobileNumbers': mobileNumbers,
      'emails': emails,
      'suspended': suspended,
    };
    
    // Only include admin field if provided
    if (admin != null && admin.isNotEmpty) {
      body['admin'] = admin;
    }

    final resp = await http.post(url, headers: headers, body: jsonEncode(body));
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
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.hospitalUpdateRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['hospitalid'] = hospitalId;
    final resp =
        await http.put(url, headers: headers, body: jsonEncode(updatedFields));
    if (resp.statusCode != 200) {
      throw Exception('Failed to update hospital: ${resp.statusCode}');
    }
  }

  Future<void> deleteHospital({
    required String token,
    required String hospitalId,
  }) async {
    final url =
        Uri.parse('${ClassUtil.baseUrl}${ClassUtil.hospitalDeleteRoute}');
    final headers = ClassUtil.baseHeaders(token: token)
      ..['hospitalid'] = hospitalId;
    final resp = await http.delete(url, headers: headers);
    // Accept 200 OK OR 204 No Content
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Failed to delete hospital: ${resp.statusCode}');
    }
  }

  // Add a new method that's safe for doctor use
  Future<HospitalData> getHospitalSafe({
    required String token,
    required String hospitalId,
  }) async {
    try {
      // First try to get hospital data the normal way
      final hospitals = await getHospitals(
        token: token,
        hospitalId: hospitalId,
      );

      if (hospitals.isNotEmpty) {
        return hospitals.first;
      }

      throw Exception('No hospital data found');
    } catch (e) {
      print(
          'HOSPITAL PROVIDER: Falling back to basic hospital data due to: $e');

      // If that fails (likely due to permissions), create a basic hospital data object
      return HospitalData(
        id: hospitalId,
        name: 'Hospital #$hospitalId',
        address: 'Contact an administrator for details',
        mobileNumbers: [],
        emails: [],
        adminId: '',
        suspended: false,
      );
    }
  }
}
