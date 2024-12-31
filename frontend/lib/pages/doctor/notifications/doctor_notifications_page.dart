import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/data_provider.dart';
import '../../../models/appointment.dart';
class DoctorNotificationsPage extends StatelessWidget {
  final String doctorId;

  const DoctorNotificationsPage({Key? key, required this.doctorId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: dataProvider.notifications.length,
        itemBuilder: (context, index) {
          final notification = dataProvider.notifications[index];

          return Card(
            child: ListTile(
              title: Text(notification.message),
              subtitle: Text(notification.timestamp.toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Approve button
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                        final appointment = Appointment(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          patientId: 'placeholder_patient_id', // Replace with actual patient ID
                          doctorId: doctorId,
                          dateTime: DateTime.now(), // Replace with actual appointment time
                          status: 'Approved',
                        );
                        dataProvider.approveAppointmentRequest(notification.id, appointment);
                      },

                  ),
                  // Reject button
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      dataProvider.rejectAppointmentRequest(notification.id);
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
}
