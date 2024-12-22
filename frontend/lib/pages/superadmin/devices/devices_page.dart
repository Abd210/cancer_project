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

  void _showAddDeviceDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String type = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Device'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            decoration: InputDecoration(labelText: 'Device Type'),
            validator: (value) => value == null || value.isEmpty ? 'Enter device type' : null,
            onSaved: (value) => type = value!,
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
                  patientId: '',
                );
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

  void _showEditDeviceDialog(BuildContext context, Device device) {
    final _formKey = GlobalKey<FormState>();
    String type = device.type;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Device'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            initialValue: device.type,
            decoration: InputDecoration(labelText: 'Device Type'),
            validator: (value) => value == null || value.isEmpty ? 'Enter device type' : null,
            onSaved: (value) => type = value!,
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
                  patientId: device.patientId,
                );
                Provider.of<DataProvider>(context, listen: false).updateDevice(updatedDevice);
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
        List<Device> devices = dataProvider.devices
            .where((d) => d.type.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        List<Patient> patients = dataProvider.patients;

        String getPatientName(String patientId) {
          final patient = patients.firstWhere((p) => p.id == patientId, orElse: () => Patient(id: 'unknown', name: 'Unassigned', age: 0, diagnosis: '', doctorId: '', deviceId: ''));
          return patient.name.isEmpty ? 'Unassigned' : patient.name;
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
                        labelText: 'Search Devices',
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
                    onPressed: () => _showAddDeviceDialog(context),
                    icon: Icon(Icons.add),
                    label: Text('Add Device'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Devices DataTable with Edit and Delete
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
                      return DataRow(cells: [
                        DataCell(Text(device.id)),
                        DataCell(Text(device.type)),
                        DataCell(Text(getPatientName(device.patientId))),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditDeviceDialog(context, device),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteDevice(context, device.id),
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
