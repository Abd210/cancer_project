// lib/models/hospital_data.dart

class HospitalData {
  final String id;
  final String name;         // maps to hospital_name
  final String address;      // maps to hospital_address
  final bool isSuspended;    // maps to suspended
  final List<String> mobileNumbers;
  final List<String> emails;

  HospitalData({
    required this.id,
    required this.name,
    required this.address,
    required this.isSuspended,
    required this.mobileNumbers,
    required this.emails,
  });

  factory HospitalData.fromJson(Map<String, dynamic> json) {
    return HospitalData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      isSuspended: json['suspended'] ?? false,
      mobileNumbers: (json['mobileNumbers'] != null)
          ? List<String>.from(json['mobileNumbers'])
          : <String>[],
      emails: (json['emails'] != null)
          ? List<String>.from(json['emails'])
          : <String>[],
    );
  }
}
