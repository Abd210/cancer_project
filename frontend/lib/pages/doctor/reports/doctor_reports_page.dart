import 'package:flutter/material.dart';
import '../../../providers/data_provider.dart';
import 'package:provider/provider.dart';
import '../../../models/patient.dart';
class DoctorReportsPage extends StatelessWidget {
  final String doctorId;

  const DoctorReportsPage({Key? key, required this.doctorId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final patients = dataProvider.getPatientsForDoctor(doctorId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
      ),
      body: ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return Card(
            child: ListTile(
              title: Text(patient.name),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientReportsPage(patient: patient),
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

class PatientReportsPage extends StatefulWidget {
  final Patient patient;

  const PatientReportsPage({Key? key, required this.patient}) : super(key: key);

  @override
  _PatientReportsPageState createState() => _PatientReportsPageState();
}

class _PatientReportsPageState extends State<PatientReportsPage> {
  final TextEditingController _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patient.name} Reports'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Text('Reports for ${widget.patient.name}'),
                  // Add report details here
                ],
              ),
            ),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: 'Add Notes'),
            ),
            ElevatedButton(
              onPressed: () {
                // Save the notes logic here
              },
              child: Text('Save Notes'),
            ),
          ],
        ),
      ),
    );
  }
}
