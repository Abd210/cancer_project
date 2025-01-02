import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/data_provider.dart';
import '../../../models/device.dart';
import '../../../models/patient.dart';
import '../../../shared/components/loading_indicator.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HospitalDevicesPage extends StatefulWidget {
  final String hospitalId;

  const HospitalDevicesPage({super.key, required this.hospitalId});

  @override
  _HospitalDevicesPageState createState() => _HospitalDevicesPageState();
}

class _HospitalDevicesPageState extends State<HospitalDevicesPage> {
  String _searchQuery = '';
  final bool _isLoading = false;

  /// NO addDevice or editDevice for hospital
  /// We only show a "delete" icon that unassigns the device from this hospital.

  void _deleteDeviceForHospital(BuildContext context, Device device) {
    // “Deleting” for the hospital means unassigning the device’s patientId 
    // if that patient belongs to this hospital.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unassign Device'),
        content: const Text(
            'Are you sure you want to remove this device from your hospital’s patient?'),
        actions: [
          TextButton(
            onPressed: () {
              // 1) We unassign if indeed the device is assigned to one of 
              //    this hospital’s patients
              Provider.of<DataProvider>(context, listen: false).unassignDeviceFromHospital(
                device, 
                widget.hospitalId,
              );

              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: 'Device unassigned for this hospital successfully.',
              );
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

        // 1) Doctors for THIS hospital
        final hospitalDoctors = dataProvider.doctors
            .where((d) => d.hospitalId == widget.hospitalId)
            .toList();

        // 2) Patients for those doctors
        final hospitalPatients = dataProvider.patients.where((p) {
          return hospitalDoctors.any((doc) => doc.id == p.doctorId);
        }).toList();

        // 3) Filter devices: 
        //    Must have .patientId assigned to one of hospital’s patients
        //    (skip unassigned or assigned to patients from other hospitals)
        List<Device> devices = dataProvider.devices
            .where((device) {
              if (device.patientId.isEmpty) return false;
              return hospitalPatients.any((p) => p.id == device.patientId);
            })
            .where((device) => device.type
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

        // Helper for displaying patient name
        String getPatientName(String patientId) {
          final patient = hospitalPatients.firstWhere(
            (p) => p.id == patientId,
            orElse: () => Patient(
              id: '',
              name: 'Unknown',
              age: 0,
              diagnosis: '',
              doctorId: '',
              deviceId: '',
            ),
          );
          return patient.name.isEmpty ? 'Unknown' : patient.name;
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ONLY a search bar, no Add device button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Search Devices',
                        prefixIcon: const Icon(Icons.search),
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
                  // No "add" button for hospital
                ],
              ),
              const SizedBox(height: 20),

              // Show the filtered devices in a DataTable
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Assigned To')),
                      DataColumn(label: Text('Actions')), // only "Delete" here
                    ],
                    rows: devices.map((device) {
                      return DataRow(cells: [
                        DataCell(Text(device.id)),
                        DataCell(Text(device.type)),
                        DataCell(Text(getPatientName(device.patientId))),
                        // Hospital can only "delete" (unassign) 
                        DataCell(
                          Row(
                            children: [
                              // We remove the "edit" button: no IconButton(Icons.edit)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteDeviceForHospital(context, device),
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
