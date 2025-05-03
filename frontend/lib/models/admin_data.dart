// lib/models/admin_data.dart
class AdminData {
  final String id;
  final String persId;
  final String password; // as returned by the API (if any)
  final String name;
  final String email;
  final String mobileNumber;
  final String hospitalId; // maps to 'hospital' in backend
  final String role; // should be "admin"
  final bool suspended;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminData({
    required this.id,
    required this.persId,
    this.password = '',
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.hospitalId,
    this.role = 'admin',
    required this.suspended,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminData.fromJson(Map<String,dynamic> json) {
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

    return AdminData(
      id          : json['id']     ?? json['_id'] ?? '',
      persId      : json['persId'] ?? '',
      password    : json['password'] ?? '',
      name        : json['name']   ?? '',
      email       : json['email']  ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      hospitalId  : json['hospital'] ?? '',
      role        : json['role'] ?? 'admin',
      suspended   : json['suspended'] ?? false,
      createdAt   : _ts(json['createdAt']),
      updatedAt   : _ts(json['updatedAt']),
    );
  }
}
