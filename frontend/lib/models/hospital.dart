// models/hospital.dart
import 'package:json_annotation/json_annotation.dart';

part 'hospital.g.dart';

@JsonSerializable()
class Hospital {
  final String id;
  final String hospitalName;
  final String hospitalAddress;
  final List<String> mobileNumbers;
  final List<String> emails;

  Hospital({
    required this.id,
    required this.hospitalName,
    required this.hospitalAddress,
    required this.mobileNumbers,
    required this.emails,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) =>
      _$HospitalFromJson(json);

  Map<String, dynamic> toJson() => _$HospitalToJson(this);
}
