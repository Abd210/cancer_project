// lib/pages/superadmin/view_hospitals/tabs/patients_tab.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/models/patient_data.dart';
import 'package:frontend/providers/patient_provider.dart';

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
    String persId     = existing?.persId ?? '';
    String name       = existing?.name   ?? '';
    String email      = existing?.email  ?? '';
    String mobile     = existing?.mobileNumber ?? '';
    String password   = '';
    String status     = existing?.status    ?? '';
    String diagnosis  = existing?.diagnosis ?? '';
    bool suspended    = existing?.suspended ?? false;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Patient' : 'Edit Patient'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _txt('Personal ID', initial: persId, save: (v) => persId    = v),
              _txt('Name',        initial: name,   save: (v) => name      = v),
              _txt('Email',       initial: email,  save: (v) => email     = v),
              _txt('Mobile',      initial: mobile, save: (v) => mobile    = v),
              if (existing == null)
                _txt('Password', obscure: true, save: (v) => password = v),
              _txt('Status',     initial: status, save: (v) => status    = v),
              _txt('Diagnosis',  initial: diagnosis, save: (v) => diagnosis = v),
              Row(children: [
                const Text('Suspended?'),
                Checkbox(
                  value: suspended,
                  onChanged: (v) => setState(() => suspended = v ?? false),
                ),
              ]),
            ]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              formKey.currentState!.save();
              Navigator.pop(context);

              setState(() => _loading = true);
              try {
                if (existing == null) {
                  await _provider.createPatient(
                    token          : widget.token,
                    persId         : persId,
                    name           : name,
                    password       : password.isEmpty ? '123' : password,
                    mobileNumber   : mobile,
                    email          : email,
                    status         : status,
                    diagnosis      : diagnosis,
                    birthDate      : DateTime.now().toIso8601String(),
                    medicalHistory : [],
                    hospitalId     : widget.hospitalId,
                    suspended      : suspended,
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this patient?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Yes')),
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
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ]),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('No patients found.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Diagnosis')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: list.map((p) => DataRow(cells: [
                      DataCell(Text(p.name)),
                      DataCell(Text(p.email)),
                      DataCell(Text(p.status)),
                      DataCell(Text(p.diagnosis)),
                      DataCell(Row(children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showUpsert(p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _delete(p.id),
                        ),
                      ])),
                    ])).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _txt(String label,
      {String initial = '',
      bool obscure = false,
      required void Function(String) save}) {
    return TextFormField(
      initialValue: initial,
      obscureText: obscure,
      decoration: InputDecoration(labelText: label),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter $label' : null,
      onSaved: (v) => save(v!.trim()),
    );
  }
}
