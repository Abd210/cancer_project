// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TicketResult _$TicketResultFromJson(Map<String, dynamic> json) => TicketResult(
      id: json['id'] as String,
      ticketId: json['ticketId'] as String,
      resolvedBy: json['resolvedBy'] as String,
      resolution: json['resolution'] as String,
      resolvedAt: DateTime.parse(json['resolvedAt'] as String),
    );

Map<String, dynamic> _$TicketResultToJson(TicketResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticketId': instance.ticketId,
      'resolvedBy': instance.resolvedBy,
      'resolution': instance.resolution,
      'resolvedAt': instance.resolvedAt.toIso8601String(),
    };
