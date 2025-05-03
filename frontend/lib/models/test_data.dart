// lib/models/test_data.dart
class TestData {
  final String id;

  // Patient
  final String patientId;
  final String patientName;

  // Doctor
  final String doctorId;
  final String doctorName;

  final String deviceId;      // may be null in API
  final DateTime resultDate;
  final String purpose;
  final String status;
  final String review;
  final bool   suspended;
  final DateTime createdAt;
  final DateTime updatedAt;

  TestData({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.deviceId,
    required this.resultDate,
    required this.purpose,
    required this.status,
    required this.review,
    required this.suspended,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TestData.fromJson(Map<String,dynamic> json) {
    DateTime _ts(dynamic v) {
      if (v is Map<String,dynamic>) {
        final s  = v['_seconds']     as int? ?? 0;
        final ns = v['_nanoseconds'] as int? ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          s*1000 + (ns ~/ 1000000),
          isUtc: true).toLocal();
      }
      if (v is String) return DateTime.parse(v);
      return DateTime.now();
    }

    final patient = json['patient'];
    final doctor  = json['doctor'];

    return TestData(
      id           : json['id'] ?? json['_id'] ?? '',
      patientId    : patient is Map ? (patient['id'] ?? '') : patient?.toString() ?? '',
      patientName  : patient is Map ? (patient['name'] ?? '') : '',
      doctorId     : doctor  is Map ? (doctor ['id'] ?? '') : doctor?.toString()  ?? '',
      doctorName   : doctor  is Map ? (doctor ['name'] ?? '') : '',
      deviceId     : json['device']?.toString() ?? '',
      resultDate   : _ts(json['resultDate']),
      purpose      : json['purpose'] ?? '',
      status       : json['status'] ?? '',
      review       : json['review'] ?? '',
      suspended    : json['suspended'] ?? false,
      createdAt    : _ts(json['createdAt']),
      updatedAt    : _ts(json['updatedAt']),
    );
  }
}
