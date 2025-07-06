import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/data_provider.dart';
import '../../../models/patient.dart';
import '../../../models/doctor.dart';
import '../../../models/device.dart';
import '../../../shared/components/loading_indicator.dart';
import '../../../shared/components/responsive_data_table.dart'
    show BetterPaginatedDataTable;
import 'package:fluttertoast/fluttertoast.dart';

class HospitalPatientsPage extends StatefulWidget {
  final String hospitalId;

  const HospitalPatientsPage({super.key, required this.hospitalId});

  @override
  _HospitalPatientsPageState createState() => _HospitalPatientsPageState();
}

class _HospitalPatientsPageState extends State<HospitalPatientsPage> {
  String _searchQuery = '';
  final bool _isLoading = false;

  void _showAddPatientDialog(BuildContext context, List<Doctor> hospitalDoctors, List<Device> unassignedDevices) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    int age = 0;
    String diagnosis = '';
    String? doctorId;
    String? deviceId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_add, color: const Color(0xFFEC407A)),
            const SizedBox(width: 10),
            const Text('Add Patient', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      labelText: 'Patient Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                    onSaved: (value) => name = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      prefixIcon: Icon(Icons.cake),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter age';
                      if (int.tryParse(value) == null) return 'Enter valid age';
                      return null;
                    },
                    onSaved: (value) => age = int.parse(value!),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Diagnosis',
                      prefixIcon: Icon(Icons.medical_services),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Enter diagnosis' : null,
                    onSaved: (value) => diagnosis = value!,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Assign Doctor',
                      prefixIcon: Icon(Icons.local_hospital),
                      border: OutlineInputBorder(),
                    ),
                    items: hospitalDoctors.map((Doctor doctor) {
                      return DropdownMenuItem<String>(
                        value: doctor.id,
                        child: Text(doctor.name),
                      );
                    }).toList(),
                    validator: (value) => value == null ? 'Select a doctor' : null,
                    onChanged: (value) => doctorId = value,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Assign Device',
                      prefixIcon: Icon(Icons.devices),
                      border: OutlineInputBorder(),
                    ),
                    items: unassignedDevices.map((Device device) {
                      return DropdownMenuItem<String>(
                        value: device.id,
                        child: Text(device.type),
                      );
                    }).toList(),
                    validator: (value) => value == null ? 'Select a device' : null,
                    onChanged: (value) => deviceId = value,
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
            label: const Text('Add Patient'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC407A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate() && doctorId != null && deviceId != null) {
                formKey.currentState!.save();
                final newPatient = Patient(
                  id: 'p${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  age: age,
                  diagnosis: diagnosis,
                  doctorId: doctorId!,
                  deviceId: deviceId!,
                );
                Provider.of<DataProvider>(context, listen: false).addPatient(newPatient);

                // Assign device to the new patient
                final device = Provider.of<DataProvider>(context, listen: false)
                    .devices
                    .firstWhere((d) => d.id == deviceId);
                device.patientId = newPatient.id;
                Provider.of<DataProvider>(context, listen: false).updateDevice(device);

                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Patient added successfully.');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditPatientDialog(
    BuildContext context,
    Patient patient,
    List<Doctor> hospitalDoctors,
    List<Device> availableDevices,
  ) {
    final formKey = GlobalKey<FormState>();
    String name = patient.name;
    int age = patient.age;
    String diagnosis = patient.diagnosis;
    String? doctorId = patient.doctorId;
    String? deviceId = patient.deviceId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: const Color(0xFFEC407A)),
            const SizedBox(width: 10),
            const Text('Edit Patient', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    initialValue: name,
                    decoration: const InputDecoration(
                      labelText: 'Patient Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                    onSaved: (value) => name = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: age.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      prefixIcon: Icon(Icons.cake),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter age';
                      if (int.tryParse(value) == null) return 'Enter a valid age';
                      return null;
                    },
                    onSaved: (value) => age = int.parse(value!),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: diagnosis,
                    decoration: const InputDecoration(
                      labelText: 'Diagnosis',
                      prefixIcon: Icon(Icons.medical_services),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Enter diagnosis' : null,
                    onSaved: (value) => diagnosis = value!,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: doctorId,
                    decoration: const InputDecoration(
                      labelText: 'Assign Doctor',
                      prefixIcon: Icon(Icons.local_hospital),
                      border: OutlineInputBorder(),
                    ),
                    items: hospitalDoctors.map((Doctor doctor) {
                      return DropdownMenuItem<String>(
                        value: doctor.id,
                        child: Text(doctor.name),
                      );
                    }).toList(),
                    validator: (value) => value == null ? 'Select a doctor' : null,
                    onChanged: (value) => doctorId = value,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: deviceId,
                    decoration: const InputDecoration(
                      labelText: 'Assign Device',
                      prefixIcon: Icon(Icons.devices),
                      border: OutlineInputBorder(),
                    ),
                    items: availableDevices.map((Device device) {
                      return DropdownMenuItem<String>(
                        value: device.id,
                        child: Text(device.type),
                      );
                    }).toList(),
                    validator: (value) => value == null ? 'Select a device' : null,
                    onChanged: (value) => deviceId = value,
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
            label: const Text('Save Patient'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC407A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate() && doctorId != null && deviceId != null) {
                formKey.currentState!.save();
                final updatedPatient = Patient(
                  id: patient.id,
                  name: name,
                  age: age,
                  diagnosis: diagnosis,
                  doctorId: doctorId!,
                  deviceId: deviceId!,
                );

                Provider.of<DataProvider>(context, listen: false).updatePatient(updatedPatient);

                // Assign device to the updated patient
                final device = Provider.of<DataProvider>(context, listen: false)
                    .devices
                    .firstWhere((d) => d.id == deviceId);
                device.patientId = updatedPatient.id;
                Provider.of<DataProvider>(context, listen: false).updateDevice(device);

                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Patient updated successfully.');
              }
            },
          ),
        ],
      ),
    );
  }

  void _deletePatient(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: const Text('Are you sure you want to delete this patient?'),
        actions: [
          TextButton(
            onPressed: () {
              // Remove device assignment
              final patient = Provider.of<DataProvider>(context, listen: false)
                  .patients
                  .firstWhere((p) => p.id == id);
              final device = Provider.of<DataProvider>(context, listen: false)
                  .devices
                  .firstWhere((d) => d.id == patient.deviceId, orElse: () => Device(id: '', type: '', patientId: ''));
              if (device.id.isNotEmpty) {
                device.patientId = '';
                Provider.of<DataProvider>(context, listen: false).updateDevice(device);
              }

              Provider.of<DataProvider>(context, listen: false).deletePatient(id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Patient deleted successfully.');
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

        // Get all doctors that belong to this hospital
        List<Doctor> hospitalDoctors = dataProvider.doctors
            .where((d) => d.hospitalId == widget.hospitalId)
            .toList();

        // Filter patients by checking if their doctor belongs to this hospital
        List<Patient> hospitalPatients = dataProvider.patients.where((p) {
          final doctor = dataProvider.doctors.firstWhere(
            (d) => d.id == p.doctorId,
            orElse: () => Doctor(id: '', name: '', specialization: '', hospitalId: ''),
          );
          return doctor.hospitalId == widget.hospitalId;
        }).where((p) {
          return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.diagnosis.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        // Get devices that are either unassigned or assigned to these patients
        List<Device> unassignedDevices = dataProvider.devices.where((d) => d.patientId.isEmpty).toList();
        List<Device> hospitalDevices = dataProvider.devices.where((d) {
          final patient = dataProvider.patients.firstWhere(
            (p) => p.id == d.patientId,
            orElse: () => Patient(id: '', name: '', age: 0, diagnosis: '', doctorId: '', deviceId: ''),
          );
          final doc = dataProvider.doctors.firstWhere(
            (doc) => doc.id == patient.doctorId,
            orElse: () => Doctor(id: '', name: '', specialization: '', hospitalId: ''),
          );
          return doc.hospitalId == widget.hospitalId;
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Title + Search + Add
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Search Patients',
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
                    onPressed: () => _showAddPatientDialog(context, hospitalDoctors, unassignedDevices),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Patient'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC407A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Patients DataTable
              Expanded(
                child: hospitalPatients.isEmpty
                    ? const Center(child: Text('No patients found.'))
                    : BetterPaginatedDataTable(
                        themeColor: const Color(0xFFEC407A),
                        rowsPerPage: 10,
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Age')),
                          DataColumn(label: Text('Diagnosis')),
                          DataColumn(label: Text('Doctor')),
                          DataColumn(label: Text('Device')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: hospitalPatients.map((patient) {
                          final doc = hospitalDoctors.firstWhere(
                            (d) => d.id == patient.doctorId,
                            orElse: () => Doctor(id: '', name: 'Unknown', specialization: '', hospitalId: ''),
                          );
                          final device = dataProvider.devices.firstWhere(
                            (dev) => dev.id == patient.deviceId,
                            orElse: () => Device(id: 'unknown', type: 'Unassigned', patientId: ''),
                          );

                          return DataRow(cells: [
                            DataCell(Text(patient.id)),
                            DataCell(Text(patient.name)),
                            DataCell(Text(patient.age.toString())),
                            DataCell(Text(patient.diagnosis)),
                            DataCell(Text(doc.name)),
                            DataCell(Text(device.type)),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditPatientDialog(
                                      context,
                                      patient,
                                      hospitalDoctors,
                                      [...unassignedDevices, ...hospitalDevices],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deletePatient(context, patient.id),
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
