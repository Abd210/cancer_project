// models/appointment.dart
import 'package:json_annotation/json_annotation.dart';

part 'appointment.g.dart';

@JsonSerializable()
class Appointment {
  final String id;
  final String patient; // Reference to Patient ID
  final String doctor; // Reference to Doctor ID
  final DateTime appointmentDate;
  final String purpose;
  final String status;

  Appointment({
    required this.id,
    required this.patient,
    required this.doctor,
    required this.appointmentDate,
    required this.purpose,
    this.status = 'scheduled',
  });

  factory Appointment.fromJson(Map<String, dynamic> json) =>
      _$AppointmentFromJson(json);

  Map<String, dynamic> toJson() => _$AppointmentToJson(this);
}
