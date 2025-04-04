// lib/pages/superadmin/view_doctors/view_doctors_page.dart

import 'package:flutter/material.dart';

import 'package:frontend/providers/doctor_provider.dart';
import 'package:frontend/models/doctor_data.dart';
import 'package:frontend/models/hospital_data.dart';

import '../../../shared/components/loading_indicator.dart';
import '../../../shared/components/components.dart';
import '../../../shared/components/responsive_data_table.dart'
    show BetterDataTable;

class DoctorsPage extends StatefulWidget {
  final String token;
  const DoctorsPage({super.key, required this.token});

  @override
  _DoctorsPageState createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  final DoctorProvider _doctorProvider = DoctorProvider();

  bool _isLoading = false;
  String _searchQuery = '';
  String _filter = 'unsuspended'; // "unsuspended", "suspended", "all"

  List<DoctorData> _doctorList = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() => _isLoading = true);
    try {
      final docs = await _doctorProvider.getDoctors(
        token: widget.token,
        doctorId: '',
        filter: _filter,
      );
      setState(() {
        _doctorList = docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load doctors: $e')),
        );
      }
    }
  }

  void _showAddDoctorDialog() {
    final formKey = GlobalKey<FormState>();

    String persId = '';
    String name = '';
    String password = '';
    String email = '';
    String mobileNumber = '';
    String birthDate = '';
    String licensesRaw = '';
    String description = '';
    bool isSuspended = false;
    String? selectedHospitalId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Doctor'),
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
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter email' : null,
                  onSaved: (val) => email = val!.trim(),
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
                  decoration: const InputDecoration(
                      labelText: 'Birth Date (YYYY-MM-DD)'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter birth date' : null,
                  onSaved: (val) => birthDate = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Licenses (comma-separated)'),
                  onSaved: (val) => licensesRaw = val ?? '',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  onSaved: (val) => description = val?.trim() ?? '',
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                final licensesList = licensesRaw
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                setState(() => _isLoading = true);
                try {
                  await _doctorProvider.createDoctor(
                    token: widget.token,
                    persId: persId,
                    name: name,
                    password: password,
                    email: email,
                    mobileNumber: mobileNumber,
                    birthDate: birthDate,
                    licenses: licensesList,
                    description: description,
                    hospitalId: selectedHospitalId ?? '',
                    suspended: isSuspended,
                  );

                  await _fetchDoctors();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Doctor added successfully.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add doctor: $e')),
                    );
                  }
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

  void _showEditDoctorDialog(DoctorData doc) {
    final formKey = GlobalKey<FormState>();

    String name = doc.name;
    String email = doc.email;
    String password = doc.password;
    String persId = doc.persId;
    String mobileNumber = doc.mobileNumber;
    String birthDate = doc.birthDate;
    List<String> licenses = doc.licenses;
    String description = doc.description;
    bool isSuspended = doc.isSuspended;
    String hospitalId = doc.hospitalId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Doctor'),
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
                  initialValue: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter email' : null,
                  onSaved: (val) => email = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: password,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter password' : null,
                  onSaved: (val) => password = val!.trim(),
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
                  initialValue: birthDate,
                  decoration: const InputDecoration(
                      labelText: 'Birth Date (YYYY-MM-DD)'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter birth date' : null,
                  onSaved: (val) => birthDate = val!.trim(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: licenses.join(', '),
                  decoration: const InputDecoration(
                      labelText: 'Licenses (comma-separated)'),
                  onSaved: (val) {
                    final raw = val ?? '';
                    licenses = raw
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  onSaved: (val) => description = val?.trim() ?? '',
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Suspended?'),
                    Checkbox(
                      value: isSuspended,
                      onChanged: (val) {
                        setState(() => isSuspended = val ?? false);
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
                    "email": email,
                    "mobileNumber": mobileNumber,
                    "birthDate": birthDate,
                    "licenses": licenses,
                    "description": description,
                    "hospital": hospitalId,
                    "suspended": isSuspended,
                  };

                  await _doctorProvider.updateDoctor(
                    token: widget.token,
                    doctorId: doc.id,
                    updatedFields: updatedFields,
                  );
                  await _fetchDoctors();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Doctor updated successfully.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update doctor: $e')),
                    );
                  }
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

  void _deleteDoctor(String doctorId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Doctor'),
        content: const Text('Are you sure you want to delete this doctor?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              try {
                await _doctorProvider.deleteDoctor(
                  token: widget.token,
                  doctorId: doctorId,
                );
                await _fetchDoctors();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Doctor deleted successfully.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete doctor: $e')),
                  );
                }
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
      return const Center(child: LoadingIndicator());
    }

    final filteredDoctors = _doctorList.where((doc) {
      final q = _searchQuery.toLowerCase();
      return doc.name.toLowerCase().contains(q) ||
          doc.persId.toLowerCase().contains(q) ||
          doc.email.toLowerCase().contains(q) ||
          doc.mobileNumber.toLowerCase().contains(q);
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
                        await _fetchDoctors();
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
                      labelText: 'Search Doctors',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _showAddDoctorDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Doctor'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _fetchDoctors,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _doctorList.isEmpty
                  ? const Center(child: Text('No doctors found.'))
                  : ListView.builder(
                      itemCount: filteredDoctors.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDoctors[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text(
                              doc.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'persId: ${doc.persId}\n'
                              'Email: ${doc.email}\n'
                              'Mobile: ${doc.mobileNumber}\n'
                              'Birth: ${doc.birthDate}\n'
                              'Suspended: ${doc.isSuspended}\n'
                              'Licenses: ${doc.licenses.join(", ")}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () => _showEditDoctorDialog(doc),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteDoctor(doc.id),
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
