import 'package:flutter/material.dart';
import '../../../providers/data_provider.dart';
import 'package:provider/provider.dart';
import '../../../models/patient.dart';

class DoctorPatientsPage extends StatelessWidget {
  final String doctorId;

  const DoctorPatientsPage({Key? key, required this.doctorId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final patients = dataProvider.getPatientsForDoctor(doctorId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Patients'),
      ),
      body: ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return Card(
            child: ListTile(
              title: Text(patient.name),
              subtitle: Text('Age: ${patient.age}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientDetailsPage(patient: patient),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class PatientDetailsPage extends StatelessWidget {
  final Patient patient;

  const PatientDetailsPage({Key? key, required this.patient}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${patient.name} Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${patient.name}', style: TextStyle(fontSize: 18)),
            Text('Age: ${patient.age}', style: TextStyle(fontSize: 18)),
            Text('Diagnosis: ${patient.diagnosis}', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}