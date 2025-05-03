//patient_data.dart
import 'package:flutter/foundation.dart';

class PatientData {
  final String id; // maps to "id" (or "_id" if returned)
  final String persId; // from "persId"
  final String name;
  final String password; // as returned (if any)
  final String role; // should be "patient"
  final String mobileNumber;
  final String email;
  final String status;
  final String diagnosis;
  final DateTime birthDate; // Parse from nested object
  final List<String> medicalHistory;
  final String hospitalId; // from "hospital"
  final bool suspended;
  final DateTime createdAt; // Parse from nested object
  final DateTime updatedAt; // Parse from nested object

  PatientData({
    required this.id,
    required this.persId,
    required this.name,
    required this.password,
    required this.role,
    required this.mobileNumber,
    required this.email,
    required this.status,
    required this.diagnosis,
    required this.birthDate,
    required this.medicalHistory,
    required this.hospitalId,
    required this.suspended,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientData.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to parse timestamp objects
      DateTime parseTimestamp(Map<String, dynamic>? timestamp) {
        if (timestamp == null) return DateTime.now();
        final seconds = timestamp['_seconds'] as int? ?? 0;
        final nanoseconds = timestamp['_nanoseconds'] as int? ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds ~/ 1000000),
        );
      }

      // Parse birthDate from nested object
      DateTime parseBirthDate(dynamic birthDate) {
        if (birthDate is Map<String, dynamic>) {
          return parseTimestamp(birthDate);
        } else if (birthDate is String) {
          try {
            return DateTime.parse(birthDate);
          } catch (e) {
            return DateTime.now();
          }
        }
        return DateTime.now();
      }

      return PatientData(
        id: json['id'] ?? json['_id'] ?? '',
        persId: json['persId'] ?? '',
        name: json['name'] ?? '',
        password: json['password'] ?? '',
        role: json['role'] ?? 'patient',
        mobileNumber: json['mobileNumber'] ?? '',
        email: json['email'] ?? '',
        status: json['status'] ?? '',
        diagnosis: json['diagnosis'] ?? '',
        birthDate: parseBirthDate(json['birthDate']),
        medicalHistory: json['medicalHistory'] != null
            ? List<String>.from(json['medicalHistory'])
            : <String>[],
        hospitalId: json['hospital'] ?? json['hospitalId'] ?? '',
        suspended: json['suspended'] ?? false,
        createdAt: parseTimestamp(json['createdAt']),
        updatedAt: parseTimestamp(json['updatedAt']),
      );
    } catch (e) {
      debugPrint('Error creating PatientData from JSON: $e\nJSON: $json');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'PatientData(id: $id, name: $name, email: $email, status: $status, diagnosis: $diagnosis)';
  }
}
