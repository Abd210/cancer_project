// lib/models/ticket.dart
class Ticket {
  final String id;
  final String userId; // corresponds to 'user' in backend
  final String issue;
  final String status; // "open", "in_progress", "resolved", "closed"
  final String role; // "patient", "doctor", "admin", "superadmin"
  final DateTime? solvedAt;
  final String review;
  final List<String> visibleTo;
  final bool suspended;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Ticket({
    required this.id,
    required this.userId,
    required this.issue,
    required this.status,
    required this.role,
    this.solvedAt,
    this.review = '',
    this.visibleTo = const ["patient", "doctor", "admin", "superadmin"],
    this.suspended = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      
      if (value is Map<String, dynamic>) {
        final seconds = value['_seconds'] as int? ?? 0;
        final nanoseconds = value['_nanoseconds'] as int? ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds ~/ 1000000),
        );
      } else if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return Ticket(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['user'] ?? '',
      issue: json['issue'] ?? '',
      status: json['status'] ?? 'open',
      role: json['role'] ?? '',
      solvedAt: parseDateTime(json['solvedAt']),
      review: json['review'] ?? '',
      visibleTo: json['visibleTo'] != null
          ? List<String>.from(json['visibleTo'])
          : ["patient", "doctor", "admin", "superadmin"],
      suspended: json['suspended'] ?? false,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }
}
