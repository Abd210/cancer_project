import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color.fromARGB(255, 218, 73, 143);
  static const accentColor = Color.fromARGB(255, 255, 192, 203);
  static const backgroundImage = 'assets/images/back.png';
  static const logoImage = 'assets/images/acuranics.png';

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      hintColor: accentColor,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 5,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor, textStyle: const TextStyle(fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        prefixIconColor: primaryColor,
        hintStyle: TextStyle(color: primaryColor.withOpacity(0.6)),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateColor.resolveWith((states) => primaryColor.withOpacity(0.1)),
        headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
        dataRowColor: MaterialStateColor.resolveWith((states) => Colors.white),
      ),
    );
  }
}
