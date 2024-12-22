// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Ticket _$TicketFromJson(Map<String, dynamic> json) => Ticket(
      id: json['id'] as String,
      role: json['role'] as String,
      issue: json['issue'] as String,
      status: json['status'] as String? ?? 'open',
      createdAt: DateTime.parse(json['createdAt'] as String),
      solvedAt: json['solvedAt'] == null
          ? null
          : DateTime.parse(json['solvedAt'] as String),
      review: json['review'] as String?,
      user: json['user'] as String,
      visibleTo: (json['visibleTo'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['patient', 'doctor', 'admin', 'superadmin'],
    );

Map<String, dynamic> _$TicketToJson(Ticket instance) => <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'issue': instance.issue,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'solvedAt': instance.solvedAt?.toIso8601String(),
      'review': instance.review,
      'user': instance.user,
      'visibleTo': instance.visibleTo,
    };
