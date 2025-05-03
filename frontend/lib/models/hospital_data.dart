//hospital_data.dart
class HospitalData {
  final String id;
  final String name;
  final String address;
  final List<String> mobileNumbers;
  final List<String> emails;
  final bool suspended; // changed from isSuspended to match backend
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HospitalData({
    required this.id,
    required this.name,
    required this.address,
    required this.mobileNumbers,
    required this.emails,
    required this.suspended,
    this.createdAt,
    this.updatedAt,
  });

  factory HospitalData.fromJson(Map<String, dynamic> json) {
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

    return HospitalData(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      suspended: json['suspended'] ?? false,
      mobileNumbers: json['mobileNumbers'] != null
          ? List<String>.from(json['mobileNumbers'])
          : <String>[],
      emails: json['emails'] != null
          ? List<String>.from(json['emails'])
          : <String>[],
      createdAt: _ts(json['createdAt']),
      updatedAt: _ts(json['updatedAt']),
    );
  }
}
