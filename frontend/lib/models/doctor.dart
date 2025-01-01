// lib/models/doctor.dart
class Doctor {
  final String id;
  String name;
  String specialization;
  String hospitalId;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.hospitalId,
  });
}
