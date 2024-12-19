// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doctor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Doctor _$DoctorFromJson(Map<String, dynamic> json) => Doctor(
      id: json['id'] as String,
      persId: json['persId'] as String,
      role: json['role'] as String? ?? 'doctor',
      name: json['name'] as String,
      email: json['email'] as String,
      mobileNumber: json['mobileNumber'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      licenses:
          (json['licenses'] as List<dynamic>).map((e) => e as String).toList(),
      description: json['description'] as String? ?? '',
      hospital: json['hospital'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$DoctorToJson(Doctor instance) => <String, dynamic>{
      'id': instance.id,
      'persId': instance.persId,
      'role': instance.role,
      'name': instance.name,
      'email': instance.email,
      'mobileNumber': instance.mobileNumber,
      'birthDate': instance.birthDate.toIso8601String(),
      'licenses': instance.licenses,
      'description': instance.description,
      'hospital': instance.hospital,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
