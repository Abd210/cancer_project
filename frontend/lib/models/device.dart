// lib/models/device.dart
class Device {
  final String id;
  String type; // Only breast cancer devices
  String patientId; // Assigned to one patient

  Device({
    required this.id,
    required this.type,
    required this.patientId,
  });
}
