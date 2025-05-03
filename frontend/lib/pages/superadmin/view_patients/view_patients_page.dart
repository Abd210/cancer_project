// lib/pages/superadmin/view_patients/view_patients_page.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:frontend/models/patient_data.dart';
import 'package:frontend/providers/patient_provider.dart';
import 'package:frontend/models/hospital_data.dart';
import 'package:frontend/models/doctor_data.dart';

import '../../../shared/components/loading_indicator.dart';
import '../../../shared/components/responsive_data_table.dart'
    show BetterPaginatedDataTable;

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
  String _filter = 'unsuspended';

  List<PatientData> _patientList = [];

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      final patients = await _patientProvider.getPatients(
        token: widget.token,
        patientId: '',
        filter: _filter,
      );
      setState(() => _patientList = patients);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load patients: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddPatientDialog() {
    final formKey = GlobalKey<FormState>();

    // Fields as expected by your API
    String persId = '';
    String name = '';
    String password = '';
    String mobileNumber = '';
    String email = '';
    String status = 'recovering';
    String diagnosis = '';
    DateTime birthDate = DateTime.now();
    String medicalHistoryRaw = '';
    String hospitalId = '';
    bool suspended = false;

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
                  decoration: const InputDecoration(labelText: 'persId'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter persId' : null,
                  onSaved: (val) => persId = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter name' : null,
                  onSaved: (val) => name = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter password' : null,
                  onSaved: (val) => password = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Mobile Number'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter mobile number' : null,
                  onSaved: (val) => mobileNumber = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter email' : null,
                  onSaved: (val) => email = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Status (e.g. recovered)'),
                  onSaved: (val) => status = val?.trim() ?? '',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Diagnosis'),
                  onSaved: (val) => diagnosis = val?.trim() ?? '',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Birth Date (YYYY-MM-DD)'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter birth date' : null,
                  onSaved: (val) {
                    if (val != null && val.isNotEmpty) {
                      try {
                        birthDate = DateTime.parse(val);
                      } catch (e) {
                        birthDate = DateTime.now();
                      }
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Medical History (comma-separated)'),
                  onSaved: (val) => medicalHistoryRaw = val?.trim() ?? '',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Hospital ID'),
                  onSaved: (val) => hospitalId = val?.trim() ?? '',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Suspended?'),
                    Checkbox(
                      value: suspended,
                      onChanged: (val) {
                        setState(() {
                          suspended = val ?? false;
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

                final medicalHistory = medicalHistoryRaw
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
                    birthDate: birthDate.toIso8601String().split('T')[0],
                    medicalHistory: medicalHistory,
                    hospitalId: hospitalId,
                    suspended: suspended,
                  );
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

  void _showEditPatientDialog(PatientData patient) {
    final formKey = GlobalKey<FormState>();

    // Pre-populate from the PatientData model using camelCase keys
    String persId = patient.persId;
    String name = patient.name;
    String password = patient.password;
    String mobileNumber = patient.mobileNumber;
    String email = patient.email;
    String status = patient.status;
    String diagnosis = patient.diagnosis;
    DateTime birthDate = patient.birthDate;
    List<String> medHistory = patient.medicalHistory;
    String hospitalId = patient.hospitalId;
    bool suspended = patient.suspended;

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
                  decoration: const InputDecoration(labelText: 'persId'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter persId' : null,
                  onSaved: (val) => persId = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter name' : null,
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
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter mobile number' : null,
                  onSaved: (val) => mobileNumber = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter email' : null,
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
                  initialValue: birthDate.toIso8601String().split('T')[0],
                  decoration: const InputDecoration(
                      labelText: 'Birth Date (YYYY-MM-DD)'),
                  onSaved: (val) {
                    if (val != null && val.isNotEmpty) {
                      try {
                        birthDate = DateTime.parse(val);
                      } catch (e) {
                        birthDate = DateTime.now();
                      }
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: medHistory.join(', '),
                  decoration: const InputDecoration(
                      labelText: 'Medical History (comma-separated)'),
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
                      value: suspended,
                      onChanged: (val) {
                        setState(() {
                          suspended = val ?? false;
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
                    "persId": persId,
                    "name": name,
                    "password": password,
                    "mobileNumber": mobileNumber,
                    "email": email,
                    "status": status,
                    "diagnosis": diagnosis,
                    "birthDate": birthDate.toIso8601String().split('T')[0],
                    "medicalHistory": medHistory,
                    "hospital": hospitalId,
                    "suspended": suspended,
                  };

                  await _patientProvider.updatePatient(
                    token: widget.token,
                    patientId: patient.id,
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
                ElevatedButton.icon(
                  onPressed: _showAddPatientDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Patient'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _fetchPatients,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: filteredPatients.isEmpty
                  ? const Center(child: Text('No patients found.'))
                  : BetterPaginatedDataTable(
                      themeColor: const Color(0xFFEC407A), // Pinkish color
                      rowsPerPage: 10, // Show 10 rows per page
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Pers ID')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Diagnosis')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Suspended')),
                        DataColumn(label: Text('Hospital')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: filteredPatients.map((patient) {
                        return DataRow(
                          cells: [
                            DataCell(Text(patient.name)),
                            DataCell(Text(patient.persId)),
                            DataCell(Text(patient.email)),
                            DataCell(Text(patient.diagnosis)),
                            DataCell(Text(patient.status)),
                            DataCell(Text(patient.suspended.toString())),
                            DataCell(Text(patient.hospitalId)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditPatientDialog(patient),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deletePatient(patient.id),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
