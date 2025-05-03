//doctor_data.dart
class DoctorData {
  final String id; // corresponds to the DB id (also "_id" in backend)
  final String persId;
  final String name;
  final String email;
  final String password; // as returned by the API (if any)
  final String mobileNumber;
  final DateTime birthDate;
  final List<String> licenses;
  final String description;
  final String hospitalId; // from "hospital"
  final List<String> patients; // list of patient IDs
  final List<Map<String, String>> schedule; // New field: [{day, start, end}]
  final String role; // should be "doctor"
  final bool suspended;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DoctorData({
    required this.id,
    required this.persId,
    required this.name,
    required this.email,
    this.password = '',
    required this.mobileNumber,
    required this.birthDate,
    required this.licenses,
    required this.description,
    required this.hospitalId,
    required this.patients,
    required this.schedule,
    this.role = 'doctor',
    required this.suspended,
    this.createdAt,
    this.updatedAt,
  });

  factory DoctorData.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to parse timestamp objects
      DateTime parseTimestamp(dynamic timestamp) {
        if (timestamp is Map<String, dynamic>) {
          final seconds = timestamp['_seconds'] as int? ?? 0;
          final nanoseconds = timestamp['_nanoseconds'] as int? ?? 0;
          final dateTime = DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanoseconds ~/ 1000000),
          );
          return dateTime;
        } else if (timestamp is String) {
          return DateTime.parse(timestamp);
        }
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

      // Parse schedule
      List<Map<String, String>> parseSchedule(dynamic scheduleData) {
        if (scheduleData is List) {
          return scheduleData
              .map((item) => {
                    'day': item['day'] as String? ?? '',
                    'start': item['start'] as String? ?? '',
                    'end': item['end'] as String? ?? '',
                  })
              .toList();
        }
        return [];
      }

      return DoctorData(
        id: json['id'] ?? json['_id'] ?? '',
        persId: json['persId'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        password: json['password'] ?? '',
        mobileNumber: json['mobileNumber'] ?? '',
        birthDate: parseTimestamp(json['birthDate']),
        licenses: json['licenses'] != null
            ? List<String>.from(json['licenses'])
            : <String>[],
        description: json['description'] ?? '',
        hospitalId: json['hospital'] ?? '',
        patients: json['patients'] != null
            ? List<String>.from(json['patients'])
            : <String>[],
        schedule: parseSchedule(json['schedule']),
        role: json['role'] ?? 'doctor',
        suspended: json['suspended'] ?? false,
        createdAt: _ts(json['createdAt']),
        updatedAt: _ts(json['updatedAt']),
      );
    } catch (e) {
      throw Exception('Error parsing doctor data: $e\nJSON: $json');
    }
  }
}
