// lib/pages/superadmin/view_patients/view_patients_page.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:frontend/models/patient_data.dart';
import 'package:frontend/providers/patient_provider.dart';
import 'package:frontend/models/hospital_data.dart';
import 'package:frontend/models/doctor_data.dart';
import 'package:frontend/providers/hospital_provider.dart';
import 'package:frontend/providers/doctor_provider.dart';

import '../../../shared/components/loading_indicator.dart';
import '../../../shared/components/components.dart';
import '../../../shared/components/page_header.dart';
import '../../../shared/components/responsive_data_table.dart'
    show BetterPaginatedDataTable;

class PatientsPage extends StatefulWidget {
  final String token;
  final String hospitalId;
  const PatientsPage({
    Key? key, 
    required this.token,
    required this.hospitalId,
  }) : super(key: key);

  @override
  _PatientsPageState createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final PatientProvider _patientProvider = PatientProvider();
  final HospitalProvider _hospitalProvider = HospitalProvider();
  final DoctorProvider _doctorProvider = DoctorProvider();

  bool _isLoading = false;
  String _searchQuery = '';
  String _filter = 'unsuspended';

  List<PatientData> _patientList = [];
  List<HospitalData> _hospitalList = [];
  List<DoctorData> _doctorList = [];

  @override
  void initState() {
    super.initState();
    _fetchPatients();
    _fetchHospitals();
    _fetchDoctors();
  }

  Future<void> _fetchHospitals() async {
    try {
      final hospitals = await _hospitalProvider.getHospitals(
        token: widget.token,
        filter: 'all',
      );
      setState(() {
        _hospitalList = hospitals;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load hospitals: $e');
    }
  }

  Future<void> _fetchDoctors() async {
    try {
      final doctors = await _doctorProvider.getDoctors(
        token: widget.token,
        filter: 'all',
      );
      setState(() {
        _doctorList = doctors;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load doctors: $e');
    }
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      // If admin has no hospital assigned, don't fetch any patients
      if (widget.hospitalId.isEmpty) {
        setState(() => _patientList = []);
        return;
      }
      
      final patients = await _patientProvider.getPatients(
        token: widget.token,
        patientId: '',
        filter: _filter,
        hospitalId: widget.hospitalId, // Filter patients by admin's hospital
      );
      setState(() => _patientList = patients);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load patients: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddPatientDialog() {
    final formKey = GlobalKey<FormState>();

    // Check if doctors are loaded
    if (_doctorList.isEmpty) {
      Fluttertoast.showToast(msg: 'Please wait for doctors to load...');
      _fetchDoctors(); // Attempt to fetch doctors again
      return;
    }

    // Fields as expected by your API
    String persId = '';
    String name = '';
    String password = '';
    String mobileNumber = '';
    String email = '';
    String status = 'recovering';
    String diagnosis = '';
    DateTime birthDate = DateTime.now();
    String medicalHistoryRaw = '';
    List<String> selectedDoctorIds = [];

    // Doctor search - filter by admin's hospital
    TextEditingController doctorSearchController = TextEditingController();
    List<DoctorData> filteredDoctors = _doctorList.where((doctor) => doctor.hospitalId == widget.hospitalId).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person_add, color: const Color(0xFFEC407A)),
              const SizedBox(width: 10),
              const Text('Add New Patient',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Personal Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEC407A),
                              )),
                          const SizedBox(height: 16),

                          // Two-column layout for form fields
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column
                              Expanded(
                                child: Column(
                                  children: [
                                    TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Full Name',
                                        prefixIcon: Icon(Icons.person),
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (val) =>
                                          val == null || val.isEmpty
                                              ? 'Enter name'
                                              : null,
                                      onSaved: (val) => name = val!.trim(),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Email Address',
                                        prefixIcon: Icon(Icons.email),
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (val) =>
                                          val == null || val.isEmpty
                                              ? 'Enter email'
                                              : null,
                                      onSaved: (val) => email = val!.trim(),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Birth Date (YYYY-MM-DD)',
                                        prefixIcon: Icon(Icons.calendar_today),
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (val) =>
                                          val == null || val.isEmpty
                                              ? 'Enter birth date'
                                              : null,
                                      onSaved: (val) {
                                        if (val != null && val.isNotEmpty) {
                                          try {
                                            birthDate = DateTime.parse(val);
                                          } catch (e) {
                                            birthDate = DateTime.now();
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Right column
                              Expanded(
                                child: Column(
                                  children: [
                                    TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Personal ID',
                                        prefixIcon: Icon(Icons.badge),
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (val) =>
                                          val == null || val.isEmpty
                                              ? 'Enter persId'
                                              : null,
                                      onSaved: (val) => persId = val!.trim(),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Mobile Number',
                                        prefixIcon: Icon(Icons.phone),
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (val) =>
                                          val == null || val.isEmpty
                                              ? 'Enter mobile number'
                                              : null,
                                      onSaved: (val) =>
                                          mobileNumber = val!.trim(),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: Icon(Icons.lock),
                                        border: OutlineInputBorder(),
                                      ),
                                      obscureText: true,
                                      validator: (val) =>
                                          val == null || val.isEmpty
                                              ? 'Enter password'
                                              : null,
                                      onSaved: (val) => password = val!.trim(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Medical Information section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Medical Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEC407A),
                              )),
                          const SizedBox(height: 16),

                          // Status dropdown
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Patient Status',
                              prefixIcon: Icon(Icons.health_and_safety),
                              border: OutlineInputBorder(),
                            ),
                            value: status,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                  value: 'recovering',
                                  child: Text('Recovering')),
                              DropdownMenuItem(
                                  value: 'recovered', child: Text('Recovered')),
                              DropdownMenuItem(
                                  value: 'active', child: Text('Active')),
                              DropdownMenuItem(
                                  value: 'inactive', child: Text('Inactive')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                status = val;
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Diagnosis',
                              prefixIcon: Icon(Icons.medical_information),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            onSaved: (val) => diagnosis = val?.trim() ?? '',
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Medical History (comma-separated)',
                              prefixIcon: Icon(Icons.history),
                              border: OutlineInputBorder(),
                              hintText:
                                  'Enter previous conditions separated by commas',
                            ),
                            maxLines: 3,
                            onSaved: (val) =>
                                medicalHistoryRaw = val?.trim() ?? '',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Doctor Assignment section - automatically assigned to admin's hospital (Optional)
                    if (filteredDoctors.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Doctor Assignment',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFEC407A),
                                    )),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Optional',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You can assign doctors to this patient now or later.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Doctor search field
                            TextField(
                              controller: doctorSearchController,
                              decoration: InputDecoration(
                                labelText: 'Search Doctors',
                                prefixIcon: const Icon(Icons.search),
                                border: const OutlineInputBorder(),
                                suffixIcon:
                                    doctorSearchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              doctorSearchController.clear();
                                              setDialogState(() {
                                                filteredDoctors = _doctorList
                                                    .where((doctor) =>
                                                        doctor.hospitalId ==
                                                        widget.hospitalId)
                                                    .toList();
                                              });
                                            },
                                          )
                                        : null,
                              ),
                              onChanged: (query) {
                                setDialogState(() {
                                  if (query.isEmpty) {
                                    filteredDoctors = _doctorList
                                        .where((doctor) =>
                                            doctor.hospitalId ==
                                            widget.hospitalId)
                                        .toList();
                                  } else {
                                    filteredDoctors = _doctorList
                                        .where((doctor) =>
                                            doctor.hospitalId ==
                                                widget.hospitalId &&
                                            (doctor.name.toLowerCase().contains(
                                                    query.toLowerCase()) ||
                                                doctor.email
                                                    .toLowerCase()
                                                    .contains(
                                                        query.toLowerCase()) ||
                                                doctor.persId
                                                    .toLowerCase()
                                                    .contains(
                                                        query.toLowerCase())))
                                        .toList();
                                  }
                                });
                              },
                            ),

                            const SizedBox(height: 16),

                            // Multiple Doctor Selection
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person, color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Select Doctors (Optional)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (selectedDoctorIds.isNotEmpty)
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: selectedDoctorIds.map((doctorId) {
                                        final doctor = filteredDoctors.firstWhere(
                                          (d) => d.id == doctorId,
                                                                                     orElse: () => DoctorData(
                                             id: doctorId,
                                             persId: 'Unknown',
                                             name: 'Unknown Doctor',
                                             email: '',
                                             mobileNumber: '',
                                             birthDate: DateTime.now(),
                                             hospitalId: '',
                                             licenses: [],
                                             description: '',
                                             suspended: false,
                                             patients: [],
                                             schedule: [],
                                           ),
                                        );
                                        return Chip(
                                          label: Text(
                                            doctor.name,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          deleteIcon: const Icon(Icons.close, size: 16),
                                          onDeleted: () {
                                            setDialogState(() {
                                              selectedDoctorIds.remove(doctorId);
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                                                             _showDoctorSelectionDialog(
                                         context,
                                         filteredDoctors,
                                         selectedDoctorIds,
                                         (updatedDoctorIds) {
                                           setDialogState(() {
                                             selectedDoctorIds = updatedDoctorIds;
                                           });
                                         },
                                       );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Select Doctors'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEC407A),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (filteredDoctors.isEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Doctor Assignment',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFEC407A),
                                    )),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Optional',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Center(
                              child: Text(
                                'No doctors available for your hospital. You can still create the patient and assign doctors later.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Save Patient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC407A),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  // Doctor assignment is optional - no validation needed

                  Navigator.pop(ctx);

                  final medicalHistory = medicalHistoryRaw
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();

                  setState(() => _isLoading = true);
                  try {
                    await _patientProvider.createPatient(
                      token: widget.token,
                      persId: persId,
                      name: name,
                      password: password,
                      mobileNumber: mobileNumber,
                      email: email,
                      status: status,
                      diagnosis: diagnosis,
                      birthDate: birthDate.toIso8601String().split('T')[0],
                      medicalHistory: medicalHistory,
                      hospitalId: widget.hospitalId,
                      doctorIds: selectedDoctorIds,
                      suspended: false,
                    );
                    await _fetchPatients();

                    Fluttertoast.showToast(msg: 'Patient added successfully.');
                  } catch (e) {
                    Fluttertoast.showToast(msg: 'Failed to add patient: $e');
                  } finally {
                    setState(() => _isLoading = false);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPatientDialog(PatientData patient) {
    final formKey = GlobalKey<FormState>();

    // Store original values to track changes
    final String originalPersId = patient.persId;
    final String originalName = patient.name;
    final String originalPassword = patient.password;
    final String originalMobileNumber = patient.mobileNumber;
    final String originalEmail = patient.email;
    final String originalStatus = patient.status;
    final String originalDiagnosis = patient.diagnosis;
    final DateTime originalBirthDate = patient.birthDate;
    final List<String> originalMedHistory = List.from(patient.medicalHistory);
    final String originalHospitalId = patient.hospitalId;
    final List<String> originalDoctorIds = List.from(patient.doctorIds);

    // Editable values
    String persId = originalPersId;
    String name = originalName;
    String password = originalPassword;
    String mobileNumber = originalMobileNumber;
    String email = originalEmail;
    String status = originalStatus;
    String diagnosis = originalDiagnosis;
    DateTime birthDate = originalBirthDate;
    List<String> medHistory = List.from(originalMedHistory);
    String hospitalId = originalHospitalId;
    List<String> doctorIds = List.from(originalDoctorIds);

    // Get the hospital name for display
    String hospitalName = 'Unknown Hospital';
    for (var hospital in _hospitalList) {
      if (hospital.id == hospitalId) {
        hospitalName = '${hospital.name} (${hospital.address})';
        break;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: const Color(0xFFEC407A)),
              const SizedBox(width: 10),
              Text('Edit Patient: ${patient.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Personal Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEC407A),
                              )),
                          const SizedBox(height: 16),

                          // Two-column layout for form fields
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column
                              Expanded(
                                child: Column(
                                  children: [
                                    TextFormField(
                                      initialValue: name,
                                      decoration: const InputDecoration(
                                        labelText: 'Full Name',
                                        prefixIcon: Icon(Icons.person),
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (val) =>
                                          val == null || val.isEmpty
                                              ? 'Enter name'
                                              : null,
                                      onSaved: (val) => name = val!.trim(),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: email,
                                      decoration: InputDecoration(
                                        labelText: 'Email Address',
                                        prefixIcon: const Icon(Icons.email),
                                        border: const OutlineInputBorder(),
                                        helperText:
                                            'This is your login identifier',
                                        helperStyle: TextStyle(
                                            color: Colors.grey.shade600),
                                      ),
                                      enabled:
                                          false, // Disable email editing to prevent uniqueness errors
                                      validator: (val) =>
                                          val == null || val.isEmpty
                                              ? 'Enter email'
                                              : null,
                                      onSaved: (val) => email = val!.trim(),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: birthDate
                                          .toIso8601String()
                                          .split('T')[0],
                                      decoration: const InputDecoration(
                                        labelText: 'Birth Date (YYYY-MM-DD)',
                                        prefixIcon: Icon(Icons.calendar_today),
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (val) =>
                                          val == null || val.isEmpty
                                              ? 'Enter birth date'
                                              : null,
                                      onSaved: (val) {
                                        if (val != null && val.isNotEmpty) {
                                          try {
                                            birthDate = DateTime.parse(val);
                                          } catch (e) {
                                            birthDate = originalBirthDate;
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Right column
                              Expanded(
                                child: Column(
                                  children: [
                                    TextFormField(
                                      initialValue: persId,
                                      decoration: const InputDecoration(
                                        labelText: 'Personal ID',
                                        prefixIcon: Icon(Icons.badge),
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (val) =>
                                          val == null || val.isEmpty
                                              ? 'Enter persId'
                                              : null,
                                      onSaved: (val) => persId = val!.trim(),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: mobileNumber,
                                      decoration: const InputDecoration(
                                        labelText: 'Mobile Number',
                                        prefixIcon: Icon(Icons.phone),
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (val) =>
                                          val == null || val.isEmpty
                                              ? 'Enter mobile number'
                                              : null,
                                      onSaved: (val) =>
                                          mobileNumber = val!.trim(),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: password,
                                      decoration: const InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: Icon(Icons.lock),
                                        border: OutlineInputBorder(),
                                        hintText:
                                            'Leave empty to keep current password',
                                      ),
                                      obscureText: true,
                                      validator:
                                          null, // Allow empty password during update
                                      onSaved: (val) =>
                                          password = val?.trim() ?? '',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Medical Information section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Medical Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEC407A),
                              )),
                          const SizedBox(height: 16),

                          // Status dropdown
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Patient Status',
                              prefixIcon: Icon(Icons.health_and_safety),
                              border: OutlineInputBorder(),
                            ),
                            value: status,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                  value: 'recovering',
                                  child: Text('Recovering')),
                              DropdownMenuItem(
                                  value: 'recovered', child: Text('Recovered')),
                              DropdownMenuItem(
                                  value: 'active', child: Text('Active')),
                              DropdownMenuItem(
                                  value: 'inactive', child: Text('Inactive')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                status = val;
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            initialValue: diagnosis,
                            decoration: const InputDecoration(
                              labelText: 'Diagnosis',
                              prefixIcon: Icon(Icons.medical_information),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            onSaved: (val) => diagnosis = val?.trim() ?? '',
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            initialValue: medHistory.join(', '),
                            decoration: const InputDecoration(
                              labelText: 'Medical History (comma-separated)',
                              prefixIcon: Icon(Icons.history),
                              border: OutlineInputBorder(),
                              hintText:
                                  'Enter previous conditions separated by commas',
                            ),
                            maxLines: 3,
                            onSaved: (val) {
                              final raw = val ?? '';
                              medHistory = raw
                                  .split(',')
                                  .map((s) => s.trim())
                                  .where((s) => s.isNotEmpty)
                                  .toList();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Hospital Assignment section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hospital Assignment',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEC407A),
                              )),
                          const SizedBox(height: 16),

                          // Hospital display (not editable in this form)
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Assigned Hospital',
                              prefixIcon: Icon(Icons.local_hospital),
                              border: OutlineInputBorder(),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      hospitalName,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Tooltip(
                                    message:
                                        'To change hospital, please create a new patient account',
                                    child: Icon(Icons.info_outline,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Doctor Assignment section for editing
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Doctor Assignment',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEC407A),
                              )),
                          const SizedBox(height: 16),

                          // Display current doctors
                          if (doctorIds.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: doctorIds.map((doctorId) {
                                final doctor = _doctorList.firstWhere(
                                  (d) => d.id == doctorId,
                                  orElse: () => DoctorData(
                                    id: doctorId,
                                    persId: 'Unknown',
                                    name: 'Unknown Doctor',
                                    email: '',
                                    mobileNumber: '',
                                    birthDate: DateTime.now(),
                                    hospitalId: '',
                                    licenses: [],
                                    description: '',
                                    suspended: false,
                                    patients: [],
                                    schedule: [],
                                  ),
                                );
                                return Chip(
                                  label: Text(
                                    doctor.name,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () {
                                    setDialogState(() {
                                      doctorIds.remove(doctorId);
                                    });
                                  },
                                );
                              }).toList(),
                            )
                          else
                            const Text(
                              'No doctors assigned',
                              style: TextStyle(color: Colors.grey),
                            ),
                          const SizedBox(height: 8),

                          ElevatedButton.icon(
                            onPressed: () {
                              final availableDoctors = _doctorList.where((doctor) => doctor.hospitalId == widget.hospitalId).toList();
                              _showDoctorSelectionDialog(
                                dialogContext,
                                availableDoctors,
                                doctorIds,
                                (updatedDoctorIds) {
                                  setDialogState(() {
                                    doctorIds = updatedDoctorIds;
                                  });
                                },
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Doctors'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEC407A),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC407A),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.pop(ctx);

                  setState(() => _isLoading = true);
                  try {
                    // Only include fields that have actually changed
                    final Map<String, dynamic> updatedFields = {};

                    if (name != originalName) updatedFields["name"] = name;
                    if (persId != originalPersId)
                      updatedFields["persId"] = persId;
                    if (password.isNotEmpty && password != originalPassword)
                      updatedFields["password"] = password;
                    if (mobileNumber != originalMobileNumber)
                      updatedFields["mobileNumber"] = mobileNumber;

                    // Format birthDate for comparison
                    String birthDateStr =
                        birthDate.toIso8601String().split('T')[0];
                    String originalBirthDateStr =
                        originalBirthDate.toIso8601String().split('T')[0];
                    if (birthDateStr != originalBirthDateStr)
                      updatedFields["birthDate"] = birthDateStr;

                    if (status != originalStatus)
                      updatedFields["status"] = status;
                    if (diagnosis != originalDiagnosis)
                      updatedFields["diagnosis"] = diagnosis;

                    // Check if medHistory has changed
                    bool medHistoryChanged =
                        medHistory.length != originalMedHistory.length;
                    if (!medHistoryChanged) {
                      for (int i = 0; i < medHistory.length; i++) {
                        if (i >= originalMedHistory.length ||
                            medHistory[i] != originalMedHistory[i]) {
                          medHistoryChanged = true;
                          break;
                        }
                      }
                    }
                    if (medHistoryChanged)
                      updatedFields["medicalHistory"] = medHistory;

                    // Check if doctors have changed
                    bool doctorsChanged = doctorIds.length != originalDoctorIds.length;
                    if (!doctorsChanged) {
                      for (int i = 0; i < doctorIds.length; i++) {
                        if (i >= originalDoctorIds.length ||
                            doctorIds[i] != originalDoctorIds[i]) {
                          doctorsChanged = true;
                          break;
                        }
                      }
                    }
                    if (doctorsChanged)
                      updatedFields["doctors"] = doctorIds;

                    // Only make the API call if there are changes
                    if (updatedFields.isNotEmpty) {
                      await _patientProvider.updatePatient(
                        token: widget.token,
                        patientId: patient.id,
                        updatedFields: updatedFields,
                      );
                      await _fetchPatients();
                      Fluttertoast.showToast(
                          msg: 'Patient updated successfully');
                    } else {
                      Fluttertoast.showToast(msg: 'No changes detected');
                    }
                  } catch (e) {
                    // Try to refresh the list even if there was an error
                    try {
                      await _fetchPatients();
                    } catch (_) {
                      // Ignore any error from the refresh attempt
                    }
                    Fluttertoast.showToast(msg: 'Failed to update patient: $e');
                  } finally {
                    setState(() => _isLoading = false);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deletePatient(String patientId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Patient'),
        content: const Text('Are you sure you want to delete this patient?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _patientProvider.deletePatient(
                  token: widget.token,
                  patientId: patientId,
                );
                await _fetchPatients();
                Fluttertoast.showToast(msg: 'Patient deleted successfully.');
              } catch (e) {
                Fluttertoast.showToast(msg: 'Failed to delete patient: $e');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  void _showDoctorSelectionDialog(
    BuildContext context,
    List<DoctorData> availableDoctors,
    List<String> currentlySelectedIds,
    Function(List<String>) onSelectionChanged,
  ) {
    List<String> tempSelectedIds = List.from(currentlySelectedIds);
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.people, color: const Color(0xFFEC407A)),
              const SizedBox(width: 10),
              const Text('Select Doctors'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: availableDoctors.isEmpty
                ? const Center(
                    child: Text('No doctors available in this hospital'),
                  )
                : ListView.builder(
                    itemCount: availableDoctors.length,
                    itemBuilder: (context, index) {
                      final doctor = availableDoctors[index];
                      final isSelected = tempSelectedIds.contains(doctor.id);
                      
                      return CheckboxListTile(
                        title: Text(doctor.name),
                        subtitle: Text('${doctor.persId} - ${doctor.email}'),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              if (!tempSelectedIds.contains(doctor.id)) {
                                tempSelectedIds.add(doctor.id);
                              }
                            } else {
                              tempSelectedIds.remove(doctor.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onSelectionChanged(tempSelectedIds);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC407A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator();
    }

    final filteredPatients = _patientList.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.diagnosis.toLowerCase().contains(q) ||
          p.email.toLowerCase().contains(q) ||
          p.persId.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const PageHeader(icon: Icons.group, title: 'Patients Management'),
            SizedBox(height: 24),
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: DropdownButton<String>(
                    value: _filter,
                    underline: const SizedBox(),
                    onChanged: widget.hospitalId.isEmpty ? null : (val) async {
                      if (val != null) {
                        setState(() => _filter = val);
                        await _fetchPatients();
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'unsuspended',
                        child: Text('Unsuspended'),
                      ),
                      DropdownMenuItem(
                        value: 'suspended',
                        child: Text('Suspended'),
                      ),
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TextField(
                    enabled: widget.hospitalId.isNotEmpty,
                    decoration: InputDecoration(
                      labelText: 'Search Patients',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: widget.hospitalId.isEmpty ? null : _showAddPatientDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Patient'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: widget.hospitalId.isEmpty ? null : _fetchPatients,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: widget.hospitalId.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_hospital_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Hospital Assigned',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You cannot view patients because you are not assigned to any hospital.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Please contact your system administrator to assign you to a hospital.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : filteredPatients.isEmpty
                      ? const Center(child: Text('No patients found.'))
                      : BetterPaginatedDataTable(
                      themeColor: const Color(0xFFEC407A), // Pinkish color
                      rowsPerPage: 10, // Show 10 rows per page
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Pers ID')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Diagnosis')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Suspended')),
                        DataColumn(label: Text('Doctors')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: filteredPatients.map((patient) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                constraints: const BoxConstraints(
                                  minWidth: 150,
                                  maxWidth: 200,
                                ),
                                child: Text(
                                  patient.name,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.3,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                constraints: const BoxConstraints(
                                  minWidth: 120,
                                  maxWidth: 150,
                                ),
                                child: Text(
                                  patient.persId,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                constraints: const BoxConstraints(
                                  minWidth: 180,
                                  maxWidth: 250,
                                ),
                                child: Text(
                                  patient.email,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                constraints: const BoxConstraints(
                                  minWidth: 250,
                                  maxWidth: 350,
                                ),
                                child: Text(
                                  patient.diagnosis,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                constraints: const BoxConstraints(
                                  minWidth: 120,
                                  maxWidth: 150,
                                ),
                                child: Text(
                                  patient.status,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                constraints: const BoxConstraints(
                                  minWidth: 80,
                                  maxWidth: 100,
                                ),
                                child: Text(
                                  patient.suspended ? 'Yes' : 'No',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.3,
                                    color: patient.suspended ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                constraints: const BoxConstraints(
                                  minWidth: 120,
                                  maxWidth: 180,
                                ),
                                child: patient.doctorIds.isEmpty
                                    ? const Text(
                                        'No doctors assigned',
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.3,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : Tooltip(
                                        message: patient.doctorIds.map((id) {
                                          final doctor = _doctorList.firstWhere(
                                            (d) => d.id == id,
                                            orElse: () => DoctorData(
                                              id: id,
                                              persId: 'Unknown',
                                              name: 'Unknown Doctor',
                                              email: '',
                                              mobileNumber: '',
                                              birthDate: DateTime.now(),
                                              hospitalId: '',
                                              licenses: [],
                                              description: '',
                                              suspended: false,
                                              patients: [],
                                              schedule: [],
                                            ),
                                          );
                                          return doctor.name;
                                        }).join(', '),
                                        child: Text(
                                          '${patient.doctorIds.length} doctor${patient.doctorIds.length == 1 ? '' : 's'}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.3,
                                            decoration: TextDecoration.underline,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        _showEditPatientDialog(patient),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deletePatient(patient.id),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}