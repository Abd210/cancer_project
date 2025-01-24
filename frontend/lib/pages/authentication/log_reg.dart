// lib/pages/authentication/log_reg.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/providers/auth_provider.dart'; // <-- Use your AuthProvider
import 'package:frontend/pages/superadmin/superAdmin_page.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  _LogInState createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final TextEditingController _emailController =
      TextEditingController(text: 'Azzam@example.com'); // example default
  final TextEditingController _passwordController =
      TextEditingController(text: '123'); // example default

  bool _isLoading = false;

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

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog(context, 'Please enter email and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = AuthProvider();
      // Attempt login against your Express backend
      final response = await authProvider.login(
        email: email,
        password: password,
        role: 'superadmin', // or adjust if needed
      );

      // If a token is returned, navigate to the SuperAdminDashboard
      if (response.token != null && response.token!.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SuperAdminDashboard(token: response.token!),
          ),
        );
        Fluttertoast.showToast(msg: 'Login successful.');
      } else {
        _showErrorDialog(context, 'No token received.');
      }
    } catch (e) {
      _showErrorDialog(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background image
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/back.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo + Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/acuranics.png',
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

                // Email TextField
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.person,
                        color: Color.fromARGB(255, 218, 73, 143),
                      ),
                      hintText: 'EMAIL',
                      hintStyle: TextStyle(
                        color: Color.fromARGB(255, 218, 73, 143),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 218, 73, 143),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 218, 73, 143),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password TextField
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.lock,
                        color: Color.fromARGB(255, 218, 73, 143),
                      ),
                      hintText: 'PASSWORD',
                      hintStyle: TextStyle(
                        color: Color.fromARGB(255, 218, 73, 143),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 218, 73, 143),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 218, 73, 143),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Login button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
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
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'LOGIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                // Forgot password (optional)
                TextButton(
                  onPressed: () {
                    // add your forgot password logic
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
      ),
    );
  }
}
