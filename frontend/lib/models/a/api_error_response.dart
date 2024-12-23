// // lib/models/api_error_response.dart
//
// import 'dart:convert';
// import 'package:isar/isar.dart';
//
// part 'api_error_response.g.dart';
//
// @Collection()
// class ApiErrorResponse {
//   @Id()
//   int? id; // Isar auto-increments this field
//
//   String? type;
//   String? title;
//   int? status;
//   Errors? errors;
//   String? traceId;
//
//   ApiErrorResponse({
//     this.id,
//     this.type,
//     this.title,
//     this.status,
//     this.errors,
//     // this.traceId,
//   });
//
//   // JSON Serialization
//   factory ApiErrorResponse.fromJson(Map<String, dynamic> json) =>
//       ApiErrorResponse(
//         type: json["type"],
//         title: json["title"],
//         status: json["status"],
//         errors:
//         json["errors"] == null ? null : Errors.fromJson(json["errors"]),
//         traceId: json["traceId"],
//       );
//
//   Map<String, dynamic> toJson() => {
//     "type": type,
//     "title": title,
//     "status": status,
//     "errors": errors?.toJson(),
//     "traceId": traceId,
//   };
// }
//
// @Collection()
// class Errors {
//   @Id()
//   int? id; // Isar auto-increments this field
//
//   List<String>? userName;
//
//   Errors({
//     this.id,
//     this.userName,
//   });
//
//   // JSON Serialization
//   factory Errors.fromJson(Map<String, dynamic> json) => Errors(
//     userName: json["UserName"] == null
//         ? []
//         : List<String>.from(json["UserName"].map((x) => x)),
//   );
//
//   Map<String, dynamic> toJson() => {
//     "UserName":
//     userName == null ? [] : List<dynamic>.from(userName!.map((x) => x)),
//   };
// }
