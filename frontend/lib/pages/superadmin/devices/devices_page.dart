// lib/pages/superadmin/devices/devices_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/data_provider.dart';
import '../../../models/device.dart';
import '../../../models/patient.dart';
import '../../../shared/components/loading_indicator.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({Key? key}) : super(key: key);

  @override
  _DevicesPageState createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  String _searchQuery = '';
  bool _isLoading = false;

  /// When adding a device, we require picking a patient from a dropdown.
  void _showAddDeviceDialog(BuildContext context, List<Patient> allPatients) {
    final _formKey = GlobalKey<FormState>();
    String type = '';
    String? selectedPatientId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Device'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Device Type
                TextFormField(
                  decoration: InputDecoration(labelText: 'Device Type'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter device type' : null,
                  onSaved: (value) => type = value!,
                ),
                SizedBox(height: 10),
                // Must pick a patient
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Assign to Patient'),
                  items: allPatients.map((p) {
                    return DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(p.name),
                    );
                  }).toList(),
                  // The user must pick a patient => no 'unassigned' option
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Select a patient' : null,
                  onChanged: (value) => selectedPatientId = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                final newDevice = Device(
                  id: 'dev${DateTime.now().millisecondsSinceEpoch}',
                  type: type,
                  patientId: selectedPatientId!,
                );

                // Add the device
                Provider.of<DataProvider>(context, listen: false).addDevice(newDevice);

                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Device added successfully.');
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  /// When editing a device, also require exactly one patient.
  void _showEditDeviceDialog(
      BuildContext context, Device device, List<Patient> allPatients) {
    final _formKey = GlobalKey<FormState>();
    String type = device.type;
    String? selectedPatientId = device.patientId; // currently assigned

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Device'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Device type
                TextFormField(
                  initialValue: type,
                  decoration: InputDecoration(labelText: 'Device Type'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter device type' : null,
                  onSaved: (value) => type = value!,
                ),
                SizedBox(height: 10),
                // Must pick a patient
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Assign to Patient'),
                    value: (selectedPatientId?.isEmpty ?? true)
                      ? null
                      : selectedPatientId,
                  items: allPatients.map((p) {
                    return DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(p.name),
                    );
                  }).toList(),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Select a patient' : null,
                  onChanged: (value) => selectedPatientId = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                final updatedDevice = Device(
                  id: device.id,
                  type: type,
                  patientId: selectedPatientId!,
                );

                Provider.of<DataProvider>(context, listen: false)
                    .updateDevice(updatedDevice);

                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Device updated successfully.');
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteDevice(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Device'),
        content: Text('Are you sure you want to delete this device?'),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<DataProvider>(context, listen: false).deleteDevice(id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Device deleted successfully.');
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
        if (_isLoading) {
          return LoadingIndicator();
        }

        // Filter devices by search
        List<Device> devices = dataProvider.devices
            .where((d) => d.type.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        // We'll get all patients so we can choose from them
        List<Patient> allPatients = dataProvider.patients;

        String getPatientName(String patientId) {
          final patient = allPatients.firstWhere(
            (p) => p.id == patientId,
            orElse: () => Patient(
              id: '',
              name: '',
              age: 0,
              diagnosis: '',
              doctorId: '',
              deviceId: '',
            ),
          );
          return patient.name.isEmpty ? 'Unassigned' : patient.name;
        }

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
                        labelText: 'Search Devices',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                    onPressed: () => _showAddDeviceDialog(context, allPatients),
                    icon: Icon(Icons.add),
                    label: Text('Add Device'),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Devices DataTable
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Assigned To')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: devices.map((device) {
                      return DataRow(
                        cells: [
                          DataCell(Text(device.id)),
                          DataCell(Text(device.type)),
                          DataCell(Text(getPatientName(device.patientId))),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditDeviceDialog(
                                    context,
                                    device,
                                    allPatients,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteDevice(context, device.id),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
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
