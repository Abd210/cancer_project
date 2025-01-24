import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../../providers/data_provider.dart';
import '../../../models/doctor.dart';
import '../../../models/hospital.dart';

// Our new shared components:
import '../../../shared/components/components.dart';
import '../../../shared/components/responsive_data_table.dart' show BetterDataTable;

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  _DoctorsPageState createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  String _searchQuery = '';

  // Show the “Add Doctor” dialog
  void _showAddDoctorDialog(BuildContext ctx, List<Hospital> allHospitals) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String specialization = '';
    String? selectedHospitalId;

    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        title: const Text('Add Doctor'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Doctor Name'),
                  validator: (val) =>
                  (val == null || val.isEmpty) ? 'Enter name' : null,
                  onSaved: (val) => name = val ?? '',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Specialization'),
                  validator: (val) =>
                  (val == null || val.isEmpty) ? 'Enter specialization' : null,
                  onSaved: (val) => specialization = val ?? '',
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Choose Hospital'),
                  items: allHospitals.map((hospital) {
                    return DropdownMenuItem<String>(
                      value: hospital.id,
                      child: Text(hospital.name),
                    );
                  }).toList(),
                  validator: (val) => (val == null) ? 'Select a hospital' : null,
                  onChanged: (val) => selectedHospitalId = val,
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
                  hospitalId: selectedHospitalId ?? '',
                );

                Provider.of<DataProvider>(ctx, listen: false)
                    .addDoctor(newDoctor);
                Navigator.pop(ctx);
                Fluttertoast.showToast(msg: 'Doctor added successfully.');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Show the “Edit Doctor” dialog
  void _showEditDoctorDialog(
      BuildContext ctx,
      Doctor doctor,
      List<Hospital> allHospitals,
      ) {
    final formKey = GlobalKey<FormState>();
    String name = doctor.name;
    String specialization = doctor.specialization;
    String? selectedHospitalId = doctor.hospitalId;

    showDialog(
      context: ctx,
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
                  validator: (val) =>
                  (val == null || val.isEmpty) ? 'Enter name' : null,
                  onSaved: (val) => name = val ?? '',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: specialization,
                  decoration: const InputDecoration(labelText: 'Specialization'),
                  validator: (val) =>
                  (val == null || val.isEmpty) ? 'Enter specialization' : null,
                  onSaved: (val) => specialization = val ?? '',
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedHospitalId,
                  decoration: const InputDecoration(labelText: 'Choose Hospital'),
                  items: allHospitals.map((hospital) {
                    return DropdownMenuItem<String>(
                      value: hospital.id,
                      child: Text(hospital.name),
                    );
                  }).toList(),
                  validator: (val) => (val == null) ? 'Select a hospital' : null,
                  onChanged: (val) => selectedHospitalId = val,
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
                  hospitalId: selectedHospitalId ?? '',
                );

                Provider.of<DataProvider>(ctx, listen: false)
                    .updateDoctor(updatedDoctor);
                Navigator.pop(ctx);
                Fluttertoast.showToast(msg: 'Doctor updated successfully.');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Delete Doctor
  void _deleteDoctor(BuildContext ctx, String id) async {
    final confirmed = await showConfirmationDialog(
      context: ctx,
      title: 'Delete Doctor',
      content: 'Are you sure you want to delete this doctor?',
      confirmLabel: 'Yes',
      cancelLabel: 'No',
    );
    if (confirmed == true) {
      Provider.of<DataProvider>(ctx, listen: false).deleteDoctor(id);
      Fluttertoast.showToast(msg: 'Doctor deleted successfully.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (ctx, dataProvider, child) {
        // 1) Filter doctors by search
        final allDoctors = dataProvider.doctors.where((doc) {
          final q = _searchQuery.toLowerCase();
          return doc.name.toLowerCase().contains(q) ||
              doc.specialization.toLowerCase().contains(q) ||
              doc.id.toLowerCase().contains(q);
        }).toList();

        // 2) Build the rows
        final rows = allDoctors.map((doctor) {
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
                    onPressed: () => _showEditDoctorDialog(
                      ctx,
                      doctor,
                      dataProvider.hospitals,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteDoctor(ctx, doctor.id),
                  ),
                ],
              ),
            ),
          ]);
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search + Add
              SearchAndAddRow(
                searchLabel: 'Search Doctors',
                searchIcon: Icons.search,
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                addButtonLabel: 'Add Doctor',
                addButtonIcon: Icons.add,
                onAddPressed: () =>
                    _showAddDoctorDialog(ctx, dataProvider.hospitals),
              ),
              const SizedBox(height: 20),

              // Display the table
              BetterDataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Specialization')),
                  DataColumn(label: Text('Hospital')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: rows,
              ),
            ],
          ),
        );
      },
    );
  }
}
