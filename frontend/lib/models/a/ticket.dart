// models/ticket.dart
import 'package:json_annotation/json_annotation.dart';

part 'ticket.g.dart';

@JsonSerializable()
class Ticket {
  final String id;
  final String role;
  final String issue;
  final String status;
  final DateTime createdAt;
  final DateTime? solvedAt;
  final String? review;
  final String user; // Reference to User ID (Patient, Doctor, etc.)
  final List<String> visibleTo;

  Ticket({
    required this.id,
    required this.role,
    required this.issue,
    this.status = 'open',
    required this.createdAt,
    this.solvedAt,
    this.review,
    required this.user,
    this.visibleTo = const ['patient', 'doctor', 'admin', 'superadmin'],
  });

  factory Ticket.fromJson(Map<String, dynamic> json) =>
      _$TicketFromJson(json);

  Map<String, dynamic> toJson() => _$TicketToJson(this);
}
