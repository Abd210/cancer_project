// lib/models/appointment_data.dart
class AppointmentData {
  //--------------------------------------------------------------------
  // RAW FIELDS IN API
  // id              String
  // patient         String  OR  nested Map
  // doctor          String  OR  nested Map
  // start, end      ISO‑8601 String OR Firestore timestamp object
  // purpose         String
  // status          String "scheduled", "cancelled", "completed"
  // suspended       bool
  //--------------------------------------------------------------------
  final String id;

  // Patient info
  final String patientId;
  final String patientName;
  final String patientEmail;

  // Doctor info
  final String doctorId;
  final String doctorName;
  final String doctorEmail;

  // Time range
  final DateTime start;
  final DateTime end;

  final String purpose;
  final String status; // "scheduled", "cancelled", "completed"
  final bool suspended;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppointmentData({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientEmail,
    required this.doctorId,
    required this.doctorName,
    required this.doctorEmail,
    required this.start,
    required this.end,
    required this.purpose,
    required this.status,
    required this.suspended,
    this.createdAt,
    this.updatedAt,
  });

  //--------------------------------------------------------------------
  // JSON ↦ MODEL
  //--------------------------------------------------------------------
  factory AppointmentData.fromJson(Map<String,dynamic> json) {
    // ---------------- helpers ----------------
    String str(dynamic v) => v == null ? '' : v.toString();

    DateTime parseTimestamp(dynamic ts) {
      if (ts is Map<String,dynamic>) {
        final s  = ts['_seconds']     as int? ?? 0;
        final ns = ts['_nanoseconds'] as int? ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          s*1000 + (ns ~/ 1000000),
          isUtc: true,
        ).toLocal();
      }
      if (ts is String)   return DateTime.parse(ts);
      return DateTime.now();
    }

    DateTime? _ts(dynamic v) {
      if (v is Map<String,dynamic>) {
        final s  = v['_seconds']     as int? ?? 0;
        final ns = v['_nanoseconds'] as int? ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          s*1000 + (ns ~/ 1000000),
          isUtc: true).toLocal();
      }
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    // ------------- patient / doctor ----------
    final patientObj = json['patient'];
    final doctorObj  = json['doctor'];

    final String patientId = patientObj is Map
        ? str(patientObj['id'] ?? patientObj['_id'])
        : str(patientObj);

    final String doctorId = doctorObj is Map
        ? str(doctorObj['id'] ?? doctorObj['_id'])
        : str(doctorObj);

    return AppointmentData(
      id            : str(json['id'] ?? json['_id']),
      patientId     : patientId,
      patientName   : patientObj is Map ? str(patientObj['name'])  : '',
      patientEmail  : patientObj is Map ? str(patientObj['email']) : '',
      doctorId      : doctorId,
      doctorName    : doctorObj  is Map ? str(doctorObj['name'])   : '',
      doctorEmail   : doctorObj  is Map ? str(doctorObj['email'])  : '',
      start         : parseTimestamp(json['start']),
      end           : parseTimestamp(json['end']),
      purpose       : str(json['purpose']),
      status        : str(json['status']),
      suspended     : json['suspended'] ?? false,
      createdAt     : _ts(json['createdAt']),
      updatedAt     : _ts(json['updatedAt']),
    );
  }

  @override
  String toString() =>
      'Appointment($id → $patientName vs $doctorName @ $start)';
}
