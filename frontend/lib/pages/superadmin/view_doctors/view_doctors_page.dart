// lib/pages/superadmin/doctors/doctors_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/data_provider.dart';
import '../../../models/doctor.dart';
import '../../../models/hospital.dart';
import '../../../shared/components/loading_indicator.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({Key? key}) : super(key: key);

  @override
  _DoctorsPageState createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  String _searchQuery = '';
  bool _isLoading = false;

  void _showAddDoctorDialog(BuildContext context, List<Hospital> hospitals) {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String specialization = '';
    String? hospitalId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Doctor'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Doctor Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                  onSaved: (value) => name = value!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Specialization'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter specialization' : null,
                  onSaved: (value) => specialization = value!,
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Select Hospital'),
                  items: hospitals.map((Hospital hospital) {
                    return DropdownMenuItem<String>(
                      value: hospital.id,
                      child: Text(hospital.name),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Select hospital' : null,
                  onChanged: (value) => hospitalId = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate() && hospitalId != null) {
                _formKey.currentState!.save();
                final newDoctor = Doctor(
                  id: 'd${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  specialization: specialization,
                  hospitalId: hospitalId!,
                );
                Provider.of<DataProvider>(context, listen: false).addDoctor(newDoctor);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Doctor added successfully.');
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDoctorDialog(BuildContext context, Doctor doctor, List<Hospital> hospitals) {
    final _formKey = GlobalKey<FormState>();
    String name = doctor.name;
    String specialization = doctor.specialization;
    String? hospitalId = doctor.hospitalId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Doctor'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  initialValue: doctor.name,
                  decoration: InputDecoration(labelText: 'Doctor Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                  onSaved: (value) => name = value!,
                ),
                TextFormField(
                  initialValue: doctor.specialization,
                  decoration: InputDecoration(labelText: 'Specialization'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter specialization' : null,
                  onSaved: (value) => specialization = value!,
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Select Hospital'),
                  value: hospitalId,
                  items: hospitals.map((Hospital hospital) {
                    return DropdownMenuItem<String>(
                      value: hospital.id,
                      child: Text(hospital.name),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Select hospital' : null,
                  onChanged: (value) => hospitalId = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate() && hospitalId != null) {
                _formKey.currentState!.save();
                final updatedDoctor = Doctor(
                  id: doctor.id,
                  name: name,
                  specialization: specialization,
                  hospitalId: hospitalId!,
                );
                Provider.of<DataProvider>(context, listen: false).updateDoctor(updatedDoctor);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Doctor updated successfully.');
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteDoctor(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Doctor'),
        content: Text('Are you sure you want to delete this doctor?'),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<DataProvider>(context, listen: false).deleteDoctor(id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Doctor deleted successfully.');
            },
            child: Text('Yes', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        List<Doctor> doctors = dataProvider.doctors
            .where((d) => d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            d.specialization.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        List<Hospital> hospitals = dataProvider.hospitals;

        String getHospitalName(String hospitalId) {
          final hospital = hospitals.firstWhere((h) => h.id == hospitalId, orElse: () => Hospital(id: 'unknown', name: 'Unknown', address: ''));
          return hospital.name;
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search and Add Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Search Doctors',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDoctorDialog(context, hospitals),
                    icon: Icon(Icons.add),
                    label: Text('Add Doctor'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Doctors DataTable with Edit and Delete
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Specialization')),
                      DataColumn(label: Text('Hospital')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: doctors.map((doctor) {
                      return DataRow(cells: [
                        DataCell(Text(doctor.id)),
                        DataCell(Text(doctor.name)),
                        DataCell(Text(doctor.specialization)),
                        DataCell(Text(getHospitalName(doctor.hospitalId))),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditDoctorDialog(context, doctor, hospitals),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteDoctor(context, doctor.id),
                            ),
                          ],
                        )),
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
