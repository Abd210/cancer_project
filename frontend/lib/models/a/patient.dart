// models/patient.dart
import 'package:json_annotation/json_annotation.dart';

part 'patient.g.dart';

@JsonSerializable()
class Patient {
  final String id;
  final String persId;
  final String role;
  final String name;
  final String mobileNumber;
  final String email;
  final String status;
  final String diagnosis;
  final DateTime birthDate;
  final List<String> medicalHistory;
  final String hospital; // Reference to Hospital ID
  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    required this.id,
    required this.persId,
    this.role = 'patient',
    required this.name,
    required this.mobileNumber,
    required this.email,
    this.status = 'active',
    this.diagnosis = 'Not Diagnosed',
    required this.birthDate,
    required this.medicalHistory,
    required this.hospital,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) =>
      _$PatientFromJson(json);

  Map<String, dynamic> toJson() => _$PatientToJson(this);
}
