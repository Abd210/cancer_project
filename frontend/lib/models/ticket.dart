// lib/models/ticket.dart
class Ticket {
  final String id;
  String requester;
  String requestType;
  String description;
  DateTime date;
  bool isApproved;

  Ticket({
    required this.id,
    required this.requester,
    required this.requestType,
    required this.description,
    required this.date,
    this.isApproved = false,
  });
}
