// models/ticket_result.dart
import 'package:json_annotation/json_annotation.dart';

part 'ticket_result.g.dart';

@JsonSerializable()
class TicketResult {
  final String id;
  final String ticketId; // Reference to Ticket ID
  final String resolvedBy; // Reference to User ID (Doctor/Admin)
  final String resolution;
  final DateTime resolvedAt;

  TicketResult({
    required this.id,
    required this.ticketId,
    required this.resolvedBy,
    required this.resolution,
    required this.resolvedAt,
  });

  factory TicketResult.fromJson(Map<String, dynamic> json) =>
      _$TicketResultFromJson(json);

  Map<String, dynamic> toJson() => _$TicketResultToJson(this);
}
