class AppointmentData {
  final String id;               // maps from "id" (or "_id" if provided)
  final String patientId;        // from patient.id
  final String patientName;      // from patient.name
  final String patientEmail;     // from patient.email
  final String doctorId;         // from doctor.id
  final String doctorName;       // from doctor.name
  final String doctorEmail;      // from doctor.email
  final DateTime date;           // parse from "appointmentDate"
  final String purpose;          // "purpose"
  final String status;           // "status"
  final bool suspended;          // "suspended"

  AppointmentData({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientEmail,
    required this.doctorId,
    required this.doctorName,
    required this.doctorEmail,
    required this.date,
    required this.purpose,
    required this.status,
    required this.suspended,
  });

  factory AppointmentData.fromJson(Map<String, dynamic> json) {
    final patientObj = json["patient"] ?? {};
    final doctorObj = json["doctor"] ?? {};

    // Parse using the camelCase key "appointmentDate"
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json["appointmentDate"]);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return AppointmentData(
      id: json["id"] ?? '',
      patientId: patientObj["id"] ?? '',
      patientName: patientObj["name"] ?? '',
      patientEmail: patientObj["email"] ?? '',
      doctorId: doctorObj["id"] ?? '',
      doctorName: doctorObj["name"] ?? '',
      doctorEmail: doctorObj["email"] ?? '',
      date: parsedDate,
      purpose: json["purpose"] ?? '',
      status: json["status"] ?? '',
      suspended: json["suspended"] ?? false,
    );
  }
}
