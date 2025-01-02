// lib/pages/superadmin/appointments/appointments_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/data_provider.dart';
import '../../../models/appointment.dart';
import '../../../models/patient.dart';
import '../../../models/doctor.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  String _searchQuery = '';
  final bool _isLoading = false;

  void _showAddAppointmentDialog(BuildContext context, List<Doctor> doctors, List<Patient> patients) {
    final formKey = GlobalKey<FormState>();
    String? patientId;
    String? doctorId;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Appointment'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Doctor'),
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
                decoration: const InputDecoration(labelText: 'Select Patient'),
                items: patients.map((Patient patient) {
                  return DropdownMenuItem<String>(
                    value: patient.id,
                    child: Text(patient.name),
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
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
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
        actions: [
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate() && patientId != null && doctorId != null) {
                formKey.currentState!.save();
                final newAppointment = Appointment(
                  id: 'a${DateTime.now().millisecondsSinceEpoch}',
                  patientId: patientId!,
                  doctorId: doctorId!,
                  dateTime: selectedDate,
                  status: 'Scheduled',
                );
                Provider.of<DataProvider>(context, listen: false).addAppointment(newAppointment);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Appointment added successfully.');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditAppointmentDialog(BuildContext context, Appointment appointment, List<Doctor> doctors, List<Patient> patients) {
    final formKey = GlobalKey<FormState>();
    String? patientId = appointment.patientId;
    String? doctorId = appointment.doctorId;
    DateTime selectedDate = appointment.dateTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Appointment'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Doctor'),
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
                decoration: const InputDecoration(labelText: 'Select Patient'),
                value: patientId,
                items: patients.map((Patient patient) {
                  return DropdownMenuItem<String>(
                    value: patient.id,
                    child: Text(patient.name),
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
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
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
        actions: [
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate() && patientId != null && doctorId != null) {
                formKey.currentState!.save();
                final updatedAppointment = Appointment(
                  id: appointment.id,
                  patientId: patientId!,
                  doctorId: doctorId!,
                  dateTime: selectedDate,
                  status: appointment.status,
                );
                Provider.of<DataProvider>(context, listen: false).updateAppointment(updatedAppointment);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Appointment updated successfully.');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteAppointment(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure you want to delete this appointment?'),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<DataProvider>(context, listen: false).deleteAppointment(id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Appointment deleted successfully.');
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
        List<Appointment> appointments = dataProvider.appointments
            .where((a) =>
        a.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            a.status.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        List<Doctor> doctors = dataProvider.doctors;
        List<Patient> patients = dataProvider.patients;

        String getDoctorName(String doctorId) {
          final doctor = doctors.firstWhere((d) => d.id == doctorId, orElse: () => Doctor(id: 'unknown', name: 'Unknown', specialization: '', hospitalId: ''));
          return doctor.name;
        }

        String getPatientName(String patientId) {
          final patient = patients.firstWhere((p) => p.id == patientId, orElse: () => Patient(id: 'unknown', name: 'Unknown', age: 0, diagnosis: '', doctorId: '', deviceId: ''));
          return patient.name;
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
                        labelText: 'Search Appointments',
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
                    onPressed: () => _showAddAppointmentDialog(context, doctors, patients),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Appointment'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Appointments DataTable with Edit and Delete
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Patient')),
                      DataColumn(label: Text('Doctor')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: appointments.map((appointment) {
                      return DataRow(cells: [
                        DataCell(Text(appointment.id)),
                        DataCell(Text(getPatientName(appointment.patientId))),
                        DataCell(Text(getDoctorName(appointment.doctorId))),
                        DataCell(Text(DateFormat('yyyy-MM-dd').format(appointment.dateTime))),
                        DataCell(Text(appointment.status)),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditAppointmentDialog(context, appointment, doctors, patients),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAppointment(context, appointment.id),
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
