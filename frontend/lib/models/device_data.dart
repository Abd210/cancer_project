import 'package:frontend/utils/helpers.dart';

class DeviceData {
  final String id;
  String type;
  String? patientId; // Can be null or empty if unassigned
  String? patientName; // Optional: Include if backend provides it
  bool suspended;
  DateTime? createdAt;
  DateTime? updatedAt;

  DeviceData({
    required this.id,
    required this.type,
    this.patientId,
    this.patientName,
    required this.suspended,
    this.createdAt,
    this.updatedAt,
  });

  factory DeviceData.fromJson(Map<String, dynamic> json) {
    return DeviceData(
      id: json["_id"] ?? json["id"] ?? 'Unknown ID', // Handle both _id and id
      type: json["type"] ?? 'Unknown Type',
      patientId: json["patient"] as String?, // Backend might send null or empty string
      patientName: json["patientName"] as String?, // Assuming backend might populate this
      suspended: json["suspended"] ?? false,
      createdAt: parseFirestoreTimestamp(json["createdAt"]),
      updatedAt: parseFirestoreTimestamp(json["updatedAt"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
        "patient": patientId,
        "suspended": suspended,
        // Timestamps are usually handled by the backend on creation/update
      };
}

