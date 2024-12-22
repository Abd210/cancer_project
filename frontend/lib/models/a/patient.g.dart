// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Patient _$PatientFromJson(Map<String, dynamic> json) => Patient(
      id: json['id'] as String,
      persId: json['persId'] as String,
      role: json['role'] as String? ?? 'patient',
      name: json['name'] as String,
      mobileNumber: json['mobileNumber'] as String,
      email: json['email'] as String,
      status: json['status'] as String? ?? 'active',
      diagnosis: json['diagnosis'] as String? ?? 'Not Diagnosed',
      birthDate: DateTime.parse(json['birthDate'] as String),
      medicalHistory: (json['medicalHistory'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      hospital: json['hospital'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$PatientToJson(Patient instance) => <String, dynamic>{
      'id': instance.id,
      'persId': instance.persId,
      'role': instance.role,
      'name': instance.name,
      'mobileNumber': instance.mobileNumber,
      'email': instance.email,
      'status': instance.status,
      'diagnosis': instance.diagnosis,
      'birthDate': instance.birthDate.toIso8601String(),
      'medicalHistory': instance.medicalHistory,
      'hospital': instance.hospital,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
