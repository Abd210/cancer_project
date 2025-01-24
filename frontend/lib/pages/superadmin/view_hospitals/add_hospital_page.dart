// lib/pages/superadmin/view_hospitals/add_hospital_page.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/providers/hospital_provider.dart';
import 'package:frontend/models/hospital_data.dart';

class AddHospitalPage extends StatefulWidget {
  final String token;
  const AddHospitalPage({super.key, required this.token});

  @override
  State<AddHospitalPage> createState() => _AddHospitalPageState();
}

class _AddHospitalPageState extends State<AddHospitalPage> {
  final _formKey = GlobalKey<FormState>();
  final _hospitalProvider = HospitalProvider();

  bool _isLoading = false;

  String _name = '';
  String _address = '';
  String _mobileNumbers = '';
  String _emails = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Hospital'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // FORM
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Hospital Name
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Hospital Name'),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Enter hospital name' : null,
                    onSaved: (value) => _name = value!.trim(),
                  ),
                  const SizedBox(height: 10),

                  // Address
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Enter address' : null,
                    onSaved: (value) => _address = value!.trim(),
                  ),
                  const SizedBox(height: 10),

                  // Mobile Numbers
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Mobile Numbers (comma-separated)',
                    ),
                    onSaved: (value) => _mobileNumbers = value ?? '',
                  ),
                  const SizedBox(height: 10),

                  // Emails
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Emails (comma-separated)',
                    ),
                    onSaved: (value) => _emails = value ?? '',
                  ),
                  const SizedBox(height: 20),

                  // SUBMIT BUTTON
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Add Hospital'),
                  ),
                ],
              ),
            ),
          ),

          // LOADING INDICATOR
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    final mobileList = _mobileNumbers
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final emailList = _emails
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    try {
      final newHospital = await _hospitalProvider.createHospital(
        token: widget.token,
        hospitalName: _name,
        hospitalAddress: _address,
        mobileNumbers: mobileList,
        emails: emailList,
      );

      Fluttertoast.showToast(msg: 'Hospital added successfully.');

      // IMPORTANT: Pop back and return the newly-created HospitalData object
      Navigator.pop(context, newHospital);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to add hospital: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
