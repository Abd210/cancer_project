// lib/pages/superadmin/view_patients/view_patients_page.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Models & Providers
import 'package:frontend/models/patient_data.dart';
import 'package:frontend/providers/patient_provider.dart';
import 'package:frontend/models/hospital_data.dart';
import 'package:frontend/models/doctor_data.dart'; // If you need to link doctors

// Shared components
import '../../../shared/components/loading_indicator.dart';
import '../../../shared/components/responsive_data_table.dart'
    show BetterDataTable;

class PatientsPage extends StatefulWidget {
  final String token;
  const PatientsPage({Key? key, required this.token}) : super(key: key);

  @override
  _PatientsPageState createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final PatientProvider _patientProvider = PatientProvider();

  bool _isLoading = false;
  String _searchQuery = '';
  String _filter = 'unsuspended'; // "unsuspended", "suspended", "all"

  List<PatientData> _patientList = [];

  // If you want hospital data or doctor data:
  // List<HospitalData> _hospitalList = [];
  // List<DoctorData> _doctorList = [];

  @override
  void initState() {
    super.initState();
    _fetchPatients();
    // _fetchHospitals() or _fetchDoctors() if needed
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      // If you want all patients => patientId = ''
      final patients = await _patientProvider.getPatients(
        token: widget.token,
        patientId: '', // empty => get all
        filter: _filter, // if your backend supports it
      );
      setState(() => _patientList = patients);
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      Fluttertoast.showToast(msg: 'Failed to load patients: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Show “Add Patient” dialog => calls createPatient
  void _showAddPatientDialog() {
    final formKey = GlobalKey<FormState>();

    // All fields needed to match your POST body
    String persId = '';
    String name = '';
    String password = '';
    String mobileNumber = '';
    String email = '';
    String status = 'recovering'; // e.g. "recovering" / "recovered" / etc
    String diagnosis = '';
    String birthDate = '';
    String medicalHistoryRaw = ''; // parse as list
    String hospitalId = '';
    bool isSuspended = false;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Patient'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'pers_id'),
                  validator: (val) => val == null || val.isEmpty ? 'Enter pers_id' : null,
                  onSaved: (val) => persId = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (val) => val == null || val.isEmpty ? 'Enter name' : null,
                  onSaved: (val) => name = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (val) => val == null || val.isEmpty ? 'Enter password' : null,
                  onSaved: (val) => password = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Mobile Number'),
                  validator: (val) => val == null || val.isEmpty ? 'Enter mobile number' : null,
                  onSaved: (val) => mobileNumber = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (val) => val == null || val.isEmpty ? 'Enter email' : null,
                  onSaved: (val) => email = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Status (e.g. recovered)'),
                  onSaved: (val) => status = val?.trim() ?? '',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Diagnosis'),
                  onSaved: (val) => diagnosis = val?.trim() ?? '',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Birth Date (YYYY-MM-DD)'),
                  validator: (val) => val == null || val.isEmpty ? 'Enter birth date' : null,
                  onSaved: (val) => birthDate = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Medical History (comma-separated)'),
                  onSaved: (val) => medicalHistoryRaw = val?.trim() ?? '',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Hospital ID'),
                  // or a dropdown if you fetch real hospitals
                  onSaved: (val) => hospitalId = val?.trim() ?? '',
                ),
                const SizedBox(height: 10),

                // Suspended
                Row(
                  children: [
                    const Text('Suspended?'),
                    Checkbox(
                      value: isSuspended,
                      onChanged: (val) {
                        setState(() {
                          isSuspended = val ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(ctx);

                final medHistoryList = medicalHistoryRaw
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                setState(() => _isLoading = true);
                try {
                  await _patientProvider.createPatient(
                    token: widget.token,
                    persId: persId,
                    name: name,
                    password: password,
                    mobileNumber: mobileNumber,
                    email: email,
                    status: status,
                    diagnosis: diagnosis,
                    birthDate: birthDate,
                    medicalHistory: medHistoryList,
                    hospitalId: hospitalId,
                    suspended: isSuspended,
                  );
                  // If the backend only returns { "message": "Registration successful" },
                  // we won't parse a new object. We'll re-fetch:
                  await _fetchPatients();

                  Fluttertoast.showToast(msg: 'Patient added successfully.');
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Failed to add patient: $e');
                } finally {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// (Optional) Show “Edit Patient” => calls updatePatient
  void _showEditPatientDialog(PatientData patient) {
    final formKey = GlobalKey<FormState>();

    // Pre-populate
    String persId = patient.persId;
    String name = patient.name;
    String password = patient.password;
    String mobileNumber = patient.mobileNumber;
    String email = patient.email;
    String status = patient.status;
    String diagnosis = patient.diagnosis;
    String birthDate = patient.birthDate;
    List<String> medHistory = patient.medicalHistory;
    String hospitalId = patient.hospitalId;
    bool isSuspended = patient.suspended;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Patient'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  initialValue: persId,
                  decoration: const InputDecoration(labelText: 'pers_id'),
                  validator: (val) => val == null || val.isEmpty ? 'Enter pers_id' : null,
                  onSaved: (val) => persId = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (val) => val == null || val.isEmpty ? 'Enter name' : null,
                  onSaved: (val) => name = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: password,
                  decoration: const InputDecoration(labelText: 'Password'),
                  onSaved: (val) => password = val?.trim() ?? '',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: mobileNumber,
                  decoration: const InputDecoration(labelText: 'Mobile Number'),
                  validator: (val) => val == null || val.isEmpty ? 'Enter mobile number' : null,
                  onSaved: (val) => mobileNumber = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (val) => val == null || val.isEmpty ? 'Enter email' : null,
                  onSaved: (val) => email = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  onSaved: (val) => status = val?.trim() ?? '',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: diagnosis,
                  decoration: const InputDecoration(labelText: 'Diagnosis'),
                  onSaved: (val) => diagnosis = val?.trim() ?? '',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: birthDate,
                  decoration: const InputDecoration(labelText: 'Birth Date'),
                  onSaved: (val) => birthDate = val?.trim() ?? '',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: medHistory.join(', '),
                  decoration:
                      const InputDecoration(labelText: 'Medical History (comma-separated)'),
                  onSaved: (val) {
                    final raw = val ?? '';
                    medHistory = raw
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: hospitalId,
                  decoration: const InputDecoration(labelText: 'Hospital ID'),
                  onSaved: (val) => hospitalId = val?.trim() ?? '',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Suspended?'),
                    Checkbox(
                      value: isSuspended,
                      onChanged: (val) {
                        setState(() {
                          isSuspended = val ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(ctx);

                setState(() => _isLoading = true);
                try {
                  final updatedFields = {
                    "pers_id": persId,
                    "name": name,
                    "password": password,
                    "mobile_number": mobileNumber,
                    "email": email,
                    "status": status,
                    "diagnosis": diagnosis,
                    "birth_date": birthDate,
                    "medicalHistory": medHistory,
                    "hospital_id": hospitalId,
                    "suspended": isSuspended,
                  };

                  await _patientProvider.updatePatient(
                    token: widget.token,
                    patientId: patient.id, // your backend expects 'patientid' in headers
                    updatedFields: updatedFields,
                  );

                  await _fetchPatients();
                  Fluttertoast.showToast(msg: 'Patient updated successfully.');
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Failed to update patient: $e');
                } finally {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// DELETE
  void _deletePatient(String patientId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Patient'),
        content: const Text('Are you sure you want to delete this patient?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              try {
                await _patientProvider.deletePatient(
                  token: widget.token,
                  patientId: patientId,
                );
                await _fetchPatients();
                Fluttertoast.showToast(msg: 'Patient deleted successfully.');
              } catch (e) {
                Fluttertoast.showToast(msg: 'Failed to delete patient: $e');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator();
    }

    // Filter patients by _searchQuery
    final filteredPatients = _patientList.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.diagnosis.toLowerCase().contains(q) ||
          p.email.toLowerCase().contains(q) ||
          p.persId.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// 1) Row with filter (suspended/unsuspended), search, Add, Refresh
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: DropdownButton<String>(
                    value: _filter,
                    underline: const SizedBox(),
                    onChanged: (val) async {
                      if (val != null) {
                        setState(() => _filter = val);
                        await _fetchPatients();
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'unsuspended',
                        child: Text('Unsuspended'),
                      ),
                      DropdownMenuItem(
                        value: 'suspended',
                        child: Text('Suspended'),
                      ),
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All'),
                      ),
                    ],
                  ),
                ),
                // Search
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search Patients',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 10),

                // Add Patient
                ElevatedButton.icon(
                  onPressed: _showAddPatientDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Patient'),
                ),
                const SizedBox(width: 10),

                // Refresh
                ElevatedButton.icon(
                  onPressed: _fetchPatients,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// 2) Patient List
            Expanded(
              child: filteredPatients.isEmpty
                  ? const Center(child: Text('No patients found.'))
                  : ListView.builder(
                      itemCount: filteredPatients.length,
                      itemBuilder: (ctx, i) {
                        final patient = filteredPatients[i];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text(
                              patient.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'pers_id: ${patient.persId}\n'
                              'email: ${patient.email}\n'
                              'diagnosis: ${patient.diagnosis}\n'
                              'status: ${patient.status}\n'
                              'suspended: ${patient.suspended}\n'
                              'hospital: ${patient.hospitalId}',
                            ),
                            isThreeLine: false,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Edit
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditPatientDialog(patient),
                                ),
                                // Delete
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deletePatient(patient.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
