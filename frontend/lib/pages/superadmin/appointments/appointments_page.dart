import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../../providers/data_provider.dart';
import '../../../models/appointment.dart';
import '../../../models/patient.dart';
import '../../../models/doctor.dart';

// Shared components
import '../../../shared/components/components.dart';
// Using only BetterPaginatedDataTable reference? We actually use BetterDataTable:
import '../../../shared/components/responsive_data_table.dart' show BetterDataTable;

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  String _searchQuery = '';

  // Add Appointment
  void _showAddAppointmentDialog(
      BuildContext context,
      List<Doctor> doctors,
      List<Patient> patients,
      ) {
    final formKey = GlobalKey<FormState>();
    String? patientId;
    String? doctorId;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Appointment'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Doctor'),
                  items: doctors.map((Doctor d) {
                    return DropdownMenuItem<String>(
                      value: d.id,
                      child: Text(d.name),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Select doctor' : null,
                  onChanged: (value) => doctorId = value,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Patient'),
                  items: patients.map((Patient p) {
                    return DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(p.name),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Select patient' : null,
                  onChanged: (value) => patientId = value,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate() &&
                  patientId != null &&
                  doctorId != null) {
                formKey.currentState!.save();
                final newAppt = Appointment(
                  id: 'a${DateTime.now().millisecondsSinceEpoch}',
                  patientId: patientId!,
                  doctorId: doctorId!,
                  dateTime: selectedDate,
                  status: 'Scheduled',
                );
                Provider.of<DataProvider>(context, listen: false)
                    .addAppointment(newAppt);
                Navigator.pop(ctx);
                Fluttertoast.showToast(msg: 'Appointment added successfully.');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Edit Appointment
  void _showEditAppointmentDialog(
      BuildContext context,
      Appointment appt,
      List<Doctor> doctors,
      List<Patient> patients,
      ) {
    final formKey = GlobalKey<FormState>();
    String? patientId = appt.patientId;
    String? doctorId = appt.doctorId;
    DateTime selectedDate = appt.dateTime;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Appointment'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Doctor'),
                  value: doctorId,
                  items: doctors.map((Doctor d) {
                    return DropdownMenuItem<String>(
                      value: d.id,
                      child: Text(d.name),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Select doctor' : null,
                  onChanged: (value) => doctorId = value,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Patient'),
                  value: patientId,
                  items: patients.map((Patient p) {
                    return DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(p.name),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Select patient' : null,
                  onChanged: (value) => patientId = value,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate() &&
                  patientId != null &&
                  doctorId != null) {
                final updated = Appointment(
                  id: appt.id,
                  patientId: patientId!,
                  doctorId: doctorId!,
                  dateTime: selectedDate,
                  status: appt.status,
                );
                Provider.of<DataProvider>(context, listen: false)
                    .updateAppointment(updated);
                Navigator.pop(ctx);
                Fluttertoast.showToast(
                    msg: 'Appointment updated successfully.');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Delete
  void _deleteAppointment(BuildContext context, String id) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete Appointment',
      content: 'Are you sure you want to delete this appointment?',
      confirmLabel: 'Yes',
      cancelLabel: 'No',
    );
    if (confirmed == true) {
      Provider.of<DataProvider>(context, listen: false).deleteAppointment(id);
      Fluttertoast.showToast(msg: 'Appointment deleted successfully.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (ctx, dataProvider, child) {
        final doctors = dataProvider.doctors;
        final patients = dataProvider.patients;

        // Filter appointments by ID or status
        final appointments = dataProvider.appointments.where((a) {
          final q = _searchQuery.toLowerCase();
          return a.id.toLowerCase().contains(q) ||
              a.status.toLowerCase().contains(q);
        }).toList();

        // Build rows
        final rows = appointments.map((appt) {
          return DataRow(cells: [
            DataCell(Text(appt.id)),
            DataCell(
              Text(
                patients
                    .firstWhere(
                      (p) => p.id == appt.patientId,
                  orElse: () => Patient(
                    id: 'unknown',
                    name: 'Unknown',
                    age: 0,
                    diagnosis: '',
                    doctorId: '',
                    deviceId: '',
                  ),
                )
                    .name,
              ),
            ),
            DataCell(
              Text(
                doctors
                    .firstWhere(
                      (d) => d.id == appt.doctorId,
                  orElse: () => Doctor(
                    id: 'unknown',
                    name: 'Unknown',
                    specialization: '',
                    hospitalId: '',
                  ),
                )
                    .name,
              ),
            ),
            DataCell(Text(DateFormat('yyyy-MM-dd').format(appt.dateTime))),
            DataCell(Text(appt.status)),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () =>
                        _showEditAppointmentDialog(ctx, appt, doctors, patients),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteAppointment(ctx, appt.id),
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
              // Our new shared Search + Add row
              SearchAndAddRow(
                searchLabel: 'Search Appointments',
                searchIcon: Icons.search,
                onSearchChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                addButtonLabel: 'Add Appointment',
                addButtonIcon: Icons.add,
                onAddPressed: () =>
                    _showAddAppointmentDialog(ctx, doctors, patients),
              ),
              const SizedBox(height: 20),

              // Display the table using our new BetterDataTable
              BetterDataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Patient')),
                  DataColumn(label: Text('Doctor')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Status')),
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
