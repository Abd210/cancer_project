// lib/pages/superadmin/view_appointments/view_appointments_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:frontend/providers/appointment_provider.dart';
import 'package:frontend/models/appointment_data.dart';
import 'package:frontend/providers/doctor_provider.dart';
import 'package:frontend/providers/patient_provider.dart';
import 'package:frontend/providers/hospital_provider.dart';
import 'package:frontend/models/doctor_data.dart';
import 'package:frontend/models/patient_data.dart';
import 'package:frontend/models/hospital_data.dart';

import '../../../shared/components/loading_indicator.dart';
import '../../../shared/components/page_header.dart';
import '../../../shared/components/responsive_data_table.dart'
    show BetterPaginatedDataTable;

class AppointmentsPage extends StatefulWidget {
  final String token;
  const AppointmentsPage({Key? key, required this.token}) : super(key: key);

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final AppointmentProvider _appointmentProvider = AppointmentProvider();
  final DoctorProvider _doctorProvider = DoctorProvider();
  final PatientProvider _patientProvider = PatientProvider();
  final HospitalProvider _hospitalProvider = HospitalProvider();

  bool _isLoading = false;
  String _searchQuery = '';
  bool _showFilters = false;

  // For GET filtering
  String _suspendFilter = 'all'; // Changed from 'unsuspended' to 'all' to show all appointments, including suspended ones
  String _filterByRole = ''; // Default to empty to get all initially
  String _filterById = '';

  // Data lists
  List<AppointmentData> _appointmentList = [];
  List<DoctorData> _doctorList = [];
  List<PatientData> _patientList = [];
  List<HospitalData> _hospitalList = [];
  
  // Filter selection
  String? _selectedHospitalId;
  String? _selectedDoctorId;
  String? _selectedPatientId;
  String _selectedDateRange = 'all'; // all, today, week, month
  String _selectedStatus = 'all'; // all, scheduled, completed, cancelled - ensures we show all statuses by default
  DateTime? _fromDate;
  DateTime? _toDate;

  late ScaffoldMessengerState _scaffoldMessenger;

  void _showToast(String message) {
    _scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
    _fetchDoctors();
    _fetchPatients();
    _fetchHospitals();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      // Apply role and ID filters if a doctor or patient is selected
      if (_selectedDoctorId != null && _selectedDoctorId!.isNotEmpty) {
        _filterByRole = 'doctor';
        _filterById = _selectedDoctorId!;
      } else if (_selectedPatientId != null && _selectedPatientId!.isNotEmpty) {
        _filterByRole = 'patient';
        _filterById = _selectedPatientId!;
      } else {
        _filterByRole = '';
        _filterById = '';
      }
      
      List<AppointmentData> pastList = [];
      List<AppointmentData> upcomingList = [];
      
      // OPTIMIZED: Use hospital arrays when a specific hospital is selected
      if (_selectedHospitalId != null && _selectedHospitalId!.isNotEmpty) {
        // Use the new direct method that queries appointments by hospital arrays
        pastList = await _appointmentProvider.getDirectHospitalAppointments(
          token: widget.token,
          hospitalId: _selectedHospitalId!,
          patientId: _selectedPatientId,
          doctorId: _selectedDoctorId,
          timeDirection: 'past',
          suspendfilter: _suspendFilter,
        );
        
        upcomingList = await _appointmentProvider.getDirectHospitalAppointments(
          token: widget.token,
          hospitalId: _selectedHospitalId!,
          patientId: _selectedPatientId,
          doctorId: _selectedDoctorId,
          timeDirection: 'upcoming',
          suspendfilter: _suspendFilter,
        );
      } else {
        // Fall back to original methods when viewing all hospitals
        // Get past appointments (history)
        pastList = await _appointmentProvider.getAppointmentsHistory(
          token: widget.token,
          suspendfilter: _suspendFilter,
          filterByRole: _filterByRole.isEmpty ? null : _filterByRole, 
          filterById: _filterById.isEmpty ? null : _filterById,       
        );
        
        // Get future appointments (upcoming)
        if (_filterByRole.isNotEmpty && _filterById.isNotEmpty) {
          // Get entity-specific upcoming appointments
          upcomingList = await _appointmentProvider.getUpcoming(
            token: widget.token,
            entityRole: _filterByRole,
            entityId: _filterById,
            suspendfilter: _suspendFilter,
          );
        } else {
          // Get all upcoming appointments
          upcomingList = await _appointmentProvider.getUpcomingAll(
            token: widget.token,
            suspendfilter: _suspendFilter,
          );
        }
      }
      
      // Combine both lists
      final list = [...pastList, ...upcomingList];
      
      // Debug check for appointment statuses
      print('DEBUG: Total appointments: ${list.length}');
      print('DEBUG: Appointment statuses: ${list.map((a) => a.status).toSet().toList()}');
      print('DEBUG: Cancelled appointments: ${list.where((a) => a.status == 'cancelled').length}');
      
      // Apply client-side filtering
      var filteredList = list;
      
      // Filter by date range if selected
      if (_fromDate != null && _toDate != null) {
        filteredList = filteredList.where((appointment) {
          return appointment.start.isAfter(_fromDate!) && 
                 appointment.start.isBefore(_toDate!.add(const Duration(days: 1)));
        }).toList();
      } else if (_selectedDateRange != 'all') {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        switch (_selectedDateRange) {
          case 'today':
            final tomorrow = today.add(const Duration(days: 1));
            filteredList = filteredList.where((appointment) {
              return appointment.start.isAfter(today) && 
                     appointment.start.isBefore(tomorrow);
            }).toList();
            break;
          case 'week':
            final weekLater = today.add(const Duration(days: 7));
            filteredList = filteredList.where((appointment) {
              return appointment.start.isAfter(today) && 
                     appointment.start.isBefore(weekLater);
            }).toList();
            break;
          case 'month':
            final monthLater = DateTime(today.year, today.month + 1, today.day);
            filteredList = filteredList.where((appointment) {
              return appointment.start.isAfter(today) && 
                     appointment.start.isBefore(monthLater);
            }).toList();
            break;
        }
      }
      
      // Filter by status if selected
      if (_selectedStatus != 'all') {
        filteredList = filteredList.where((appointment) {
          return appointment.status == _selectedStatus;
        }).toList();
      }
      
      // Hospital filtering is now handled server-side when using getDirectHospitalAppointments
      // Only apply client-side hospital filtering when using the fallback methods
      if (_selectedHospitalId != null && _selectedHospitalId!.isNotEmpty && 
          (_filterByRole.isNotEmpty || _filterById.isNotEmpty)) {
        // This case handles when we used the fallback methods but still have a hospital filter
        // First, find doctors belonging to this hospital
        final hospitalDoctorIds = _doctorList
            .where((doctor) => doctor.hospitalId == _selectedHospitalId)
            .map((doctor) => doctor.id)
            .toList();
        
        // Then filter appointments by those doctors
        filteredList = filteredList.where((appointment) {
          return hospitalDoctorIds.contains(appointment.doctorId);
        }).toList();
      }
      
      setState(() {
        _appointmentList = filteredList;
      });
    } catch (e) {
      print('Error fetching appointments: $e');
      if (mounted) {
        _showToast('Failed to load appointments: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDoctors() async {
    try {
      // Fetch all doctors
      final allDoctors = await _doctorProvider.getDoctors(
        token: widget.token,
        filter: 'all',
      );
      
      // OPTIMIZED: Filter by hospital when a specific hospital is selected
      if (_selectedHospitalId != null && _selectedHospitalId!.isNotEmpty) {
        // Filter doctors to only include those from the selected hospital
        final hospitalDoctors = allDoctors.where((doctor) => doctor.hospitalId == _selectedHospitalId).toList();
        setState(() {
          _doctorList = hospitalDoctors;
        });
      } else {
        // Show all doctors when no hospital filter is applied
        setState(() {
          _doctorList = allDoctors;
        });
      }
    } catch (e) {
      print('Error fetching doctors: $e');
    }
  }
  
  Future<void> _fetchPatients() async {
    try {
      // Fetch all patients
      final allPatients = await _patientProvider.getPatients(
        token: widget.token,
        filter: 'all',
      );
      
      // OPTIMIZED: Filter by hospital when a specific hospital is selected
      if (_selectedHospitalId != null && _selectedHospitalId!.isNotEmpty) {
        // Filter patients to only include those from the selected hospital
        final hospitalPatients = allPatients.where((patient) => patient.hospitalId == _selectedHospitalId).toList();
        setState(() {
          _patientList = hospitalPatients;
        });
      } else {
        // Show all patients when no hospital filter is applied
        setState(() {
          _patientList = allPatients;
        });
      }
    } catch (e) {
      print('Error fetching patients: $e');
    }
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
      print('Error fetching hospitals: $e');
    }
  }

  void _showAddAppointmentDialog() {
    final formKey = GlobalKey<FormState>();
    
    // Form state variables
    String? selectedHospitalId;
    String? selectedDoctorId;
    String? selectedPatientId;
    DateTime selectedStartDate = DateTime.now();
    TimeOfDay selectedStartTime = TimeOfDay.now();
    DateTime selectedEndDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedEndTime = TimeOfDay.fromDateTime(selectedEndDate);
    String purpose = '';
    String status = 'scheduled';
    bool suspended = false;
    
    // Filter lists
    List<DoctorData> filteredDoctors = [];
    List<PatientData> filteredPatients = [];
    
    // Controllers for search fields
    TextEditingController doctorSearchController = TextEditingController();
    TextEditingController patientSearchController = TextEditingController();

    // Helper function to get available patients for a selected doctor
    List<PatientData> _getAvailablePatientsForDoctor(String doctorId) {
      final doctor = _doctorList.firstWhere((d) => d.id == doctorId, orElse: () => DoctorData(
        id: '', persId: '', name: '', email: '', mobileNumber: '', birthDate: DateTime.now(),
        licenses: [], description: '', hospitalId: '', patients: [], schedule: [], suspended: false,
      ));
      
      return _patientList.where((patient) => 
        patient.hospitalId == selectedHospitalId && doctor.patients.contains(patient.id)
      ).toList();
    }

    // Helper function to get available doctors for a selected patient
    List<DoctorData> _getAvailableDoctorsForPatient(String patientId) {
      final patient = _patientList.firstWhere((p) => p.id == patientId, orElse: () => PatientData(
        id: '', persId: '', name: '', email: '', mobileNumber: '', birthDate: DateTime.now(),
        hospitalId: '', doctorIds: [], status: '', diagnosis: '', medicalHistory: [], suspended: false,
      ));
      
      return _doctorList.where((doctor) => 
        doctor.hospitalId == selectedHospitalId && patient.doctorIds.contains(doctor.id)
      ).toList();
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.calendar_month, color: const Color(0xFFEC407A)),
                const SizedBox(width: 10),
                const Text('Schedule New Appointment', 
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
                      // Hospital and Doctor Selection section
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
                            Row(
                              children: [
                                Text('Doctor Assignment', 
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFEC407A),
                                  )
                                ),
                                if (selectedHospitalId != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.shade300),
                                    ),
                                    child: Text(
                                      'Hospital Selected',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Hospital dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Select Hospital',
                                prefixIcon: Icon(Icons.local_hospital),
                                border: OutlineInputBorder(),
                              ),
                              value: selectedHospitalId,
                              hint: const Text('Choose a hospital'),
                              isExpanded: true,
                              items: _hospitalList.map((hospital) {
                                return DropdownMenuItem<String>(
                                  value: hospital.id,
                                  child: Text(hospital.name),
                                );
                              }).toList(),
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Select a hospital' : null,
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedHospitalId = value;
                                  selectedDoctorId = null;
                                  selectedPatientId = null;
                                  patientSearchController.clear();
                                  doctorSearchController.clear();
                                  if (value != null) {
                                    filteredDoctors = _doctorList
                                        .where((doctor) => doctor.hospitalId == value)
                                        .toList();
                                    filteredPatients = _patientList
                                        .where((patient) => patient.hospitalId == value)
                                        .toList();
                                  } else {
                                    filteredDoctors = [];
                                    filteredPatients = [];
                                  }
                                });
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Doctor search field
                            if (selectedHospitalId != null) ...[
                              TextField(
                                controller: doctorSearchController,
                                decoration: InputDecoration(
                                  labelText: 'Search Doctors',
                                  prefixIcon: const Icon(Icons.search),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: doctorSearchController.text.isNotEmpty 
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          doctorSearchController.clear();
                                          setDialogState(() {
                                            // If patient is selected, show only doctors associated with that patient
                                            if (selectedPatientId != null && selectedPatientId!.isNotEmpty) {
                                              filteredDoctors = _getAvailableDoctorsForPatient(selectedPatientId!);
                                            } else {
                                              filteredDoctors = _doctorList
                                                .where((doctor) => doctor.hospitalId == selectedHospitalId)
                                                .toList();
                                            }
                                          });
                                        },
                                      )
                          : null,
                                ),
                                onChanged: (query) {
                                  setDialogState(() {
                                    List<DoctorData> baseList;
                                    // If patient is selected, filter from doctors associated with that patient
                                    if (selectedPatientId != null && selectedPatientId!.isNotEmpty) {
                                      baseList = _getAvailableDoctorsForPatient(selectedPatientId!);
                                    } else {
                                      baseList = _doctorList
                                        .where((doctor) => doctor.hospitalId == selectedHospitalId)
                                        .toList();
                                    }
                                    
                                    if (query.isEmpty) {
                                      filteredDoctors = baseList;
                                    } else {
                                      filteredDoctors = baseList
                                        .where((doctor) => 
                                          doctor.name.toLowerCase().contains(query.toLowerCase()) ||
                                          doctor.email.toLowerCase().contains(query.toLowerCase()) ||
                                          doctor.persId.toLowerCase().contains(query.toLowerCase()))
                                        .toList();
                                    }
                                  });
                                },
                              ),
                            ] else ...[
                              // Show message when no hospital is selected
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Please select a hospital first to see available doctors',
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            if (selectedHospitalId != null) const SizedBox(height: 16),
                            
                            // Doctor dropdown
                            if (selectedHospitalId != null)
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Select Doctor',
                                  prefixIcon: const Icon(Icons.person),
                                  border: const OutlineInputBorder(),
                                  helperText: selectedPatientId != null && selectedPatientId!.isNotEmpty
                                    ? 'Showing doctors associated with selected patient'
                                    : 'Select a patient first to see associated doctors',
                                  helperStyle: TextStyle(
                                    color: selectedPatientId != null && selectedPatientId!.isNotEmpty
                                      ? Colors.green.shade600
                                      : Colors.orange.shade600,
                                    fontSize: 11,
                                  ),
                                  suffixIcon: selectedDoctorId != null && selectedDoctorId!.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.red),
                                        onPressed: () {
                                          setDialogState(() {
                                            selectedDoctorId = null;
                                            doctorSearchController.clear();
                                            // Reset patient filtering to show all hospital patients
                                            filteredPatients = _patientList
                                              .where((patient) => patient.hospitalId == selectedHospitalId)
                                              .toList();
                                          });
                                        },
                                        tooltip: 'Clear doctor selection',
                                      )
                                    : null,
                                ),
                                value: selectedDoctorId,
                                hint: const Text('Choose a doctor'),
                                isExpanded: true,
                                items: filteredDoctors.map((doctor) {
                                  return DropdownMenuItem<String>(
                                    value: doctor.id,
                                    child: Text('${doctor.name} (${doctor.persId})'),
                                  );
                                }).toList(),
                                validator: (val) =>
                                    val == null || val.isEmpty ? 'Select a doctor' : null,
                                onChanged: (val) {
                                  setDialogState(() {
                                    selectedDoctorId = val;
                                    // If a doctor is selected, filter patients to only show those associated with this doctor
                                    if (val != null && val.isNotEmpty) {
                                      filteredPatients = _getAvailablePatientsForDoctor(val);
                                      // If currently selected patient is not in the filtered list, clear selection
                                      if (selectedPatientId != null && 
                                          !filteredPatients.any((p) => p.id == selectedPatientId)) {
                                        selectedPatientId = null;
                                        patientSearchController.clear();
                                      }
                                    } else {
                                      filteredPatients = _patientList
                                        .where((patient) => patient.hospitalId == selectedHospitalId)
                                        .toList();
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Patient Selection section
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
                            Row(
                              children: [
                                Text('Patient Information', 
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFEC407A),
                                  )
                                ),
                                if (selectedHospitalId != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.shade300),
                                    ),
                                    child: Text(
                                      'Hospital Selected',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Patient search field - only show if hospital is selected
                            if (selectedHospitalId != null) ...[
                              TextField(
                                controller: patientSearchController,
                                decoration: InputDecoration(
                                  labelText: 'Search Patients',
                                  prefixIcon: const Icon(Icons.search),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: patientSearchController.text.isNotEmpty 
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          patientSearchController.clear();
                                          setDialogState(() {
                                            // If doctor is selected, show only patients associated with that doctor
                                            if (selectedDoctorId != null && selectedDoctorId!.isNotEmpty) {
                                              filteredPatients = _getAvailablePatientsForDoctor(selectedDoctorId!);
                                            } else {
                                              filteredPatients = _patientList
                                                .where((patient) => patient.hospitalId == selectedHospitalId)
                                                .toList();
                                            }
                                          });
                                        },
                                      )
                                    : null,
                                ),
                                onChanged: (query) {
                                  setDialogState(() {
                                    List<PatientData> baseList;
                                    // If doctor is selected, filter from patients associated with that doctor
                                    if (selectedDoctorId != null && selectedDoctorId!.isNotEmpty) {
                                      baseList = _getAvailablePatientsForDoctor(selectedDoctorId!);
                                    } else {
                                      baseList = _patientList
                                        .where((patient) => patient.hospitalId == selectedHospitalId)
                                        .toList();
                                    }
                                    
                                    if (query.isEmpty) {
                                      filteredPatients = baseList;
                                    } else {
                                      filteredPatients = baseList
                                        .where((patient) => 
                                          patient.name.toLowerCase().contains(query.toLowerCase()) ||
                                          patient.email.toLowerCase().contains(query.toLowerCase()) ||
                                          patient.persId.toLowerCase().contains(query.toLowerCase()))
                                        .toList();
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                            ] else ...[
                              // Show message when no hospital is selected
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Please select a hospital first to see available patients',
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Patient dropdown - only show if hospital is selected
                            if (selectedHospitalId != null)
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Select Patient',
                                  prefixIcon: const Icon(Icons.personal_injury),
                                  border: const OutlineInputBorder(),
                                  helperText: selectedDoctorId != null && selectedDoctorId!.isNotEmpty
                                    ? 'Showing patients associated with selected doctor'
                                    : 'Select a doctor first to see associated patients',
                                  helperStyle: TextStyle(
                                    color: selectedDoctorId != null && selectedDoctorId!.isNotEmpty
                                      ? Colors.green.shade600
                                      : Colors.orange.shade600,
                                    fontSize: 11,
                                  ),
                                  suffixIcon: selectedPatientId != null && selectedPatientId!.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.red),
                                        onPressed: () {
                                          setDialogState(() {
                                            selectedPatientId = null;
                                            patientSearchController.clear();
                                            // Reset doctor filtering to show all hospital doctors
                                            filteredDoctors = _doctorList
                                              .where((doctor) => doctor.hospitalId == selectedHospitalId)
                                              .toList();
                                          });
                                        },
                                        tooltip: 'Clear patient selection',
                                      )
                                    : null,
                                ),
                                value: selectedPatientId,
                                hint: const Text('Choose a patient'),
                                isExpanded: true,
                                items: filteredPatients.map((patient) {
                                  return DropdownMenuItem<String>(
                                    value: patient.id,
                                    child: Text('${patient.name} (${patient.persId})'),
                                  );
                                }).toList(),
                                validator: (val) =>
                                    val == null || val.isEmpty ? 'Select a patient' : null,
                                onChanged: (val) {
                                  setDialogState(() {
                                    selectedPatientId = val;
                                    // If a patient is selected, filter doctors to only show those associated with this patient
                                    if (val != null && val.isNotEmpty) {
                                      filteredDoctors = _getAvailableDoctorsForPatient(val);
                                      // If currently selected doctor is not in the filtered list, clear selection
                                      if (selectedDoctorId != null && 
                                          !filteredDoctors.any((d) => d.id == selectedDoctorId)) {
                                        selectedDoctorId = null;
                                        doctorSearchController.clear();
                                      }
                                    } else {
                                      filteredDoctors = _doctorList
                                        .where((doctor) => doctor.hospitalId == selectedHospitalId)
                                        .toList();
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Appointment Details section
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
                            Text('Appointment Details', 
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEC407A),
                              )
                            ),
                            const SizedBox(height: 16),
                            
                            // Purpose field
                    TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Purpose',
                                prefixIcon: Icon(Icons.description),
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                      validator: (val) =>
                                  val == null || val.isEmpty ? 'Enter purpose' : null,
                              onSaved: (val) => purpose = val!.trim(),
                    ),
                            
                            const SizedBox(height: 16),
                            
                    // Start Date & Time Picker
                    Row(
                      children: [
                        Expanded(
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Start Date & Time',
                                      prefixIcon: Icon(Icons.access_time),
                                      border: OutlineInputBorder(),
                                    ),
                          child: Text(
                                      '${DateFormat("yyyy-MM-dd").format(selectedStartDate)} ${selectedStartTime.format(context)}',
                                      style: const TextStyle(fontSize: 16),
                        ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_calendar),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                                      context: context,
                              initialDate: selectedStartDate,
                                      firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              final pickedTime = await showTimePicker(
                                        context: context,
                                initialTime: selectedStartTime,
                              );
                              if (pickedTime != null) {
                                        setDialogState(() {
                                  selectedStartDate = pickedDate;
                                  selectedStartTime = pickedTime;
                                          
                                          // Update end time to be 1 hour after start time
                                  final startDateTime = DateTime(
                                    selectedStartDate.year,
                                    selectedStartDate.month,
                                    selectedStartDate.day,
                                    selectedStartTime.hour,
                                    selectedStartTime.minute,
                                  );
                                          final newEndDateTime = startDateTime.add(const Duration(hours: 1));
                                          selectedEndDate = newEndDateTime;
                                          selectedEndTime = TimeOfDay.fromDateTime(newEndDateTime);
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                            
                            const SizedBox(height: 16),
                            
                    // End Date & Time Picker
                    Row(
                      children: [
                        Expanded(
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'End Date & Time',
                                      prefixIcon: Icon(Icons.access_time),
                                      border: OutlineInputBorder(),
                                    ),
                          child: Text(
                                      '${DateFormat("yyyy-MM-dd").format(selectedEndDate)} ${selectedEndTime.format(context)}',
                                      style: const TextStyle(fontSize: 16),
                        ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_calendar),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                                      context: context,
                              initialDate: selectedEndDate,
                                      firstDate: selectedStartDate,
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              final pickedTime = await showTimePicker(
                                        context: context,
                                initialTime: selectedEndTime,
                              );
                              if (pickedTime != null) {
                                final startDateTime = DateTime(
                                  selectedStartDate.year,
                                  selectedStartDate.month,
                                  selectedStartDate.day,
                                  selectedStartTime.hour,
                                  selectedStartTime.minute,
                                );
                                final potentialEndDateTime = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                                        
                                if (potentialEndDateTime.isAfter(startDateTime)) {
                                          setDialogState(() {
                                    selectedEndDate = pickedDate;
                                    selectedEndTime = pickedTime;
                                  });
                                } else {
                                  _showToast('End time must be after start time');
                                }
                              }
                            }
                          },
                        ),
                      ],
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
                icon: const Icon(Icons.add_circle),
                label: const Text('Create Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC407A),
                  foregroundColor: Colors.white,
                ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                    
                    if (selectedHospitalId == null || selectedHospitalId!.isEmpty) {
                      _showToast('Please select a hospital first');
                      return;
                    }
                    
                    if (selectedDoctorId == null || selectedPatientId == null) {
                      _showToast('Please select both doctor and patient');
                      return;
                    }

                    // Validate that the selected doctor and patient are associated with each other
                    final selectedDoctor = _doctorList.firstWhere((d) => d.id == selectedDoctorId);
                    final selectedPatient = _patientList.firstWhere((p) => p.id == selectedPatientId);
                    
                    if (!selectedDoctor.patients.contains(selectedPatientId) || 
                        !selectedPatient.doctorIds.contains(selectedDoctorId)) {
                      _showToast('Selected doctor and patient are not associated with each other');
                      return;
                    }

                    // Construct DateTime objects from date and time
                    final startDateTime = DateTime(
                  selectedStartDate.year,
                  selectedStartDate.month,
                  selectedStartDate.day,
                  selectedStartTime.hour,
                  selectedStartTime.minute,
                );
                    
                    final endDateTime = DateTime(
                  selectedEndDate.year,
                  selectedEndDate.month,
                  selectedEndDate.day,
                  selectedEndTime.hour,
                  selectedEndTime.minute,
                );

                    // Validate that start time is in the future
                    if (startDateTime.isBefore(DateTime.now())) {
                      _showToast('Start time must be in the future');
                      return;
                    }
                    
                    // Validate that end time is after start time
                    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
                      _showToast('End time must be after start time');
                      return;
                    }
                    
                Navigator.pop(ctx);

                setState(() => _isLoading = true);
                try {
                  await _appointmentProvider.createAppointment(
                    token: widget.token,
                        patientId: selectedPatientId!,
                        doctorId: selectedDoctorId!,
                        start: startDateTime,
                        end: endDateTime,
                    purpose: purpose,
                    status: 'scheduled', // Default status for new appointments
                    suspended: false, // Default to not suspended
                    hospitalId: selectedHospitalId!, // Pass the selected hospital ID
                  );
                      
                  await _fetchAppointments();
                  _showToast('Appointment created successfully');
                } catch (e) {
                  _showToast('Failed to create appointment: $e');
                } finally {
                  setState(() => _isLoading = false);
                }
              }
            },
          ),
        ],
          );
        },
      ),
    );
  }

  void _showEditAppointmentDialog(AppointmentData appointment) {
    final formKey = GlobalKey<FormState>();

    // Initialize with current appointment values
    String purpose = appointment.purpose;
    String status = appointment.status;
    bool suspended = appointment.suspended;
    
    // Date and time
    DateTime selectedStartDate = appointment.start;
    TimeOfDay selectedStartTime = TimeOfDay.fromDateTime(appointment.start);
    DateTime selectedEndDate = appointment.end;
    TimeOfDay selectedEndTime = TimeOfDay.fromDateTime(appointment.end);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit_calendar, color: const Color(0xFFEC407A)),
                const SizedBox(width: 10),
                Text('Edit Appointment', 
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
                      // Appointment information header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Patient info
                            Row(
                              children: [
                                Icon(Icons.person, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Patient: ${_getPatientName(appointment.patientId)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Doctor info
                            Row(
                              children: [
                                Icon(Icons.medical_services, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Doctor: ${_getDoctorName(appointment.doctorId)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Appointment ID
                            Row(
                              children: [
                                Icon(Icons.numbers, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ID: ${appointment.id}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Appointment Details section
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
                            Text('Appointment Details', 
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEC407A),
                              )
                            ),
                            const SizedBox(height: 16),
                            
                            // Purpose field
                    TextFormField(
                              initialValue: purpose,
                              decoration: const InputDecoration(
                                labelText: 'Purpose',
                                prefixIcon: Icon(Icons.description),
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Enter purpose' : null,
                              onSaved: (val) => purpose = val!.trim(),
                            ),
                            
                            const SizedBox(height: 16),
                            
                    // Start Date & Time Picker
                    Row(
                      children: [
                        Expanded(
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Start Date & Time',
                                      prefixIcon: Icon(Icons.access_time),
                                      border: OutlineInputBorder(),
                                    ),
                          child: Text(
                                      '${DateFormat("yyyy-MM-dd").format(selectedStartDate)} ${selectedStartTime.format(context)}',
                                      style: const TextStyle(fontSize: 16),
                        ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_calendar),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                                      context: context,
                              initialDate: selectedStartDate.isAfter(DateTime.now()) ? selectedStartDate : DateTime.now(),
                                      firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              final pickedTime = await showTimePicker(
                                        context: context,
                                initialTime: selectedStartTime,
                              );
                              if (pickedTime != null) {
                                        setDialogState(() {
                                  selectedStartDate = pickedDate;
                                  selectedStartTime = pickedTime;
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                            
                            const SizedBox(height: 16),
                            
                    // End Date & Time Picker
                    Row(
                      children: [
                        Expanded(
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'End Date & Time',
                                      prefixIcon: Icon(Icons.access_time),
                                      border: OutlineInputBorder(),
                                    ),
                          child: Text(
                                      '${DateFormat("yyyy-MM-dd").format(selectedEndDate)} ${selectedEndTime.format(context)}',
                                      style: const TextStyle(fontSize: 16),
                        ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_calendar),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                                      context: context,
                              initialDate: selectedEndDate.isAfter(DateTime.now()) ? selectedEndDate : DateTime.now(),
                                      firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              final pickedTime = await showTimePicker(
                                        context: context,
                                initialTime: selectedEndTime,
                              );
                              if (pickedTime != null) {
                                final startDateTime = DateTime(
                                  selectedStartDate.year,
                                  selectedStartDate.month,
                                  selectedStartDate.day,
                                  selectedStartTime.hour,
                                  selectedStartTime.minute,
                                );
                                final potentialEndDateTime = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                                        
                                if (potentialEndDateTime.isAfter(startDateTime)) {
                                          setDialogState(() {
                                    selectedEndDate = pickedDate;
                                    selectedEndTime = pickedTime;
                                  });
                                } else {
                                  _showToast('End time must be after start time');
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                            
                            const SizedBox(height: 16),
                            
                            // Status dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                prefixIcon: Icon(Icons.flag),
                                border: OutlineInputBorder(),
                              ),
                              value: status,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem<String>(value: 'scheduled', child: Text('Scheduled')),
                                DropdownMenuItem<String>(value: 'completed', child: Text('Completed')),
                                DropdownMenuItem<String>(value: 'cancelled', child: Text('Cancelled')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    status = val;
                                  });
                                }
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Suspended checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: suspended,
                                  activeColor: const Color(0xFFEC407A),
                          onChanged: (val) {
                                    setDialogState(() {
                              suspended = val ?? false;
                            });
                          },
                        ),
                                const Text('Suspended'),
                                const Tooltip(
                                  message: 'Suspended appointments will not be shown to patients or doctors',
                                  child: Icon(Icons.info_outline, size: 16),
                                ),
                      ],
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
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC407A),
                  foregroundColor: Colors.white,
                ),
            onPressed: () async {
                  if (formKey.currentState!.validate()) {
              formKey.currentState!.save();

                    // Check dates and validate they are in the future
                    final newStartDateTime = DateTime(
                selectedStartDate.year,
                selectedStartDate.month,
                selectedStartDate.day,
                selectedStartTime.hour,
                selectedStartTime.minute,
              );
                    
                    final newEndDateTime = DateTime(
                selectedEndDate.year,
                selectedEndDate.month,
                selectedEndDate.day,
                selectedEndTime.hour,
                selectedEndTime.minute,
              );

                    // Validate that start time is in the future
                    if (newStartDateTime.isBefore(DateTime.now())) {
                      _showToast('Start time must be in the future');
                      return;
                    }
                    
                    // Validate that end time is after start time
                    if (newEndDateTime.isBefore(newStartDateTime) || newEndDateTime.isAtSameMomentAs(newStartDateTime)) {
                      _showToast('End time must be after start time');
                      return;
                    }

              Navigator.pop(ctx);

                    // Check what actually changed
                    final Map<String, dynamic> updatedFields = {};
                    
                    // Check purpose
                    if (purpose != appointment.purpose) {
                      updatedFields['purpose'] = purpose;
                    }
                    
                    // Check status
                    if (status != appointment.status) {
                      updatedFields['status'] = status;
                    }
                    
                    // Check suspended
                    if (suspended != appointment.suspended) {
                      updatedFields['suspended'] = suspended;
                    }
                    
                    if (newStartDateTime != appointment.start) {
                      updatedFields['start'] = newStartDateTime.toIso8601String();
                    }
                    
                    if (newEndDateTime != appointment.end) {
                      updatedFields['end'] = newEndDateTime.toIso8601String();
                    }
                    
                    // Only update if something changed
                    if (updatedFields.isNotEmpty) {
              setState(() => _isLoading = true);
              try {
                await _appointmentProvider.updateAppointment(
                  token: widget.token,
                          appointmentId: appointment.id,
                  updatedFields: updatedFields,
                );
                        
                await _fetchAppointments();
                _showToast('Appointment updated successfully');
              } catch (e) {
                _showToast('Failed to update appointment: $e');
              } finally {
                setState(() => _isLoading = false);
                      }
                    } else {
                      _showToast('No changes detected');
                    }
              }
            },
          ),
        ],
          );
        },
      ),
    );
  }

  void _toggleSuspension(String appointmentId, bool newValue) async {
    print('DEBUG: Toggle suspension for appointment ID: $appointmentId');
    if (appointmentId.isEmpty) {
      _showToast('Error: Empty appointment ID');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await _appointmentProvider.updateAppointment(
        token: widget.token,
        appointmentId: appointmentId,
        updatedFields: {'suspended': newValue},
      );
      await _fetchAppointments();
      _showToast(newValue 
          ? 'Appointment suspended successfully' 
          : 'Appointment unsuspended successfully');
    } catch (e) {
      _showToast('Failed to update suspension status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cancelAppointment(String appointmentId) async {
    print('DEBUG: Cancel appointment ID: $appointmentId');
    if (appointmentId.isEmpty) {
      _showToast('Error: Empty appointment ID');
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    try {
      await _appointmentProvider.cancelAppointment(
        token: widget.token,
        appointmentId: appointmentId,
      );
      
      // Update the appointment status locally to avoid having to refetch everything
      setState(() {
        final appointmentIndex = _appointmentList.indexWhere((a) => a.id == appointmentId);
        if (appointmentIndex != -1) {
          // Create a new appointment object with status 'cancelled'
          final updatedAppointment = AppointmentData(
            id: _appointmentList[appointmentIndex].id,
            patientId: _appointmentList[appointmentIndex].patientId,
            patientName: _appointmentList[appointmentIndex].patientName,
            patientEmail: _appointmentList[appointmentIndex].patientEmail,
            doctorId: _appointmentList[appointmentIndex].doctorId,
            doctorName: _appointmentList[appointmentIndex].doctorName,
            doctorEmail: _appointmentList[appointmentIndex].doctorEmail,
            start: _appointmentList[appointmentIndex].start,
            end: _appointmentList[appointmentIndex].end,
            purpose: _appointmentList[appointmentIndex].purpose,
            status: 'cancelled', // Set the status to cancelled
            suspended: _appointmentList[appointmentIndex].suspended,
            createdAt: _appointmentList[appointmentIndex].createdAt,
            updatedAt: DateTime.now(),
          );
          
          // Replace the old appointment with the updated one
          _appointmentList[appointmentIndex] = updatedAppointment;
        }
      });
      
      _showToast('Appointment cancelled successfully');
    } catch (e) {
      _showToast('Failed to cancel appointment: $e');
      // Fetch appointments from server if local update fails
      await _fetchAppointments();
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _deleteAppointment(String appointmentId) async {
    print('DEBUG: Delete appointment ID: $appointmentId');
    if (appointmentId.isEmpty) {
      _showToast('Error: Empty appointment ID');
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text(
          'Are you sure you want to permanently delete this appointment? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    try {
      await _appointmentProvider.deleteAppointment(
        token: widget.token,
        appointmentId: appointmentId,
      );
      await _fetchAppointments();
      _showToast('Appointment deleted successfully');
    } catch (e) {
      _showToast('Failed to delete appointment: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Build the filter panel - making it more compact
  Widget _buildFilterPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showFilters ? null : 0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row: Hospital, Doctor, Patient filters in one row
              Row(
                children: [
                  // Hospital dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Hospital',
                        prefixIcon: Icon(Icons.local_hospital, size: 16),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      value: _selectedHospitalId,
                      hint: const Text('All'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('All'),
                        ),
                        ..._hospitalList.map((hospital) {
                          return DropdownMenuItem<String>(
                            value: hospital.id,
                            child: Text(hospital.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedHospitalId = value;
                          if (_selectedHospitalId != _selectedHospitalId) {
                            _selectedDoctorId = null;
                            _selectedPatientId = null;
                          }
                        });
                        // OPTIMIZED: Refetch all data when hospital changes to use efficient filtering
                        _fetchAppointments();
                        _fetchDoctors();
                        _fetchPatients();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Doctor dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Doctor',
                        prefixIcon: Icon(Icons.medical_services, size: 16),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      value: _selectedDoctorId,
                      hint: const Text('All'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('All'),
                        ),
                        ...(_selectedHospitalId != null && _selectedHospitalId!.isNotEmpty
                            ? _doctorList
                                .where((d) => d.hospitalId == _selectedHospitalId)
                                .map((doctor) {
                                  return DropdownMenuItem<String>(
                                    value: doctor.id,
                                    child: Text(doctor.name, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList()
                            : _doctorList.map((doctor) {
                                return DropdownMenuItem<String>(
                                  value: doctor.id,
                                  child: Text(doctor.name, overflow: TextOverflow.ellipsis),
                                );
                              }).toList()),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDoctorId = value;
                          if (value != null && value.isNotEmpty) {
                            _selectedPatientId = null;
                          }
                        });
                        _fetchAppointments();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Patient dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Patient',
                        prefixIcon: Icon(Icons.person, size: 16),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      value: _selectedPatientId,
                      hint: const Text('All'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('All'),
                        ),
                        ..._patientList.map((patient) {
                          return DropdownMenuItem<String>(
                            value: patient.id,
                            child: Text(patient.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPatientId = value;
                          if (value != null && value.isNotEmpty) {
                            _selectedDoctorId = null;
                          }
                        });
                        _fetchAppointments();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Second row: Status, date range, suspended filters
              Row(
                children: [
                  // Status dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.flag, size: 16),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      value: _selectedStatus,
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'all',
                          child: Text('All'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'scheduled',
                          child: Text('Scheduled'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'cancelled',
                          child: Text('Cancelled'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                        _fetchAppointments();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Date range preset dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.date_range, size: 16),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      value: _selectedDateRange,
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'all',
                          child: Text('All'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'today',
                          child: Text('Today'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'week',
                          child: Text('This Week'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'month',
                          child: Text('This Month'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'custom',
                          child: Text('Custom'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDateRange = value!;
                          if (value != 'custom') {
                            _fromDate = null;
                            _toDate = null;
                          }
                        });
                        _fetchAppointments();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Suspended filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Suspended',
                        prefixIcon: Icon(Icons.block, size: 16),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      value: _suspendFilter,
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'all',
                          child: Text('All'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'suspended',
                          child: Text('Suspended'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'unsuspended',
                          child: Text('Active'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _suspendFilter = value!;
                        });
                        _fetchAppointments();
                      },
                    ),
                  ),
                ],
              ),
              
              // Custom date range pickers (visible only when 'custom' is selected)
              if (_selectedDateRange == 'custom')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _fromDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _fromDate = pickedDate;
                              });
                              _fetchAppointments();
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'From',
                              prefixIcon: Icon(Icons.calendar_today, size: 16),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              isDense: true,
                            ),
                            child: Text(
                              _fromDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_fromDate!)
                                  : 'Select',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _toDate ?? (_fromDate != null ? _fromDate!.add(const Duration(days: 7)) : DateTime.now()),
                              firstDate: _fromDate ?? DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _toDate = pickedDate;
                              });
                              _fetchAppointments();
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'To',
                              prefixIcon: Icon(Icons.calendar_today, size: 16),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              isDense: true,
                            ),
                            child: Text(
                              _toDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_toDate!)
                                  : 'Select',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 8),
              
              // Filter actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedHospitalId = null;
                        _selectedDoctorId = null;
                        _selectedPatientId = null;
                        _selectedDateRange = 'all';
                        _selectedStatus = 'all';
                        _suspendFilter = 'all';
                        _fromDate = null;
                        _toDate = null;
                      });
                      // OPTIMIZED: Refetch all data when clearing filters to use efficient methods
                      _fetchAppointments();
                      _fetchDoctors();
                      _fetchPatients();
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Apply', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC407A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: _fetchAppointments,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Store the ScaffoldMessenger state at the beginning of build
    _scaffoldMessenger = ScaffoldMessenger.of(context);

    if (_isLoading) {
      return const LoadingIndicator();
    }

    // Apply text search filter
    final filtered = _appointmentList.where((appointment) {
      final query = _searchQuery.toLowerCase();
      return appointment.patientName.toLowerCase().contains(query) ||
          appointment.doctorName.toLowerCase().contains(query) ||
          appointment.purpose.toLowerCase().contains(query) ||
          appointment.status.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(icon: Icons.event, title: 'Appointments Management'),
            SizedBox(height: 24),
            // Compact header and search row
            Row(
              children: [
                Text(
                  'Appointments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEC407A),
                  ),
                ),
                const SizedBox(width: 8),
                // Toggle filter button
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  icon: Icon(
                    _showFilters ? Icons.filter_list_off : Icons.filter_list,
                    size: 18,
                  ),
                  label: Text(
                    _showFilters ? "Hide Filters" : "Show Filters",
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                const Spacer(),
                // Compact search
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search appointments...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showAddAppointmentDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC407A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Collapsible filter panel
            _buildFilterPanel(),
            
            // Results count in a more compact way
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                'Showing ${filtered.length} appointments',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            
            // Expanded table to take up maximum space
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No appointments found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : BetterPaginatedDataTable(
                       themeColor: const Color(0xFFEC407A),
                       rowsPerPage: 10, // Use a valid value from availableRowsPerPage
                       columns: const [
                         DataColumn(label: Text('ID')),
                         DataColumn(label: Text('Patient')),
                         DataColumn(label: Text('Doctor')),
                         DataColumn(label: Text('Start')),
                         DataColumn(label: Text('End')),
                         DataColumn(label: Text('Purpose')),
                         DataColumn(label: Text('Status')),
                         DataColumn(label: Text('Suspended')),
                         DataColumn(label: Text('Actions')),
                       ],
                       rows: filtered.map((appointment) {
                         return DataRow(
                           cells: [
                             DataCell(
                               Container(
                                 padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                 constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
                                 child: Text(
                                   appointment.id,
                                   maxLines: 2,
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
                                 constraints: const BoxConstraints(minWidth: 180, maxWidth: 250),
                                 child: Column(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       _getPatientName(appointment.patientId),
                                       maxLines: 2,
                                       overflow: TextOverflow.ellipsis,
                                       softWrap: true,
                                       style: const TextStyle(
                                         fontSize: 14,
                                         height: 1.3,
                                         fontWeight: FontWeight.w500,
                                       ),
                                     ),
                                     Text(
                                       _getPatientEmail(appointment.patientId),
                                       maxLines: 2,
                                       overflow: TextOverflow.ellipsis,
                                       softWrap: true,
                                       style: TextStyle(
                                         fontSize: 12,
                                         height: 1.3,
                                         color: Colors.grey.shade600,
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                             DataCell(
                               Container(
                                 padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                 constraints: const BoxConstraints(minWidth: 180, maxWidth: 250),
                                 child: Column(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       _getDoctorName(appointment.doctorId),
                                       maxLines: 2,
                                       overflow: TextOverflow.ellipsis,
                                       softWrap: true,
                                       style: const TextStyle(
                                         fontSize: 14,
                                         height: 1.3,
                                         fontWeight: FontWeight.w500,
                                       ),
                                     ),
                                     Text(
                                       _getDoctorEmail(appointment.doctorId),
                                       maxLines: 2,
                                       overflow: TextOverflow.ellipsis,
                                       softWrap: true,
                                       style: TextStyle(
                                         fontSize: 12,
                                         height: 1.3,
                                         color: Colors.grey.shade600,
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                             DataCell(
                               Container(
                                 padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                 constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
                                 child: Text(
                                   DateFormat('yyyy-MM-dd HH:mm').format(appointment.start),
                                   maxLines: 2,
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
                                 constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
                                 child: Text(
                                   DateFormat('yyyy-MM-dd HH:mm').format(appointment.end),
                                   maxLines: 2,
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
                                 constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
                                 child: Text(
                                   appointment.purpose,
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
                                 constraints: const BoxConstraints(minWidth: 100, maxWidth: 120),
                                 child: Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                   decoration: BoxDecoration(
                                     color: _getStatusColor(appointment.status),
                                     borderRadius: BorderRadius.circular(12),
                                   ),
                                   child: Text(
                                     appointment.status,
                                     maxLines: 1,
                                     overflow: TextOverflow.ellipsis,
                                     softWrap: true,
                                     style: const TextStyle(
                                       fontSize: 13,
                                       height: 1.3,
                                       color: Colors.white,
                                       fontWeight: FontWeight.w500,
                                     ),
                                   ),
                                 ),
                               ),
                             ),
                             DataCell(
                               Container(
                                 padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                 constraints: const BoxConstraints(minWidth: 80, maxWidth: 100),
                                 child: Switch(
                                   value: appointment.suspended,
                                   activeColor: const Color(0xFFEC407A),
                                   onChanged: (newValue) {
                                     _toggleSuspension(appointment.id, newValue);
                                   },
                                   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                 ),
                               ),
                             ),
                             DataCell(
                               Container(
                                 padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                 constraints: const BoxConstraints(minWidth: 120, maxWidth: 150),
                                 child: Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     IconButton(
                                       icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                       onPressed: () => _showEditAppointmentDialog(appointment),
                                       tooltip: 'Edit',
                                       padding: EdgeInsets.zero,
                                       constraints: const BoxConstraints(),
                                       visualDensity: VisualDensity.compact,
                                     ),
                                     const SizedBox(width: 4),
                                     if (appointment.status == 'scheduled')
                                       IconButton(
                                         icon: const Icon(Icons.cancel, color: Colors.orange, size: 18),
                                         onPressed: () => _cancelAppointment(appointment.id),
                                         tooltip: 'Cancel',
                                         padding: EdgeInsets.zero,
                                         constraints: const BoxConstraints(),
                                         visualDensity: VisualDensity.compact,
                                       ),
                                     const SizedBox(width: 4),
                                     IconButton(
                                       icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                       onPressed: () => _deleteAppointment(appointment.id),
                                       tooltip: 'Delete',
                                       padding: EdgeInsets.zero,
                                       constraints: const BoxConstraints(),
                                       visualDensity: VisualDensity.compact,
                                     ),
                                   ],
                                 ),
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
  
  // Helper method to get color based on status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper methods to get patient and doctor info from IDs
  String _getPatientName(String patientId) {
    final patient = _patientList.firstWhere(
      (p) => p.id == patientId,
      orElse: () => PatientData(
        id: '',
        persId: '',
        name: 'Unknown Patient',
        email: '',
        mobileNumber: '',
        birthDate: DateTime.now(),
        hospitalId: '',
        doctorIds: [],
        status: '',
        diagnosis: '',
        medicalHistory: [],
        suspended: false,
      ),
    );
    return patient.name.isNotEmpty ? patient.name : 'Unknown Patient';
  }

  String _getPatientEmail(String patientId) {
    final patient = _patientList.firstWhere(
      (p) => p.id == patientId,
      orElse: () => PatientData(
        id: '',
        persId: '',
        name: '',
        email: 'unknown@email.com',
        mobileNumber: '',
        birthDate: DateTime.now(),
        hospitalId: '',
        doctorIds: [],
        status: '',
        diagnosis: '',
        medicalHistory: [],
        suspended: false,
      ),
    );
    return patient.email.isNotEmpty ? patient.email : 'unknown@email.com';
  }

  String _getDoctorName(String doctorId) {
    final doctor = _doctorList.firstWhere(
      (d) => d.id == doctorId,
      orElse: () => DoctorData(
        id: '',
        persId: '',
        name: 'Unknown Doctor',
        email: '',
        mobileNumber: '',
        birthDate: DateTime.now(),
        licenses: [],
        description: '',
        hospitalId: '',
        patients: [],
        schedule: [],
        suspended: false,
      ),
    );
    return doctor.name.isNotEmpty ? doctor.name : 'Unknown Doctor';
  }

  String _getDoctorEmail(String doctorId) {
    final doctor = _doctorList.firstWhere(
      (d) => d.id == doctorId,
      orElse: () => DoctorData(
        id: '',
        persId: '',
        name: '',
        email: 'unknown@email.com',
        mobileNumber: '',
        birthDate: DateTime.now(),
        licenses: [],
        description: '',
        hospitalId: '',
        patients: [],
        schedule: [],
        suspended: false,
      ),
    );
    return doctor.email.isNotEmpty ? doctor.email : 'unknown@email.com';
  }
}
