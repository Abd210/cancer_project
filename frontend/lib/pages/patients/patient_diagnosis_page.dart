import 'package:flutter/material.dart';
import '../../models/patient_data.dart';

class PatientDiagnosisPage extends StatefulWidget {
  final String token;
  final String patientId;
  final PatientData patientData;

  const PatientDiagnosisPage({
    Key? key,
    required this.token,
    required this.patientId,
    required this.patientData,
  }) : super(key: key);

  @override
  State<PatientDiagnosisPage> createState() => _PatientDiagnosisPageState();
}

class _PatientDiagnosisPageState extends State<PatientDiagnosisPage> {
  @override
  Widget build(BuildContext context) {
    final diagnosis = widget.patientData.diagnosis;
    final medicalHistory = widget.patientData.medicalHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Diagnosis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Diagnosis Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diagnosis Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Diagnosis', diagnosis),
                    _buildInfoRow('Status', widget.patientData.status),
                    // Assuming date and notes might not be in PatientData directly, or are within diagnosis string
                    // For now, only display what's directly in PatientData
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Medical History Card
            if (medicalHistory.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medical History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...(medicalHistory).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text('• $item'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
