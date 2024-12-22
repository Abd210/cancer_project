// models/notification.dart
import 'package:json_annotation/json_annotation.dart';

part 'notification.g.dart';

enum NotificationType { appointment, ticket, general }

@JsonSerializable()
class AppNotification {
  final String id;
  final String userId; // Reference to User ID
  final NotificationType type;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);
}
