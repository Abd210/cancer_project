import 'package:flutter/material.dart';
import '../../../models/patient_data.dart';
import '../../../providers/patient_provider.dart';

class PatientDetailsPage extends StatefulWidget {
  final PatientData patient;
  final String? token;

  const PatientDetailsPage({
    super.key,
    required this.patient,
    this.token,
  });

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  final PatientProvider _patientProvider = PatientProvider();
  late PatientData _patient;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
  }

  Future<void> _updateDiagnosis(String newDiagnosis) async {
    if (newDiagnosis == _patient.diagnosis) {
      return; // No change, no need to update
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedFields = {
        'diagnosis': newDiagnosis,
      };

      // Get the stored token
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Missing authentication token');
      }

      final updatedPatient = await _patientProvider.updatePatient(
        token: token,
        patientId: _patient.id,
        updatedFields: updatedFields,
      );

      if (mounted) {
        setState(() {
          _patient = updatedPatient;
          _isUpdating = false;
        });

        // Use ScaffoldMessenger instead of Fluttertoast for web compatibility
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diagnosis updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });

        // Use ScaffoldMessenger instead of Fluttertoast for web compatibility
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update diagnosis: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _getToken() async {
    if (widget.token != null && widget.token!.isNotEmpty) {
      return widget.token;
    }

    return null;
  }

  void _showEditDiagnosisDialog() {
    final TextEditingController diagnosisController =
        TextEditingController(text: _patient.diagnosis);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Diagnosis'),
        content: TextField(
          controller: diagnosisController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Diagnosis',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateDiagnosis(diagnosisController.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_patient.name} Details'),
        actions: [
          if (_patient.suspended)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red),
              ),
              child: const Text(
                'SUSPENDED',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isUpdating
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPatientHeader(),
                    const SizedBox(height: 24),
                    _buildInfoSection(),
                    if (_patient.medicalHistory.isNotEmpty)
                      _buildMedicalHistorySection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPatientHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              _patient.name.isNotEmpty ? _patient.name[0].toUpperCase() : "?",
              style: const TextStyle(fontSize: 40, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _patient.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Status: ${_patient.status}',
            style: TextStyle(
              fontSize: 16,
              color: _getStatusColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pers ID: ${_patient.persId}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Email', _patient.email),
            _buildInfoRow('Phone', _patient.mobileNumber),
            _buildInfoRow('Birth Date', _formatDate(_patient.birthDate)),
            _buildInfoRow('Hospital ID', _patient.hospitalId),
            _buildDiagnosisRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Diagnosis:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: _showEditDiagnosisDialog,
                tooltip: 'Edit Diagnosis',
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Text(
              _patient.diagnosis.isEmpty
                  ? 'No diagnosis available'
                  : _patient.diagnosis,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistorySection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Medical History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ..._patient.medicalHistory.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child:
                              Text(item, style: const TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
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
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_patient.status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'recovering':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      case 'inactive':
        return Colors.grey;
      case 'recovered':
        return Colors.blue;
      default:
        return Colors.black54;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
