import 'package:flutter/material.dart';
import 'package:frontend/pages/hospital/hospital_page.dart';
import 'package:frontend/pages/patients/patient_page.dart';
import 'package:frontend/pages/doctor/doctor_page.dart';
import 'package:frontend/pages/superadmin/superAdmin_page.dart';

class LogIn extends StatefulWidget {
  @override
  _LogInState createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    // Dispose the controller to avoid memory leaks
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                width: 300, // Adjust width here
                child: TextField(
                  controller: _usernameController, // Attach the controller
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person, color: Color.fromARGB(255, 218, 73, 143)),
                    hintText: 'USERNAME',
                    hintStyle: TextStyle(color: Color.fromARGB(255, 218, 73, 143)),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color.fromARGB(255, 218, 73, 143)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color.fromARGB(255, 218, 73, 143), width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Password TextField with adjusted width
              SizedBox(
                width: 300, // Adjust width here
                child: TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock, color: Color.fromARGB(255, 218, 73, 143)),
                    hintText: 'PASSWORD',
                    hintStyle: TextStyle(color: Color.fromARGB(255, 218, 73, 143)),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color.fromARGB(255, 218, 73, 143)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color.fromARGB(255, 218, 73, 143), width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Login Button
              ElevatedButton(
                onPressed: () {
                  final username = _usernameController.text.trim().toLowerCase();
                  if (username == 'hospital') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HospitalPage()),
                    );
                  } else if (username == 'patient') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PatientPage()),
                    );
                  } else if (username == 'doctor') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DoctorPage()),
                    );
                  } else if (username == 'superadmin') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SuperAdminDashboard()),
                    );
                  } else {
                    // Show an error if the input doesn't match any known role
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Error'),
                        content: Text('Invalid username. Please try again.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 218, 73, 143),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
