//patient.dart
class Patient {
  final String id;
  String name;
  int age;
  String diagnosis;
  String doctorId;
  String deviceId; // Each device is assigned to one patient

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.diagnosis,
    required this.doctorId,
    required this.deviceId,
  });
}
//useless