import 'package:flutter/material.dart';
import 'package:frontend/frontend/superadmin/screens/main_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Curanics',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const SuperAdminMainPage(), // Set your SuperAdminMainPage as the home
    );
  }
}
