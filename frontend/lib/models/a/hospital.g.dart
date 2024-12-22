// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hospital.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Hospital _$HospitalFromJson(Map<String, dynamic> json) => Hospital(
      id: json['id'] as String,
      hospitalName: json['hospitalName'] as String,
      hospitalAddress: json['hospitalAddress'] as String,
      mobileNumbers: (json['mobileNumbers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      emails:
          (json['emails'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$HospitalToJson(Hospital instance) => <String, dynamic>{
      'id': instance.id,
      'hospitalName': instance.hospitalName,
      'hospitalAddress': instance.hospitalAddress,
      'mobileNumbers': instance.mobileNumbers,
      'emails': instance.emails,
    };
