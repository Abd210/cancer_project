// lib/models/test_data.dart
class TestData {
  final String id;

  // Patient info
  final String patientId; // from 'patient'
  final String patientName;

  // Doctor info
  final String doctorId; // from 'doctor'
  final String doctorName;

  // Device info
  final String? deviceId; // from 'device', may be null in API
  
  final DateTime? resultDate;
  final String status; // "reviewed", "in_progress", "pending"
  final String purpose;
  final String review;
  final List<String> results;
  final bool suspended;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TestData({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    this.deviceId,
    this.resultDate,
    required this.status,
    required this.purpose,
    required this.review,
    required this.results,
    required this.suspended,
    this.createdAt,
    this.updatedAt,
  });

  factory TestData.fromJson(Map<String,dynamic> json) {
    DateTime? _ts(dynamic v) {
      if (v == null) return null;
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

    final patient = json['patient'];
    final doctor  = json['doctor'];

    return TestData(
      id           : json['id'] ?? json['_id'] ?? '',
      patientId    : patient is Map ? (patient['id'] ?? patient['_id'] ?? '') : patient?.toString() ?? '',
      patientName  : patient is Map ? (patient['name'] ?? '') : '',
      doctorId     : doctor  is Map ? (doctor ['id'] ?? doctor['_id'] ?? '') : doctor?.toString()  ?? '',
      doctorName   : doctor  is Map ? (doctor ['name'] ?? '') : '',
      deviceId     : json['device']?.toString(),
      resultDate   : _ts(json['resultDate']),
      purpose      : json['purpose'] ?? '',
      status       : json['status'] ?? 'pending',
      review       : json['review'] ?? '',
      results      : json['results'] != null ? List<String>.from(json['results']) : <String>[],
      suspended    : json['suspended'] ?? false,
      createdAt    : _ts(json['createdAt']),
      updatedAt    : _ts(json['updatedAt']),
    );
  }
}
