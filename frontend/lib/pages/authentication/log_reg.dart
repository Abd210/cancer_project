// lib/pages/authentication/log_reg.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // <--- Make sure to import Provider
import 'package:frontend/providers/data_provider.dart'; // <--- So we can access hospitals

import 'package:frontend/pages/hospital/hospital_page.dart';
import 'package:frontend/pages/patients/patient_page.dart';
import 'package:frontend/pages/doctor/doctor_page.dart';
import 'package:frontend/pages/superadmin/superAdmin_page.dart';
import 'package:frontend/models/hospital.dart';
import 'package:frontend/models/doctor.dart';
import 'package:frontend/pages/doctor/doctor_page.dart'; // Ensure this import exists



class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  _LogInState createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
   void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // We'll need to read the DataProvider here to check for custom hospital names.
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/back.png'), // Background image
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and app name in a Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/acuranics.png', // Replace with your logo
                    height: 135,
                  ),
                  const Text(
                    'CURANICS',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 218, 73, 143),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Username TextField with adjusted width
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person,
                        color: Color.fromARGB(255, 218, 73, 143)),
                    hintText: 'USERNAME',
                    hintStyle:
                        TextStyle(color: Color.fromARGB(255, 218, 73, 143)),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 218, 73, 143)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 218, 73, 143), width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password TextField with adjusted width
              const SizedBox(
                width: 300,
                child: TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock,
                        color: Color.fromARGB(255, 218, 73, 143)),
                    hintText: 'PASSWORD',
                    hintStyle:
                        TextStyle(color: Color.fromARGB(255, 218, 73, 143)),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 218, 73, 143)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 218, 73, 143), width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Login Button
              ElevatedButton(
  onPressed: () {
    final username = _usernameController.text.trim().toLowerCase();

    if (username == 'patient') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PatientPage()),
      );
    } else if (username.startsWith('dr.') || username.startsWith('doctor')) {
  final matchedDoctor = dataProvider.doctors.firstWhere(
    (d) => d.name.toLowerCase() == username,
    orElse: () => Doctor(
      id: '',
      name: '',
      specialization: 'General',
      hospitalId: '',
    ),
  );

  if (matchedDoctor.id.isNotEmpty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorPage(doctorId: matchedDoctor.id),
      ),
    );
  } else {
    _showErrorDialog(context, 'Invalid doctor username. Please try again.');
  }
}

     else if (username == 'superadmin') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SuperAdminDashboard(),
        ),
      );
    } else {
      // Check if hospital exists
      final matchedHospital = dataProvider.hospitals.firstWhere(
        (h) => h.name.toLowerCase() == username,
        orElse: () => Hospital(id: '', name: '', address: ''),
      );

      if (matchedHospital.id.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HospitalPage(
              hospitalId: matchedHospital.id,
            ),
          ),
        );
      } else {
        // Show error for invalid input
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Invalid username. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color.fromARGB(255, 218, 73, 143),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 100,
      vertical: 15,
    ),
    elevation: 5,
  ),
  child: const Text(
    'LOGIN',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
),

              const SizedBox(height: 20),

              // Forgot password link
              TextButton(
                onPressed: () {
                  // Navigate to forgot password
                },
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: Color.fromARGB(255, 218, 73, 143),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
