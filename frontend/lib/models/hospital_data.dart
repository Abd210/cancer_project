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
      id: json['_id'] ?? '',
      name: json['hospital_name'] ?? '',
      address: json['hospital_address'] ?? '',
      isSuspended: json['suspended'] ?? false,
      mobileNumbers: (json['mobile_numbers'] != null)
          ? List<String>.from(json['mobile_numbers'])
          : <String>[],
      emails: (json['emails'] != null)
          ? List<String>.from(json['emails'])
          : <String>[],
    );
  }
}
