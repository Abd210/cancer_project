// lib/pages/superadmin/view_hospitals/tabs/doctors_tab.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/models/doctor_data.dart';
import 'package:frontend/providers/doctor_provider.dart';

class HospitalDoctorsTab extends StatefulWidget {
  final String token;
  final String hospitalId;
  const HospitalDoctorsTab({
    super.key,
    required this.token,
    required this.hospitalId,
  });

  @override
  State<HospitalDoctorsTab> createState() => _HospitalDoctorsTabState();
}

class _HospitalDoctorsTabState extends State<HospitalDoctorsTab> {
  final _provider = DoctorProvider();
  bool _loading = false;
  List<DoctorData> _doctors = [];
  String _q = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      _doctors = await _provider.getDoctors(
        token: widget.token,
        filter: 'all',
        hospitalId: widget.hospitalId,
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Load doctors failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showUpsert([DoctorData? existing]) {
    final formKey = GlobalKey<FormState>();
    String persId   = existing?.persId ?? '';
    String name     = existing?.name   ?? '';
    String email    = existing?.email  ?? '';
    String mobile   = existing?.mobileNumber ?? '';
    String password = '';
    String desc     = existing?.description  ?? '';
    bool suspended  = existing?.isSuspended  ?? false;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Doctor' : 'Edit Doctor'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _txt('Personal ID', initial: persId, save: (v) => persId = v),
              _txt('Name',        initial: name,   save: (v) => name   = v),
              _txt('Email',       initial: email,  save: (v) => email  = v),
              _txt('Mobile',      initial: mobile, save: (v) => mobile = v),
              if (existing == null)
                _txt('Password', obscure: true, save: (v) => password = v),
              _txt('Description', initial: desc,   save: (v) => desc   = v),
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
                  await _provider.createDoctor(
                    token: widget.token,
                    persId: persId,
                    name: name,
                    password: password.isEmpty ? '123' : password,
                    email: email,
                    mobileNumber: mobile,
                    birthDate: DateTime.now().toIso8601String(),
                    licenses: [],
                    description: desc,
                    hospitalId: widget.hospitalId,
                    suspended: suspended,
                  );
                  Fluttertoast.showToast(msg: 'Doctor created.');
                } else {
                  await _provider.updateDoctor(
                    token: widget.token,
                    doctorId: existing.id,
                    updatedFields: {
                      'name': name,
                      'email': email,
                      'mobileNumber': mobile,
                      'description': desc,
                      'suspended': suspended,
                    },
                  );
                  Fluttertoast.showToast(msg: 'Doctor updated.');
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
        title: const Text('Delete doctor?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Yes')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      await _provider.deleteDoctor(token: widget.token, doctorId: id);
      Fluttertoast.showToast(msg: 'Doctor deleted.');
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
    final list = _doctors.where((d) {
      final q = _q.toLowerCase();
      return d.name.toLowerCase().contains(q) || d.email.toLowerCase().contains(q);
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
                  hintText: 'Search doctors',
                ),
                onChanged: (v) => setState(() => _q = v),
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
              ? const Center(child: Text('No doctors found.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: list.map((d) => DataRow(cells: [
                      DataCell(Text(d.name)),
                      DataCell(Text(d.email)),
                      DataCell(Text(d.description)),
                      DataCell(Row(children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showUpsert(d),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _delete(d.id),
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
