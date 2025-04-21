//doctor_data.dart
class DoctorData {
  final String id; // corresponds to the DB id
  final String persId; // from "persId"
  final String name;
  final String email;
  final String password; // as returned by the API (if any)
  final String mobileNumber;
  final String birthDate; // e.g., "1981-02-12"
  final List<String> licenses;
  final String description;
  final String hospitalId; // from "hospital"
  final bool isSuspended; // from "suspended"

  DoctorData({
    required this.id,
    required this.persId,
    required this.name,
    required this.email,
    required this.password,
    required this.mobileNumber,
    required this.birthDate,
    required this.licenses,
    required this.description,
    required this.hospitalId,
    required this.isSuspended,
  });

  factory DoctorData.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to parse timestamp objects
      String parseTimestamp(dynamic timestamp) {
        if (timestamp is Map<String, dynamic>) {
          final seconds = timestamp['_seconds'] as int? ?? 0;
          final nanoseconds = timestamp['_nanoseconds'] as int? ?? 0;
          final dateTime = DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanoseconds ~/ 1000000),
          );
          return dateTime.toIso8601String().split('T')[0];
        } else if (timestamp is String) {
          return timestamp;
        }
        return DateTime.now().toIso8601String().split('T')[0];
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
        isSuspended: json['suspended'] ?? false,
      );
    } catch (e) {
      throw Exception('Error parsing doctor data: $e\nJSON: $json');
    }
  }
}
