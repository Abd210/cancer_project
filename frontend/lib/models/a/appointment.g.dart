// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Appointment _$AppointmentFromJson(Map<String, dynamic> json) => Appointment(
      id: json['id'] as String,
      patient: json['patient'] as String,
      doctor: json['doctor'] as String,
      appointmentDate: DateTime.parse(json['appointmentDate'] as String),
      purpose: json['purpose'] as String,
      status: json['status'] as String? ?? 'scheduled',
    );

Map<String, dynamic> _$AppointmentToJson(Appointment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patient': instance.patient,
      'doctor': instance.doctor,
      'appointmentDate': instance.appointmentDate.toIso8601String(),
      'purpose': instance.purpose,
      'status': instance.status,
    };
