import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/data_provider.dart';
import '../../../models/doctor.dart';
import '../../../models/hospital.dart';
import '../../../shared/components/loading_indicator.dart';
import '../../../shared/components/responsive_data_table.dart'
    show BetterPaginatedDataTable;
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
        title: Row(
          children: [
            Icon(Icons.person_add, color: const Color(0xFFEC407A)),
            const SizedBox(width: 10),
            const Text('Add Doctor', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Doctor Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                    onSaved: (value) => name = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Specialization',
                      prefixIcon: Icon(Icons.local_hospital),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Enter specialization' : null,
                    onSaved: (value) => specialization = value!,
                  ),
                ],
              ),
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
            label: const Text('Add Doctor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC407A),
              foregroundColor: Colors.white,
            ),
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
        title: Row(
          children: [
            Icon(Icons.edit, color: const Color(0xFFEC407A)),
            const SizedBox(width: 10),
            const Text('Edit Doctor', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    initialValue: doctor.name,
                    decoration: const InputDecoration(
                      labelText: 'Doctor Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                    onSaved: (value) => name = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: doctor.specialization,
                    decoration: const InputDecoration(
                      labelText: 'Specialization',
                      prefixIcon: Icon(Icons.local_hospital),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Enter specialization' : null,
                    onSaved: (value) => specialization = value!,
                  ),
                ],
              ),
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
            label: const Text('Save Doctor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC407A),
              foregroundColor: Colors.white,
            ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC407A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Doctors DataTable
              Expanded(
                child: doctors.isEmpty
                    ? const Center(child: Text('No doctors found.'))
                    : BetterPaginatedDataTable(
                        themeColor: const Color(0xFFEC407A),
                        rowsPerPage: 10,
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Specialization')),
                          DataColumn(label: Text('Actions')),
                        ],
                                            rows: doctors.map((doctor) {
                      return DataRow(cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            constraints: const BoxConstraints(
                              minWidth: 100,
                              maxWidth: 120,
                            ),
                            child: Text(
                              doctor.id,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            constraints: const BoxConstraints(
                              minWidth: 180,
                              maxWidth: 250,
                            ),
                            child: Text(
                              doctor.name,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            constraints: const BoxConstraints(
                              minWidth: 250,
                              maxWidth: 350,
                            ),
                            child: Text(
                              doctor.specialization,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
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
            ],
          ),
        );
      },
    );
  }
}
