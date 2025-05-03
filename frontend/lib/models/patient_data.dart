//patient_data.dart
import 'package:flutter/foundation.dart';

class PatientData {
  final String id; // maps to "id" (or "_id" if returned)
  final String persId;
  final String password; // as returned (if any)
  final String name;
  final String email;
  final String mobileNumber;
  final DateTime birthDate;
  final String hospitalId; // from "hospital"
  final String doctorId; // from "doctor"
  final String status; // "recovering", "recovered", "active", "inactive"
  final String diagnosis;
  final List<String> medicalHistory;
  final String role; // should be "patient"
  final bool suspended;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PatientData({
    required this.id,
    required this.persId,
    this.password = '',
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.birthDate,
    required this.hospitalId,
    required this.doctorId,
    required this.status,
    required this.diagnosis,
    required this.medicalHistory,
    this.role = 'patient',
    required this.suspended,
    this.createdAt,
    this.updatedAt,
  });

  factory PatientData.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to parse timestamp objects
      DateTime parseTimestamp(dynamic timestamp) {
        if (timestamp == null) return DateTime.now();
        
        if (timestamp is Map<String, dynamic>) {
          final seconds = timestamp['_seconds'] as int? ?? 0;
          final nanoseconds = timestamp['_nanoseconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanoseconds ~/ 1000000),
          );
        } else if (timestamp is String) {
          try {
            return DateTime.parse(timestamp);
          } catch (e) {
            return DateTime.now();
          }
        }
        return DateTime.now();
      }

      DateTime? _ts(dynamic v) {
        if (v is Map<String,dynamic>) {
          final s  = v['_seconds']     as int? ?? 0;
          final ns = v['_nanoseconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(
            s*1000 + (ns ~/ 1000000),
            isUtc: true).toLocal();
        }
        if (v is String) return DateTime.tryParse(v);
        return null;
      }

      return PatientData(
        id: json['id'] ?? json['_id'] ?? '',
        persId: json['persId'] ?? '',
        password: json['password'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        mobileNumber: json['mobileNumber'] ?? '',
        birthDate: parseTimestamp(json['birthDate']),
        hospitalId: json['hospital'] ?? '',
        doctorId: json['doctor'] ?? '',
        status: json['status'] ?? 'active',
        diagnosis: json['diagnosis'] ?? '',
        medicalHistory: json['medicalHistory'] != null
            ? List<String>.from(json['medicalHistory'])
            : <String>[],
        role: json['role'] ?? 'patient',
        suspended: json['suspended'] ?? false,
        createdAt: _ts(json['createdAt']),
        updatedAt: _ts(json['updatedAt']),
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
