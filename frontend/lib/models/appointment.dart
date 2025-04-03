class Appointment {
  final String id;
  String patientId;
  String doctorId;
  DateTime dateTime;
  String status;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.dateTime,
    required this.status,
  });
}
