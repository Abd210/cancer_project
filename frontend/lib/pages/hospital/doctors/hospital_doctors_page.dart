import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/data_provider.dart';
import '../../../models/doctor.dart';
import '../../../models/hospital.dart';
import '../../../shared/components/loading_indicator.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HospitalDoctorsPage extends StatefulWidget {
  final String hospitalId;

  const HospitalDoctorsPage({super.key, required this.hospitalId});

  @override
  _HospitalDoctorsPageState createState() => _HospitalDoctorsPageState();
}

class _HospitalDoctorsPageState extends State<HospitalDoctorsPage> {
  String _searchQuery = '';
  final bool _isLoading = false;

  void _showAddDoctorDialog(BuildContext context, Hospital hospital) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String specialization = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Doctor'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Doctor Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                  onSaved: (value) => name = value!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Specialization'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter specialization' : null,
                  onSaved: (value) => specialization = value!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final newDoctor = Doctor(
                  id: 'd${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  specialization: specialization,
                  hospitalId: hospital.id,
                );
                Provider.of<DataProvider>(context, listen: false).addDoctor(newDoctor);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Doctor added successfully.');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDoctorDialog(BuildContext context, Doctor doctor) {
    final formKey = GlobalKey<FormState>();
    String name = doctor.name;
    String specialization = doctor.specialization;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Doctor'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  initialValue: doctor.name,
                  decoration: const InputDecoration(labelText: 'Doctor Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                  onSaved: (value) => name = value!,
                ),
                TextFormField(
                  initialValue: doctor.specialization,
                  decoration: const InputDecoration(labelText: 'Specialization'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter specialization' : null,
                  onSaved: (value) => specialization = value!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final updatedDoctor = Doctor(
                  id: doctor.id,
                  name: name,
                  specialization: specialization,
                  hospitalId: doctor.hospitalId,
                );
                Provider.of<DataProvider>(context, listen: false).updateDoctor(updatedDoctor);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Doctor updated successfully.');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteDoctor(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Doctor'),
        content: const Text('Are you sure you want to delete this doctor?'),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<DataProvider>(context, listen: false).deleteDoctor(id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Doctor deleted successfully.');
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        if (_isLoading) {
          return const LoadingIndicator();
        }

        // Retrieve the hospital object from the DataProvider
        final hospital = dataProvider.hospitals.firstWhere(
          (h) => h.id == widget.hospitalId,
          orElse: () => Hospital(id: '', name: 'Unknown', address: ''),
        );

        // Filter doctors by this hospital
        List<Doctor> doctors = dataProvider.doctors
            .where((d) => d.hospitalId == widget.hospitalId)
            .where((d) =>
                d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                d.specialization.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Title + Search + Add button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Search Doctors',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDoctorDialog(context, hospital),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Doctor'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Doctors DataTable
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Specialization')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: doctors.map((doctor) {
                      return DataRow(cells: [
                        DataCell(Text(doctor.id)),
                        DataCell(Text(doctor.name)),
                        DataCell(Text(doctor.specialization)),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditDoctorDialog(context, doctor),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteDoctor(context, doctor.id),
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
