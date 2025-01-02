import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/data_provider.dart';
import '../../../models/doctor.dart';
import '../../../models/hospital.dart';
import '../../../shared/components/loading_indicator.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  _DoctorsPageState createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  String _searchQuery = '';
  final bool _isLoading = false;

  void _showAddDoctorDialog(BuildContext context, List<Hospital> allHospitals) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String specialization = '';
    String? selectedHospitalId; // from dropdown

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
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter name' : null,
                  onSaved: (value) => name = value!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Specialization'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter specialization' : null,
                  onSaved: (value) => specialization = value!,
                ),
                const SizedBox(height: 10),
                // Hospital dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Choose Hospital'),
                  items: allHospitals.map((hospital) {
                    return DropdownMenuItem<String>(
                      value: hospital.id,
                      child: Text(hospital.name),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Select a hospital' : null,
                  onChanged: (value) => selectedHospitalId = value,
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
                // Create new doctor
                final newDoctor = Doctor(
                  id: 'd${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  specialization: specialization,
                  hospitalId: selectedHospitalId!,
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

  void _showEditDoctorDialog(
      BuildContext context, Doctor doctor, List<Hospital> allHospitals) {
    final formKey = GlobalKey<FormState>();
    String name = doctor.name;
    String specialization = doctor.specialization;
    String? selectedHospitalId = doctor.hospitalId;

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
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Doctor Name'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter name' : null,
                  onSaved: (value) => name = value!,
                ),
                TextFormField(
                  initialValue: specialization,
                  decoration: const InputDecoration(labelText: 'Specialization'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter specialization' : null,
                  onSaved: (value) => specialization = value!,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Choose Hospital'),
                  value: selectedHospitalId,
                  items: allHospitals.map((hospital) {
                    return DropdownMenuItem<String>(
                      value: hospital.id,
                      child: Text(hospital.name),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Select a hospital' : null,
                  onChanged: (value) => selectedHospitalId = value,
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
                  hospitalId: selectedHospitalId!,
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
          return const LoadingIndicator(); // if needed
        }

        // We can filter by name/specialization if we want
        List<Doctor> doctors = dataProvider.doctors.where((doc) {
          return doc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              doc.specialization.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        // Get all hospitals for the dropdown
        List<Hospital> allHospitals = dataProvider.hospitals;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search + Add
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
                    onPressed: () => _showAddDoctorDialog(context, allHospitals),
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
                      DataColumn(label: Text('Hospital')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: doctors.map((doctor) {
                      final hospital = dataProvider.hospitals.firstWhere(
                        (h) => h.id == doctor.hospitalId,
                        orElse: () => Hospital(id: '', name: 'Unknown', address: ''),
                      );
                      return DataRow(cells: [
                        DataCell(Text(doctor.id)),
                        DataCell(Text(doctor.name)),
                        DataCell(Text(doctor.specialization)),
                        DataCell(Text(hospital.name)),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditDoctorDialog(context, doctor, allHospitals),
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
