class AppointmentData {
  final String id; // maps from "id" (or "_id" if provided)
  final String patientId; // from patient.id
  final String patientName; // from patient.name
  final String patientEmail; // from patient.email
  final String doctorId; // from doctor.id
  final String doctorName; // from doctor.name
  final String doctorEmail; // from doctor.email
  final DateTime date; // parse from "appointmentDate"
  final String purpose; // "purpose"
  final String status; // "status"
  final bool suspended; // "suspended"

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

    // Helper function to convert id to string
    String toStringId(dynamic id) {
      if (id == null) return '';
      return id.toString();
    }

    // Parse using the camelCase key "appointmentDate"
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json["appointmentDate"]);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return AppointmentData(
      id: toStringId(json["id"] ?? json["_id"]),
      patientId: toStringId(patientObj["id"] ?? patientObj["_id"]),
      patientName: patientObj["name"]?.toString() ?? '',
      patientEmail: patientObj["email"]?.toString() ?? '',
      doctorId: toStringId(doctorObj["id"] ?? doctorObj["_id"]),
      doctorName: doctorObj["name"]?.toString() ?? '',
      doctorEmail: doctorObj["email"]?.toString() ?? '',
      date: parsedDate,
      purpose: json["purpose"]?.toString() ?? '',
      status: json["status"]?.toString() ?? '',
      suspended: json["suspended"] ?? false,
    );
  }

  String toDebugString() {
    return 'AppointmentData(id: $id, patient: $patientName, doctor: $doctorName, date: $date, status: $status)';
  }
}
