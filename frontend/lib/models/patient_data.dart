// lib/models/patient_data.dart

class PatientData {
  final String id;            // Maps to "_id" from the DB if returned
  final String persId;        // "pers_id"
  final String name;
  final String password;      // Might not be returned from the backend, but included to match POST/PUT
  final String role;          // Should be "patient"
  final String mobileNumber;
  final String email;
  final String status;
  final String diagnosis;
  final String birthDate;     // e.g. "1991-10-11"
  final List<String> medicalHistory;
  final String hospitalId;    // "hospital_id"
  final bool suspended;

  PatientData({
    required this.id,
    required this.persId,
    required this.name,
    required this.password,
    required this.role,
    required this.mobileNumber,
    required this.email,
    required this.status,
    required this.diagnosis,
    required this.birthDate,
    required this.medicalHistory,
    required this.hospitalId,
    required this.suspended,
  });

  factory PatientData.fromJson(Map<String, dynamic> json) {
    return PatientData(
      id: json['_id'] ?? '',
      persId: json['pers_id'] ?? '',
      name: json['name'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? 'patient', // or default to "patient"
      mobileNumber: json['mobile_number'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      birthDate: json['birth_date'] ?? '',
      medicalHistory: (json['medicalHistory'] != null)
          ? List<String>.from(json['medicalHistory'])
          : <String>[],
      hospitalId: json['hospital_id'] ?? '',
      suspended: json['suspended'] ?? false,
    );
  }
}
