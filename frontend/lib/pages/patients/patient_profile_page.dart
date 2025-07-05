import 'package:flutter/material.dart';
import '../../models/patient_data.dart';
import '../../models/hospital_data.dart';
import '../../models/doctor_data.dart';
import '../../providers/patient_provider.dart';
import '../../providers/hospital_provider.dart';
import '../../providers/doctor_provider.dart';

class PatientProfilePage extends StatefulWidget {
  final String token;
  final String patientId;

  const PatientProfilePage({
    Key? key,
    required this.token,
    required this.patientId,
  }) : super(key: key);

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final PatientProvider _patientProvider = PatientProvider();
  final HospitalProvider _hospitalProvider = HospitalProvider();
  final DoctorProvider _doctorProvider = DoctorProvider();

  late Future<PatientData> _patientData;
  Future<HospitalData>? _hospitalData;
  Future<List<DoctorData>>? _doctorsData;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  void _loadPatientData() {
    _patientData = _patientProvider
        .getPatients(token: widget.token, patientId: widget.patientId)
        .then((patients) {
      if (patients.isNotEmpty) {
        final patient = patients.first;
        setState(() {
          _hospitalData = _hospitalProvider
              .getHospitals(token: widget.token, hospitalId: patient.hospitalId)
              .then((hospitals) {
            if (hospitals.isNotEmpty) {
              return hospitals.first;
            } else {
              throw Exception('Hospital data not found');
            }
          });
          // Fetch all doctors assigned to the patient
          if (patient.doctorIds.isNotEmpty) {
            _doctorsData = Future.wait(
              patient.doctorIds.map((doctorId) => 
                _doctorProvider.getDoctorPublicData(
                  token: widget.token, 
                  doctorId: doctorId
                )
              ).toList()
            );
          } else {
            _doctorsData = Future.value(<DoctorData>[]);
          }
        });
        return patient;
      } else {
        throw Exception('Patient data not found');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Information Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<PatientData>(
                      future: _patientData,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (!snapshot.hasData) {
                          return const Text('No data available');
                        }

                        final patient = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Name', patient.name),
                            _buildInfoRow('Email', patient.email),
                            _buildInfoRow('Phone', patient.mobileNumber),
                            _buildInfoRow('Date of Birth',
                                patient.birthDate.toString().split(' ')[0]),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Assigned Hospital Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assigned Hospital',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<HospitalData>(
                      future: _hospitalData,
                      builder: (context, snapshot) {
                        if (_hospitalData == null) {
                          return const Text('No hospital assigned');
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (!snapshot.hasData) {
                          return const Text('No hospital assigned');
                        }
                        final hospital = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Name', hospital.name),
                            _buildInfoRow('Address', hospital.address),
                            if (hospital.mobileNumbers.isNotEmpty)
                              _buildInfoRow(
                                  'Phone', hospital.mobileNumbers.first),
                            if (hospital.emails.isNotEmpty)
                              _buildInfoRow('Email', hospital.emails.first),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Assigned Doctors Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assigned Doctors',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<DoctorData>>(
                      future: _doctorsData,
                      builder: (context, snapshot) {
                        if (_doctorsData == null) {
                          return const Text('No doctors assigned');
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('No doctors assigned');
                        }
                        final doctors = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: doctors.asMap().entries.map((entry) {
                            final index = entry.key;
                            final doctor = entry.value;
                            return Container(
                              margin: EdgeInsets.only(
                                bottom: index < doctors.length - 1 ? 16 : 0
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Doctor ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Name', doctor.name),
                                  _buildInfoRow('Specialization', doctor.description),
                                  _buildInfoRow('Email', doctor.email),
                                  _buildInfoRow('Phone', doctor.mobileNumber),
                                  if (doctor.licenses.isNotEmpty)
                                    _buildInfoRow(
                                        'Licenses', doctor.licenses.join(', ')),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
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
