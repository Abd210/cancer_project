// lib/pages/superadmin/view_hospitals/tabs/patients_tab.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/models/patient_data.dart';
import 'package:frontend/providers/patient_provider.dart';
import '../../../../shared/components/responsive_data_table.dart'
    show BetterPaginatedDataTable;
import 'package:frontend/providers/doctor_provider.dart';

class HospitalPatientsTab extends StatefulWidget {
  final String token;
  final String hospitalId;
  const HospitalPatientsTab({
    super.key,
    required this.token,
    required this.hospitalId,
  });

  @override
  State<HospitalPatientsTab> createState() => _HospitalPatientsTabState();
}

class _HospitalPatientsTabState extends State<HospitalPatientsTab> {
  final _provider = PatientProvider();
  final _doctorProvider = DoctorProvider();
  bool _loading = false;
  List<PatientData> _patients = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      _patients = await _provider.getPatients(
        token: widget.token,
        filter: 'all',
        hospitalId: widget.hospitalId,
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Load patients failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showUpsert([PatientData? existing]) {
    final formKey = GlobalKey<FormState>();
    String persId = existing?.persId ?? '';
    String name = existing?.name ?? '';
    String email = existing?.email ?? '';
    String mobile = existing?.mobileNumber ?? '';
    String password = '';
    String status = existing?.status ?? '';
    String diagnosis = existing?.diagnosis ?? '';
    bool suspended = existing?.suspended ?? false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(existing == null ? Icons.person_add : Icons.edit, color: const Color(0xFFEC407A)),
              const SizedBox(width: 10),
              Text(existing == null ? 'Add Patient' : 'Edit Patient', 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                    initialValue: persId,
                    decoration: const InputDecoration(
                      labelText: 'Personal ID',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Personal ID' : null,
                    onSaved: (v) => persId = v!.trim(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Name' : null,
                    onSaved: (v) => name = v!.trim(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Email' : null,
                    onSaved: (v) => email = v!.trim(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: mobile,
                    decoration: const InputDecoration(
                      labelText: 'Mobile',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Mobile' : null,
                    onSaved: (v) => mobile = v!.trim(),
                  ),
                  const SizedBox(height: 16),
                  if (existing == null)
                    Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Password' : null,
                          onSaved: (v) => password = v!.trim(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  TextFormField(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.info),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Status' : null,
                    onSaved: (v) => status = v!.trim(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: diagnosis,
                    decoration: const InputDecoration(
                      labelText: 'Diagnosis',
                      prefixIcon: Icon(Icons.medical_services),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Diagnosis' : null,
                    onSaved: (v) => diagnosis = v!.trim(),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Text('Suspended?'),
                    const SizedBox(width: 10),
                    Checkbox(
                      value: suspended,
                      onChanged: (v) => setDialogState(() => suspended = v ?? false),
                      activeColor: const Color(0xFFEC407A),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(existing == null ? 'Add Patient' : 'Save Patient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC407A),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                formKey.currentState!.save();
                Navigator.pop(context);

                setState(() => _loading = true);
                try {
                  if (existing == null) {
                    await _provider.createPatient(
                      token: widget.token,
                      persId: persId,
                      name: name,
                      password: password.isEmpty ? '123' : password,
                      mobileNumber: mobile,
                      email: email,
                      status: status,
                      diagnosis: diagnosis,
                      birthDate: DateTime.now().toIso8601String(),
                      medicalHistory: [],
                      hospitalId: widget.hospitalId,
                      doctorIds: [_fetchDefaultDoctor(widget.hospitalId)],
                      suspended: suspended,
                    );
                    Fluttertoast.showToast(msg: 'Patient added.');
                  } else {
                    await _provider.updatePatient(
                      token: widget.token,
                      patientId: existing.id,
                      updatedFields: {
                        'name': name,
                        'mobileNumber': mobile,
                        'email': email,
                        'status': status,
                        'diagnosis': diagnosis,
                        'suspended': suspended,
                      },
                    );
                    Fluttertoast.showToast(msg: 'Patient updated.');
                  }
                  await _fetch();
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Save failed: $e');
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this patient?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      await _provider.deletePatient(token: widget.token, patientId: id);
      Fluttertoast.showToast(msg: 'Patient deleted.');
      await _fetch();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Delete failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final list = _patients.where((p) {
      final q = _query.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.email.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search patients',
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showUpsert(),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC407A),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC407A),
                foregroundColor: Colors.white,
              ),
            ),
          ]),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('No patients found.'))
              : BetterPaginatedDataTable(
                  themeColor: const Color(0xFFEC407A),
                  rowsPerPage: 10,
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Diagnosis')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: list
                      .map((p) => DataRow(cells: [
                            DataCell(Text(p.name)),
                            DataCell(Text(p.email)),
                            DataCell(Text(p.status)),
                            DataCell(Text(p.diagnosis)),
                            DataCell(Row(children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue),
                                onPressed: () => _showUpsert(p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => _delete(p.id),
                              ),
                            ])),
                          ]))
                      .toList(),
                ),
        ),
      ],
    );
  }



  String _fetchDefaultDoctor(String hospitalId) {
    // This is a synchronous method that returns a hardcoded ID
    // In a real app, you would want to fetch this properly
    // For now, we'll return a placeholder to make the code compile
    return 'defaultDoctorId';
  }
}