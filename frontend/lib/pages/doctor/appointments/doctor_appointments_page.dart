// lib/pages/doctor/appointments/doctor_appointments_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/data_provider.dart';
import '../../../models/appointment.dart';

class DoctorAppointmentsPage extends StatelessWidget {
  final String doctorId;

  const DoctorAppointmentsPage({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
      ),
      body: ListView.builder(
        itemCount: dataProvider.getAppointmentsForDoctor(doctorId).length,
        itemBuilder: (context, index) {
          final appointment = dataProvider.getAppointmentsForDoctor(doctorId)[index];

          return Card(
            child: ListTile(
              title: Text("Patient ID: ${appointment.patientId}"),
              subtitle: Text("Date: ${appointment.dateTime}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      // Open a dialog to reschedule
                      _showRescheduleDialog(context, dataProvider, appointment);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Cancel the appointment
                      dataProvider.deleteAppointment(appointment.id);
                      dataProvider.addAppointmentCancelledNotification(
                        appointment.id,
                        appointment.patientId,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRescheduleDialog(
      BuildContext context, DataProvider dataProvider, Appointment appointment) {
    final TextEditingController dateTimeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reschedule Appointment'),
          content: TextField(
            controller: dateTimeController,
            decoration: const InputDecoration(
              labelText: 'Enter new date and time',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newDateTime = DateTime.parse(dateTimeController.text);
                dataProvider.updateAppointment(Appointment(
                  id: appointment.id,
                  patientId: appointment.patientId,
                  doctorId: appointment.doctorId,
                  dateTime: newDateTime,
                  status: 'Rescheduled',
                ));
                dataProvider.addAppointmentRescheduledNotification(
                  appointment.id,
                  appointment.patientId,
                  newDateTime,
                );
                Navigator.pop(context);
              },
              child: const Text('Reschedule'),
            ),
          ],
        );
      },
    );
  }
}
