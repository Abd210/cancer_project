import 'package:frontend/utils/helpers.dart';

class DeviceData {
  final String id;
  final String hospitalId; // maps to 'hospital' in backend
  final String? patientId; // Can be null or empty if unassigned
  final String deviceCode; // from deviceCode in backend
  final String purpose;
  final String status; // "operational", "malfunctioned", "standby"
  final bool suspended;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DeviceData({
    required this.id,
    required this.hospitalId,
    this.patientId,
    required this.deviceCode,
    required this.purpose,
    required this.status,
    required this.suspended,
    this.createdAt,
    this.updatedAt,
  });

  factory DeviceData.fromJson(Map<String, dynamic> json) {
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

    return DeviceData(
      id: json["_id"] ?? json["id"] ?? 'Unknown ID', // Handle both _id and id
      hospitalId: json["hospital"] ?? '',
      patientId: json["patient"] as String?, // Backend might send null or empty string
      deviceCode: json["deviceCode"] ?? '',
      purpose: json["purpose"] ?? '',
      status: json["status"] ?? 'operational',
      suspended: json["suspended"] ?? false,
      createdAt: _ts(json["createdAt"]),
      updatedAt: _ts(json["updatedAt"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "hospital": hospitalId,
        "patient": patientId,
        "deviceCode": deviceCode,
        "purpose": purpose,
        "status": status,
        "suspended": suspended,
        // Timestamps are usually handled by the backend on creation/update
      };
}

