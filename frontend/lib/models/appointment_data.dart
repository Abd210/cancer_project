// lib/models/appointment_data.dart

/// Because your API returns something like:
/// {
///   "_id": "...",
///   "patient": { "_id": "...", "name": "...", "email": "..." },
///   "doctor": { "_id": "...", "name": "...", "email": "..." },
///   "appointment_date": "2025-04-10T00:00:00.000Z",
///   "purpose": "Example",
///   "status": "scheduled",
///   "suspended": false,
///   ...
/// }
/// we parse those nested objects.

class AppointmentData {
  final String id;               // maps from "_id"
  final String patientId;        // from "patient._id"
  final String patientName;      // from "patient.name"
  final String patientEmail;     // from "patient.email"
  final String doctorId;         // from "doctor._id"
  final String doctorName;       // from "doctor.name"
  final String doctorEmail;      // from "doctor.email"
  final DateTime date;           // parse from "appointment_date"
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
    // The server returns "patient" as an object. We safely parse subfields.
    final patientObj = json["patient"] ?? {};
    final doctorObj = json["doctor"] ?? {};

    // parse date from "appointment_date"
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json["appointment_date"]);
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
