// lib/pages/authentication/log_reg.dart
import 'package:flutter/material.dart';
import 'package:frontend/pages/patients/patient_page.dart';

import 'package:frontend/providers/auth_provider.dart';
import '../superadmin/superAdmin_page.dart';
import '../doctor/doctor_page.dart';
import '../hospital/hospital_page.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final _emailCtrl    = TextEditingController(text: 'mario@gmail.com');
  final _passwordCtrl = TextEditingController(text: '123');
  bool  _isLoading = false;

  //---------------------------------------------------------------------------
  // HELPERS
  //---------------------------------------------------------------------------
  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'), content: Text(msg),
        actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passwordCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showError('Please enter email and password.');
      return;
    }

    setState(()=>_isLoading = true);
    try {
      final auth = AuthProvider();
      final resp = await auth.login(email: email, password: pass);

      if (resp.token.isEmpty) {
        _showError('Backend did not return a token.');
        return;
      }

      // ------------------------- role‑based routing -------------------------
      Widget destination;
      switch (resp.role.toLowerCase()) {
        case 'superadmin':
          destination = SuperAdminDashboard(token: resp.token);
          break;
        case 'admin':
          destination = SuperAdminDashboard(token: resp.token);
          //HospitalPage(hospitalId: resp.hospitalId ?? '');
          break;
        case 'doctor':
          destination = SuperAdminDashboard(token: resp.token);
          //DoctorPage(doctorId: resp.userId);
          break;
        case 'patient':
          destination = SuperAdminDashboard(token: resp.token);
           //PatientPage();   // patientId not used in UI yet
          break;
        default:
          _showError('Unknown role "${resp.role}".');
          return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp.message ?? 'Login successful')),
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(()=>_isLoading = false);
    }
  }

  //---------------------------------------------------------------------------
  // UI
  //---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/back.png'), fit: BoxFit.cover),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ------------ Logo ------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/acuranics.png', height: 135),
                    const Text('CURANICS',
                      style: TextStyle(
                        fontSize: 40, fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 218, 73, 143),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ------------ Email ------------
                _styledField(
                  controller: _emailCtrl,
                  hint: 'EMAIL',
                  icon: Icons.person,
                  obscure: false,
                ),
                const SizedBox(height: 20),

                // ---------- Password ----------
                _styledField(
                  controller: _passwordCtrl,
                  hint: 'PASSWORD',
                  icon: Icons.lock,
                  obscure: true,
                ),
                const SizedBox(height: 30),

                // ------------ Button ----------
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 218, 73, 143),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('LOGIN',
                          style: TextStyle(fontSize: 16,
                                           fontWeight: FontWeight.bold,
                                           color: Colors.white)),
                ),
                const SizedBox(height: 20),

                // -------- forgot pw ----------
                TextButton(
                  onPressed: () {},  // TODO
                  child: const Text('Forgot password?',
                      style: TextStyle(
                        color: Color.fromARGB(255, 218, 73, 143), fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // helper to build styled text fields
  Widget _styledField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
  }) {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color.fromARGB(255, 218, 73, 143)),
          hintText: hint,
          hintStyle: const TextStyle(color: Color.fromARGB(255, 218, 73, 143)),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color.fromARGB(255, 218, 73, 143)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Color.fromARGB(255, 218, 73, 143), width: 2),
          ),
        ),
      ),
    );
  }
}
