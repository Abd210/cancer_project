// // lib/models/user_fields.dart
//
// import 'package:flutter/material.dart';
//
// mixin UserFields {
//   String? serverId; // Corresponds to MongoDB ObjectId
//   String? email;
//   String? firstName;
//   String? lastName;
//   String? phoneNumber;
//   String? themeMode = ThemeMode.system.toString();
//
//   void setTheme(ThemeMode theme) => themeMode = theme.toString();
//   String getFullName() => '$firstName $lastName';
//   String getInitials() => '${firstName![0]}${lastName![0]}';
//   ThemeMode getTheme() =>
//       ThemeMode.values.firstWhere((e) => e.toString() == themeMode);
// }
