// lib/models/doctor_data.dart

/// Represents a Doctor object in your app.
class DoctorData {
  final String id;              // _id from DB
  final String persId;          // personal ID: "pers_id"
  final String name;
  final String email;
  final String password;        // Usually not stored in plain text, but included to match your POST data
  final String mobileNumber;
  final String birthDate;       // e.g. "1981-02-12"
  final List<String> licenses;
  final String description;
  final String hospitalId;      // "hospital" field in your JSON
  final bool isSuspended;

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

  /// Factory to build DoctorData from JSON returned by the backend.
  factory DoctorData.fromJson(Map<String, dynamic> json) {
    return DoctorData(
      id: json['_id'] ?? '',
      persId: json['pers_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',  // or omit if the backend does not return it
      mobileNumber: json['mobile_number'] ?? '',
      birthDate: json['birth_date'] ?? '',
      licenses: (json['licenses'] != null)
          ? List<String>.from(json['licenses'])
          : <String>[],
      description: json['description'] ?? '',
      hospitalId: json['hospital'] ?? '',
      isSuspended: json['suspended'] ?? false,
    );
  }
}
