import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../../providers/data_provider.dart';
import '../../../models/device.dart';
import '../../../models/patient.dart';

// Shared components
import '../../../shared/components/components.dart';
import '../../../shared/components/responsive_data_table.dart' show BetterDataTable;

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  _DevicesPageState createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  String _searchQuery = '';

  // Add Device
  void _showAddDeviceDialog(BuildContext ctx, List<Patient> allPatients) {
    final formKey = GlobalKey<FormState>();
    String type = '';
    String? selectedPatientId;

    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        title: const Text('Add Device'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Device Type'),
                  validator: (val) =>
                  val == null || val.isEmpty ? 'Enter device type' : null,
                  onSaved: (val) => type = val ?? '',
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration:
                  const InputDecoration(labelText: 'Assign to Patient'),
                  items: allPatients.map((p) {
                    return DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name),
                    );
                  }).toList(),
                  validator: (val) => val == null ? 'Select a patient' : null,
                  onChanged: (val) => selectedPatientId = val,
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
                final newDevice = Device(
                  id: 'dev${DateTime.now().millisecondsSinceEpoch}',
                  type: type,
                  patientId: selectedPatientId ?? '',
                );
                Provider.of<DataProvider>(ctx, listen: false)
                    .addDevice(newDevice);
                Navigator.pop(ctx);
                Fluttertoast.showToast(msg: 'Device added successfully.');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Edit Device
  void _showEditDeviceDialog(
      BuildContext ctx,
      Device device,
      List<Patient> allPatients,
      ) {
    final formKey = GlobalKey<FormState>();
    String type = device.type;
    String? selectedPatientId = device.patientId;

    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        title: const Text('Edit Device'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Device Type'),
                  validator: (val) =>
                  val == null || val.isEmpty ? 'Enter device type' : null,
                  onSaved: (val) => type = val ?? '',
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration:
                  const InputDecoration(labelText: 'Assign to Patient'),
                  value: selectedPatientId?.isEmpty ?? true
                      ? null
                      : selectedPatientId,
                  items: allPatients.map((p) {
                    return DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(p.name),
                    );
                  }).toList(),
                  validator: (val) => val == null ? 'Select a patient' : null,
                  onChanged: (val) => selectedPatientId = val,
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
                final updated = Device(
                  id: device.id,
                  type: type,
                  patientId: selectedPatientId ?? '',
                );
                Provider.of<DataProvider>(ctx, listen: false)
                    .updateDevice(updated);
                Navigator.pop(ctx);
                Fluttertoast.showToast(msg: 'Device updated successfully.');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Delete Device
  void _deleteDevice(BuildContext ctx, String id) async {
    final confirmed = await showConfirmationDialog(
      context: ctx,
      title: 'Delete Device',
      content: 'Are you sure you want to delete this device?',
      confirmLabel: 'Yes',
      cancelLabel: 'No',
    );
    if (confirmed == true) {
      Provider.of<DataProvider>(ctx, listen: false).deleteDevice(id);
      Fluttertoast.showToast(msg: 'Device deleted successfully.');
    }
  }

  // Helper
  String _getPatientName(DataProvider dataProvider, String patientId) {
    final p = dataProvider.patients.firstWhere(
          (pp) => pp.id == patientId,
      orElse: () => Patient(
        id: '',
        name: '',
        age: 0,
        diagnosis: '',
        doctorId: '',
        deviceId: '',
      ),
    );
    return p.name.isEmpty ? 'Unassigned' : p.name;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (ctx, dataProvider, child) {
        final allPatients = dataProvider.patients;
        final devices = dataProvider.devices.where((d) {
          return d.type.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        final rows = devices.map((dev) {
          return DataRow(cells: [
            DataCell(Text(dev.id)),
            DataCell(Text(dev.type)),
            DataCell(Text(_getPatientName(dataProvider, dev.patientId))),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditDeviceDialog(ctx, dev, allPatients),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteDevice(ctx, dev.id),
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
              // Reusable search + add
              SearchAndAddRow(
                searchLabel: 'Search Devices',
                searchIcon: Icons.search,
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                addButtonLabel: 'Add Device',
                addButtonIcon: Icons.add,
                onAddPressed: () => _showAddDeviceDialog(ctx, allPatients),
              ),
              const SizedBox(height: 20),

              BetterDataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Assigned To')),
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
