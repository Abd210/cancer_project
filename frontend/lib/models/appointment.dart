// lib/models/appointment.dart
class Appointment {
  final String id;
  String patientId;
  String doctorId;
  DateTime start;
  DateTime end;
  String status;
  String purpose;
  bool suspended;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.start,
    required this.end,
    required this.status,
    required this.purpose,
    this.suspended = false, required DateTime dateTime,
  });
}
