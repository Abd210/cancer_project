// lib/pages/superadmin/patients/patients_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/data_provider.dart';
import '../../../models/patient.dart';
import '../../../models/doctor.dart';
import '../../../models/device.dart';
import '../../../shared/components/loading_indicator.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({Key? key}) : super(key: key);

  @override
  _PatientsPageState createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  String _searchQuery = '';
  bool _isLoading = false;

  void _showAddPatientDialog(BuildContext context, List<Doctor> doctors, List<Device> devices) {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    int age = 0;
    String diagnosis = '';
    String? doctorId;
    String? deviceId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Patient'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Patient Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                  onSaved: (value) => name = value!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Age'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter age';
                    if (int.tryParse(value) == null) return 'Enter valid age';
                    return null;
                  },
                  onSaved: (value) => age = int.parse(value!),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Diagnosis'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter diagnosis' : null,
                  onSaved: (value) => diagnosis = value!,
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Assign Doctor'),
                  items: doctors.map((Doctor doctor) {
                    return DropdownMenuItem<String>(
                      value: doctor.id,
                      child: Text(doctor.name),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Select doctor' : null,
                  onChanged: (value) => doctorId = value,
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Assign Device'),
                  items: devices.where((d) => d.patientId.isEmpty).map((Device device) {
                    return DropdownMenuItem<String>(
                      value: device.id,
                      child: Text(device.type),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Select device' : null,
                  onChanged: (value) => deviceId = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate() && doctorId != null && deviceId != null) {
                _formKey.currentState!.save();
                final newPatient = Patient(
                  id: 'p${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  age: age,
                  diagnosis: diagnosis,
                  doctorId: doctorId!,
                  deviceId: deviceId!,
                );
                Provider.of<DataProvider>(context, listen: false).addPatient(newPatient);
                // Assign device to patient
                final device = Provider.of<DataProvider>(context, listen: false).devices.firstWhere((d) => d.id == deviceId);
                device.patientId = newPatient.id;
                Provider.of<DataProvider>(context, listen: false).updateDevice(device);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Patient added successfully.');
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditPatientDialog(BuildContext context, Patient patient, List<Doctor> doctors, List<Device> devices) {
    final _formKey = GlobalKey<FormState>();
    String name = patient.name;
    int age = patient.age;
    String diagnosis = patient.diagnosis;
    String? doctorId = patient.doctorId;
    String? deviceId = patient.deviceId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Patient'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  initialValue: patient.name,
                  decoration: InputDecoration(labelText: 'Patient Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                  onSaved: (value) => name = value!,
                ),
                TextFormField(
                  initialValue: patient.age.toString(),
                  decoration: InputDecoration(labelText: 'Age'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter age';
                    if (int.tryParse(value) == null) return 'Enter valid age';
                    return null;
                  },
                  onSaved: (value) => age = int.parse(value!),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  initialValue: patient.diagnosis,
                  decoration: InputDecoration(labelText: 'Diagnosis'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter diagnosis' : null,
                  onSaved: (value) => diagnosis = value!,
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Assign Doctor'),
                  value: doctorId,
                  items: doctors.map((Doctor doctor) {
                    return DropdownMenuItem<String>(
                      value: doctor.id,
                      child: Text(doctor.name),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Select doctor' : null,
                  onChanged: (value) => doctorId = value,
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Assign Device'),
                  value: deviceId,
                  items: devices.where((d) => d.patientId.isEmpty || d.patientId == patient.id).map((Device device) {
                    return DropdownMenuItem<String>(
                      value: device.id,
                      child: Text(device.type),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Select device' : null,
                  onChanged: (value) => deviceId = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate() && doctorId != null && deviceId != null) {
                _formKey.currentState!.save();
                final updatedPatient = Patient(
                  id: patient.id,
                  name: name,
                  age: age,
                  diagnosis: diagnosis,
                  doctorId: doctorId!,
                  deviceId: deviceId!,
                );
                Provider.of<DataProvider>(context, listen: false).updatePatient(updatedPatient);
                // Assign device to patient
                final device = Provider.of<DataProvider>(context, listen: false).devices.firstWhere((d) => d.id == deviceId);
                device.patientId = updatedPatient.id;
                Provider.of<DataProvider>(context, listen: false).updateDevice(device);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Patient updated successfully.');
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deletePatient(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Patient'),
        content: Text('Are you sure you want to delete this patient?'),
        actions: [
          TextButton(
            onPressed: () {
              // Remove device assignment
              final patient = Provider.of<DataProvider>(context, listen: false).patients.firstWhere((p) => p.id == id);
              final device = Provider.of<DataProvider>(context, listen: false).devices.firstWhere((d) => d.id == patient.deviceId, orElse: () => Device(id: '', type: '', patientId: ''));
              if (device.id.isNotEmpty) {
                device.patientId = '';
                Provider.of<DataProvider>(context, listen: false).updateDevice(device);
              }
              Provider.of<DataProvider>(context, listen: false).deletePatient(id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Patient deleted successfully.');
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
        List<Patient> patients = dataProvider.patients
            .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.diagnosis.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        List<Doctor> doctors = dataProvider.doctors;
        List<Device> devices = dataProvider.devices;

        String getDoctorName(String doctorId) {
          final doctor = doctors.firstWhere((d) => d.id == doctorId, orElse: () => Doctor(id: 'unknown', name: 'Unknown', specialization: '', hospitalId: ''));
          return doctor.name;
        }

        String getDeviceType(String deviceId) {
          final device = devices.firstWhere((d) => d.id == deviceId, orElse: () => Device(id: 'unknown', type: 'Unknown', patientId: ''));
          return device.type;
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
                        labelText: 'Search Patients',
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
                    onPressed: () => _showAddPatientDialog(context, doctors, devices),
                    icon: Icon(Icons.add),
                    label: Text('Add Patient'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Patients DataTable with Edit and Delete
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Age')),
                      DataColumn(label: Text('Diagnosis')),
                      DataColumn(label: Text('Doctor')),
                      DataColumn(label: Text('Device')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: patients.map((patient) {
                      return DataRow(cells: [
                        DataCell(Text(patient.id)),
                        DataCell(Text(patient.name)),
                        DataCell(Text(patient.age.toString())),
                        DataCell(Text(patient.diagnosis)),
                        DataCell(Text(getDoctorName(patient.doctorId))),
                        DataCell(Text(getDeviceType(patient.deviceId))),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditPatientDialog(context, patient, doctors, devices),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePatient(context, patient.id),
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
