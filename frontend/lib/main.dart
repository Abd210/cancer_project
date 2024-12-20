import 'package:flutter/material.dart';
import 'package:frontend/pages/authentication/log_reg.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove debug banner
      title: 'Hospital App',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: LogIn(), // Set LogIn as the initial screen
    );
  }
}