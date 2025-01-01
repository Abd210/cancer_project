// models/doctor.dart
import 'package:json_annotation/json_annotation.dart';

part 'doctor.g.dart';

@JsonSerializable()
class Doctor {
  final String id;
  final String persId;
  final String role;
  final String name;
  final String email;
  final String mobileNumber;
  final DateTime birthDate;
  final List<String> licenses;
  final String description;
  final String hospital; // Reference to Hospital ID
  final DateTime createdAt;
  final DateTime updatedAt;

  Doctor({
    required this.id,
    required this.persId,
    this.role = 'doctor',
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.birthDate,
    required this.licenses,
    this.description = '',
    required this.hospital,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) =>
      _$DoctorFromJson(json);

  Map<String, dynamic> toJson() => _$DoctorToJson(this);
}
