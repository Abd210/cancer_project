// models/user.dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

enum UserRole { patient, doctor, admin, superadmin }

@JsonSerializable()
class User {
  final String id;
  final UserRole role;
  final String name;
  final String email;
  final String mobileNumber;

  User({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    required this.mobileNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
