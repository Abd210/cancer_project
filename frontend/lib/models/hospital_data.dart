//hospital_data.dart
class HospitalData {
  final String id;
  final String name;         // from "name"
  final String address;      // from "address"
  final bool isSuspended;    // from "suspended"
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
      mobileNumbers: json['mobileNumbers'] != null
          ? List<String>.from(json['mobileNumbers'])
          : <String>[],
      emails: json['emails'] != null
          ? List<String>.from(json['emails'])
          : <String>[],
    );
  }
}
