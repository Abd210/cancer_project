// lib/pages/superadmin/view_doctors/view_doctors_page.dart

import 'package:flutter/material.dart';

import 'package:frontend/providers/doctor_provider.dart';
import 'package:frontend/providers/patient_provider.dart';
import 'package:frontend/providers/hospital_provider.dart';
import 'package:frontend/providers/admin_provider.dart';
import 'package:frontend/models/doctor_data.dart';
import 'package:frontend/models/hospital_data.dart';
import 'package:frontend/models/patient_data.dart';
import 'package:frontend/models/admin_data.dart';

import '../../../shared/components/loading_indicator.dart';
import '../../../shared/components/components.dart';
import '../../../shared/components/page_header.dart';
import '../../../shared/components/responsive_data_table.dart'
    show BetterPaginatedDataTable;

class DoctorsPage extends StatefulWidget {
  final String token;
  const DoctorsPage({super.key, required this.token});

  @override
  _DoctorsPageState createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  final DoctorProvider _doctorProvider = DoctorProvider();
  final PatientProvider _patientProvider = PatientProvider();
  final HospitalProvider _hospitalProvider = HospitalProvider();
  final AdminProvider _adminProvider = AdminProvider();

  bool _isLoading = false;
  String _searchQuery = '';
  String _filter = 'unsuspended'; // "unsuspended", "suspended", "all"

  List<DoctorData> _doctorList = [];
  List<PatientData> _patientList = [];
  List<HospitalData> _hospitalList = [];
  AdminData? _currentAdmin;
  String? _adminHospitalId;

  @override
  void initState() {
    super.initState();
    _initializeAdminData();
  }

  Future<void> _initializeAdminData() async {
    setState(() => _isLoading = true);
    try {
      // Get current admin data to find their hospital ID
      final admins = await _adminProvider.getAdmins(token: widget.token);
      if (admins.isNotEmpty) {
        _currentAdmin = admins.first;
        _adminHospitalId = _currentAdmin!.hospitalId;
        
        if (_adminHospitalId != null && _adminHospitalId!.isNotEmpty) {
          // Only fetch data if admin has a hospital assigned
          await Future.wait([
            _fetchDoctors(),
            _fetchPatients(),
            _fetchHospitals(),
          ]);
        } else {
          // Admin has no hospital assigned
          setState(() {
            _doctorList = [];
            _patientList = [];
            _hospitalList = [];
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No hospital assigned to your account. Please contact your administrator.')),
            );
          }
        }
      } else {
        throw Exception('Admin data not found');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load admin data: $e')),
        );
      }
    }
  }

  Future<void> _fetchHospitals() async {
    if (_adminHospitalId == null || _adminHospitalId!.isEmpty) {
      setState(() => _hospitalList = []);
      return;
    }

    try {
      final hospitals = await _hospitalProvider.getHospitals(
        token: widget.token,
        hospitalId: _adminHospitalId!, // Only fetch admin's hospital
      );
      setState(() {
        _hospitalList = hospitals;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load hospitals: $e')),
        );
      }
    }
  }

  Future<void> _fetchDoctors() async {
    if (_adminHospitalId == null || _adminHospitalId!.isEmpty) {
      setState(() {
        _doctorList = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final docs = await _doctorProvider.getDoctors(
        token: widget.token,
        doctorId: '',
        filter: _filter,
        hospitalId: _adminHospitalId!, // Filter by admin's hospital
      );
      setState(() {
        _doctorList = docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load doctors: $e')),
        );
      }
    }
  }

  Future<void> _fetchPatients() async {
    if (_adminHospitalId == null || _adminHospitalId!.isEmpty) {
      setState(() => _patientList = []);
      return;
    }

    try {
      final patients = await _patientProvider.getPatients(
        token: widget.token,
        patientId: '',
        filter: 'all',
        hospitalId: _adminHospitalId!, // Filter by admin's hospital
      );
      setState(() {
        _patientList = patients;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load patients: $e')),
        );
      }
    }
  }

  // Function to show patient selection in a separate dialog
  void _showPatientSelectionDialog(BuildContext context, List<String> selectedPatients, Function(List<String>) onSave, String hospitalId) {
    TextEditingController patientSearchController = TextEditingController();
    List<String> tempSelectedPatients = List.from(selectedPatients);
    
    // Filter patients by the selected hospital
    List<PatientData> hospitalPatients = _patientList.where((patient) => 
      patient.hospitalId == hospitalId
    ).toList();
    
    if (hospitalPatients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patients found for the selected hospital')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.people, color: const Color(0xFFEC407A)),
            const SizedBox(width: 10),
            const Text('Assign Hospital Patients'),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setInnerState) {
            // Filter patients based on search text
            List<PatientData> filteredPatients = hospitalPatients.where((patient) {
              final query = patientSearchController.text.toLowerCase();
              return query.isEmpty || 
                patient.name.toLowerCase().contains(query) ||
                patient.email.toLowerCase().contains(query) ||
                patient.persId.toLowerCase().contains(query);
            }).toList();
            
            return Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.6,
              constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
              child: Column(
                children: [
                  TextField(
                    controller: patientSearchController,
                    decoration: InputDecoration(
                      labelText: 'Search Hospital Patients',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: patientSearchController.text.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                patientSearchController.clear();
                                setInnerState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setInnerState(() {}),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${tempSelectedPatients.length} patients selected',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear All'),
                          onPressed: tempSelectedPatients.isEmpty ? null : () {
                            setInnerState(() {
                              tempSelectedPatients.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: filteredPatients.isEmpty
                      ? Center(
                          child: Text(
                            'No matching patients found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredPatients.length,
                          itemBuilder: (context, index) {
                            final patient = filteredPatients[index];
                            final isSelected = tempSelectedPatients.contains(patient.id);
                            
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: isSelected ? const Color(0xFFFCE4EC) : Colors.white,
                              child: CheckboxListTile(
                                title: Text(
                                  patient.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('${patient.email} (ID: ${patient.persId})'),
                                secondary: CircleAvatar(
                                  backgroundColor: isSelected ? const Color(0xFFEC407A) : Colors.grey[300],
                                  child: Text(
                                    patient.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                                value: isSelected,
                                activeColor: const Color(0xFFEC407A),
                                onChanged: (selected) {
                                  setInnerState(() {
                                    if (selected!) {
                                      tempSelectedPatients.add(patient.id);
                                    } else {
                                      tempSelectedPatients.remove(patient.id);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Confirm Selection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC407A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              onSave(tempSelectedPatients);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  // Helper function to validate schedule for overlaps
  String? _validateSchedule(List<Map<String, String>> schedule) {
    if (schedule.isEmpty) return null;
    
    // Group by day
    Map<String, List<Map<String, String>>> dayGroups = {};
    for (var entry in schedule) {
      String day = entry['day'] ?? '';
      String start = entry['start'] ?? '';
      String end = entry['end'] ?? '';
      
      if (day.isEmpty || start.isEmpty || end.isEmpty) {
        return 'All schedule entries must have day, start time, and end time filled.';
      }
      
      if (!dayGroups.containsKey(day)) {
        dayGroups[day] = [];
      }
      dayGroups[day]!.add(entry);
    }
    
    // Check for overlaps within each day
    for (String day in dayGroups.keys) {
      List<Map<String, String>> dayEntries = dayGroups[day]!;
      
      for (int i = 0; i < dayEntries.length; i++) {
        for (int j = i + 1; j < dayEntries.length; j++) {
          String start1 = dayEntries[i]['start']!;
          String end1 = dayEntries[i]['end']!;
          String start2 = dayEntries[j]['start']!;
          String end2 = dayEntries[j]['end']!;
          
          // Convert time strings to minutes for comparison
          int start1Minutes = _timeToMinutes(start1);
          int end1Minutes = _timeToMinutes(end1);
          int start2Minutes = _timeToMinutes(start2);
          int end2Minutes = _timeToMinutes(end2);
          
          if (start1Minutes >= end1Minutes) {
            return 'Invalid time range on $day: start time must be before end time.';
          }
          if (start2Minutes >= end2Minutes) {
            return 'Invalid time range on $day: start time must be before end time.';
          }
          
          // Check for overlap
          if (start1Minutes < end2Minutes && start2Minutes < end1Minutes) {
            return 'Time overlap detected on $day: ${start1}-${end1} overlaps with ${start2}-${end2}.';
          }
        }
      }
    }
    
    return null;
  }
  
  // Helper function to convert time string (HH:MM) to minutes
  int _timeToMinutes(String time) {
    try {
      List<String> parts = time.split(':');
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);
      return hours * 60 + minutes;
    } catch (e) {
      return 0; // Default to 0 if parsing fails
    }
  }

  void _showAddDoctorDialog() {
    final formKey = GlobalKey<FormState>();

    String persId = '';
    String name = '';
    String password = '';
    String email = '';
    String mobileNumber = '';
    String birthDate = '';
    String licensesRaw = '';
    String description = '';
    List<String> selectedPatients = [];
    List<Map<String, String>> schedule = [];
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person_add, color: const Color(0xFFEC407A)),
              const SizedBox(width: 10),
              const Text('Add New Doctor', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            )
                          ),
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
                                          val == null || val.isEmpty ? 'Enter name' : null,
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
                                          val == null || val.isEmpty ? 'Enter email' : null,
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
                                          val == null || val.isEmpty ? 'Enter birth date' : null,
                                      onSaved: (val) => birthDate = val!.trim(),
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
                                          val == null || val.isEmpty ? 'Enter persId' : null,
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
                                          val == null || val.isEmpty ? 'Enter mobile number' : null,
                                      onSaved: (val) => mobileNumber = val!.trim(),
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
                                          val == null || val.isEmpty ? 'Enter password' : null,
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
                    
                    // Professional Information section
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
                          Text('Professional Information', 
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEC407A),
                            )
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Licenses (comma-separated)',
                              prefixIcon: Icon(Icons.work),
                              border: OutlineInputBorder(),
                            ),
                            onSaved: (val) => licensesRaw = val ?? '',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Professional Description',
                              hintText: 'Enter specialties, experience, and expertise',
                              prefixIcon: Icon(Icons.description),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            onSaved: (val) => description = val?.trim() ?? '',
                          ),
                          const SizedBox(height: 16),
                          
                          // Hospital assignment info (read-only)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.local_hospital, color: Colors.blue.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Doctor will be assigned to your hospital automatically',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Patient Assignment section
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
                          Text('Patient Assignment', 
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEC407A),
                            )
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selected Patients: ${selectedPatients.length}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        selectedPatients.isEmpty 
                                            ? 'No patients assigned yet'
                                            : 'Click "Manage Patients" to view or edit assignments',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _showPatientSelectionDialog(
                                    dialogContext,
                                    selectedPatients,
                                    (updatedPatients) {
                                      setDialogState(() {
                                        selectedPatients = updatedPatients;
                                      });
                                    },
                                    _adminHospitalId!,
                                  );
                                },
                                icon: const Icon(Icons.people),
                                label: const Text('Manage Patients'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEC407A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  disabledForegroundColor: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Schedule Management section
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Weekly Schedule', 
                                style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFEC407A),
                                )
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setDialogState(() {
                                    schedule.add({
                                      'day': 'Monday',
                                      'start': '09:00',
                                      'end': '17:00',
                                    });
                                  });
                                },
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Day'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEC407A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          if (schedule.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, color: Colors.grey.shade600),
                                  const SizedBox(width: 12),
                                  Text(
                                    'No schedule set. Click "Add Day" to create working hours.',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...schedule.asMap().entries.map((entry) {
                              int index = entry.key;
                              Map<String, String> daySchedule = entry.value;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Day dropdown
                                      Expanded(
                                        flex: 2,
                                        child: DropdownButtonFormField<String>(
                                          value: daySchedule['day'],
                                          decoration: const InputDecoration(
                                            labelText: 'Day',
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            isDense: true,
                                          ),
                                          items: [
                                            'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
                                            'Friday', 'Saturday', 'Sunday'
                                          ].map((day) => DropdownMenuItem(
                                            value: day,
                                            child: Text(day),
                                          )).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setDialogState(() {
                                                schedule[index]['day'] = value;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      
                                      // Start time
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: daySchedule['start'],
                                          decoration: const InputDecoration(
                                            labelText: 'Start',
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            isDense: true,
                                          ),
                                          onChanged: (value) {
                                            schedule[index]['start'] = value;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      
                                      // End time
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: daySchedule['end'],
                                          decoration: const InputDecoration(
                                            labelText: 'End',
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            isDense: true,
                                          ),
                                          onChanged: (value) {
                                            schedule[index]['end'] = value;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      
                                      // Remove button
                                      IconButton(
                                        onPressed: () {
                                          setDialogState(() {
                                            schedule.removeAt(index);
                                          });
                                        },
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Remove',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
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
              label: const Text('Save Doctor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC407A),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  
                  // Validate schedule for overlaps
                  String? scheduleError = _validateSchedule(schedule);
                  if (scheduleError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(scheduleError),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.pop(ctx);

                  final licensesList = licensesRaw
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();

                  setState(() => _isLoading = true);
                  try {
                    await _doctorProvider.createDoctor(
                      token: widget.token,
                      persId: persId,
                      name: name,
                      password: password,
                      email: email,
                      mobileNumber: mobileNumber,
                      birthDate: birthDate,
                      licenses: licensesList,
                      description: description,
                      hospitalId: _adminHospitalId!,
                      suspended: false,
                      patients: selectedPatients,
                      schedule: schedule,
                    );

                    await _fetchDoctors();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Doctor added successfully.')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add doctor: $e')),
                      );
                    }
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

  void _showEditDoctorDialog(DoctorData doc) {
    final formKey = GlobalKey<FormState>();

    // Store original values to track changes
    final String originalName = doc.name;
    final String originalEmail = doc.email;
    final String originalPassword = doc.password;
    final String originalPersId = doc.persId;
    final String originalMobileNumber = doc.mobileNumber;
    final String originalBirthDateStr = doc.birthDate.toIso8601String().split('T')[0];
    final List<String> originalLicenses = List.from(doc.licenses);
    final String originalDescription = doc.description;
    final List<String> originalPatients = List.from(doc.patients);
    final List<Map<String, String>> originalSchedule = List.from(doc.schedule);

    // Editable values
    String name = originalName;
    String email = originalEmail;
    String password = originalPassword;
    String persId = originalPersId;
    String mobileNumber = originalMobileNumber;
    String birthDateStr = originalBirthDateStr;
    List<String> licenses = List.from(originalLicenses);
    String description = originalDescription;
    String hospitalId = doc.hospitalId;
    List<String> selectedPatients = List.from(originalPatients);
    List<Map<String, String>> schedule = doc.schedule.map((s) => Map<String, String>.from(s)).toList();
    
    // Get the hospital name for display
    String hospitalName = 'Unknown Hospital';
    for (var hospital in _hospitalList) {
      if (hospital.id == hospitalId) {
        hospitalName = hospital.name;
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
              Text('Edit Doctor: ${doc.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                            )
                          ),
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
                                          val == null || val.isEmpty ? 'Enter name' : null,
                                      onSaved: (val) => name = val!.trim(),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: email,
                                      decoration: InputDecoration(
                                        labelText: 'Email Address',
                                        prefixIcon: const Icon(Icons.email),
                                        border: const OutlineInputBorder(),
                                        helperText: 'This is your login identifier',
                                        helperStyle: TextStyle(color: Colors.grey.shade600),
                                      ),
                                      enabled: false, // Disable email editing to prevent uniqueness errors
                                      validator: (val) =>
                                          val == null || val.isEmpty ? 'Enter email' : null,
                                      onSaved: (val) => email = val!.trim(),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: birthDateStr,
                                      decoration: const InputDecoration(
                                        labelText: 'Birth Date (YYYY-MM-DD)',
                                        prefixIcon: Icon(Icons.calendar_today),
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (val) =>
                                          val == null || val.isEmpty ? 'Enter birth date' : null,
                                      onSaved: (val) => birthDateStr = val!.trim(),
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
                                          val == null || val.isEmpty ? 'Enter persId' : null,
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
                                          val == null || val.isEmpty ? 'Enter mobile number' : null,
                                      onSaved: (val) => mobileNumber = val!.trim(),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: password,
                                      decoration: const InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: Icon(Icons.lock),
                                        border: OutlineInputBorder(),
                                        hintText: 'Leave empty to keep current password',
                                      ),
                                      obscureText: true,
                                      validator: null, // Allow empty password during update
                                      onSaved: (val) => password = val?.trim() ?? '',
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
                    
                    // Professional Information section
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
                          Text('Professional Information', 
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEC407A),
                            )
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            initialValue: licenses.join(', '),
                            decoration: const InputDecoration(
                              labelText: 'Licenses (comma-separated)',
                              prefixIcon: Icon(Icons.work),
                              border: OutlineInputBorder(),
                            ),
                            onSaved: (val) {
                              final raw = val ?? '';
                              licenses = raw
                                  .split(',')
                                  .map((s) => s.trim())
                                  .where((s) => s.isNotEmpty)
                                  .toList();
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: description,
                            decoration: const InputDecoration(
                              labelText: 'Professional Description',
                              hintText: 'Enter specialties, experience, and expertise',
                              prefixIcon: Icon(Icons.description),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            onSaved: (val) => description = val?.trim() ?? '',
                          ),
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
                                    message: 'To change hospital, please create a new doctor account',
                                    child: Icon(Icons.info_outline, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Patient Assignment section
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
                          Text('Patient Assignment', 
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEC407A),
                            )
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selected Patients: ${selectedPatients.length}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        selectedPatients.isEmpty 
                                            ? 'No patients assigned yet'
                                            : 'Click "Manage Patients" to view or edit assignments',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _showPatientSelectionDialog(
                                    dialogContext,
                                    selectedPatients,
                                    (updatedPatients) {
                                      setDialogState(() {
                                        selectedPatients = updatedPatients;
                                      });
                                    },
                                    hospitalId,
                                  );
                                },
                                icon: const Icon(Icons.people),
                                label: const Text('Manage Patients'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEC407A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Schedule Management section
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Weekly Schedule', 
                                style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFEC407A),
                                )
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setDialogState(() {
                                    schedule.add({
                                      'day': 'Monday',
                                      'start': '09:00',
                                      'end': '17:00',
                                    });
                                  });
                                },
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Day'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEC407A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          if (schedule.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, color: Colors.grey.shade600),
                                  const SizedBox(width: 12),
                                  Text(
                                    'No schedule set. Click "Add Day" to create working hours.',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...schedule.asMap().entries.map((entry) {
                              int index = entry.key;
                              Map<String, String> daySchedule = entry.value;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Day dropdown
                                      Expanded(
                                        flex: 2,
                                        child: DropdownButtonFormField<String>(
                                          value: daySchedule['day'],
                                          decoration: const InputDecoration(
                                            labelText: 'Day',
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            isDense: true,
                                          ),
                                          items: [
                                            'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
                                            'Friday', 'Saturday', 'Sunday'
                                          ].map((day) => DropdownMenuItem(
                                            value: day,
                                            child: Text(day),
                                          )).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setDialogState(() {
                                                schedule[index]['day'] = value;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      
                                      // Start time
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: daySchedule['start'],
                                          decoration: const InputDecoration(
                                            labelText: 'Start',
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            isDense: true,
                                          ),
                                          onChanged: (value) {
                                            schedule[index]['start'] = value;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      
                                      // End time
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: daySchedule['end'],
                                          decoration: const InputDecoration(
                                            labelText: 'End',
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            isDense: true,
                                          ),
                                          onChanged: (value) {
                                            schedule[index]['end'] = value;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      
                                      // Remove button
                                      IconButton(
                                        onPressed: () {
                                          setDialogState(() {
                                            schedule.removeAt(index);
                                          });
                                        },
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Remove',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
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
                  
                  // Validate schedule for overlaps
                  String? scheduleError = _validateSchedule(schedule);
                  if (scheduleError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(scheduleError),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.pop(ctx);

                  setState(() => _isLoading = true);

                  try {
                    // Only include fields that have actually changed
                    final Map<String, dynamic> updatedFields = {};
                    
                    if (name != originalName) updatedFields["name"] = name;
                    if (persId != originalPersId) updatedFields["persId"] = persId;
                    if (password.isNotEmpty && password != originalPassword) updatedFields["password"] = password;
                    if (mobileNumber != originalMobileNumber) updatedFields["mobileNumber"] = mobileNumber;
                    if (birthDateStr != originalBirthDateStr) updatedFields["birthDate"] = birthDateStr;
                    
                    // Check if licenses have changed
                    bool licensesChanged = licenses.length != originalLicenses.length;
                    if (!licensesChanged) {
                      for (int i = 0; i < licenses.length; i++) {
                        if (i >= originalLicenses.length || licenses[i] != originalLicenses[i]) {
                          licensesChanged = true;
                          break;
                        }
                      }
                    }
                    if (licensesChanged) updatedFields["licenses"] = licenses;
                    
                    if (description != originalDescription) updatedFields["description"] = description;
                    
                    // Check if patients have changed
                    bool patientsChanged = selectedPatients.length != originalPatients.length;
                    if (!patientsChanged) {
                      for (int i = 0; i < selectedPatients.length; i++) {
                        if (i >= originalPatients.length || selectedPatients[i] != originalPatients[i]) {
                          patientsChanged = true;
                          break;
                        }
                      }
                    }
                    if (patientsChanged) updatedFields["patients"] = selectedPatients;
                    
                    // Check if schedule has changed
                    bool scheduleChanged = schedule.length != originalSchedule.length;
                    if (!scheduleChanged) {
                      for (int i = 0; i < schedule.length; i++) {
                        if (i >= originalSchedule.length || 
                            schedule[i]['day'] != originalSchedule[i]['day'] ||
                            schedule[i]['start'] != originalSchedule[i]['start'] ||
                            schedule[i]['end'] != originalSchedule[i]['end']) {
                          scheduleChanged = true;
                          break;
                        }
                      }
                    }
                    if (scheduleChanged) updatedFields["schedule"] = schedule;

                    // Only make the API call if there are changes
                    if (updatedFields.isNotEmpty) {
                      bool success = await _doctorProvider.updateDoctor(
                        token: widget.token,
                        doctorId: doc.id,
                        updatedFields: updatedFields,
                      );
                      
                      // Always refresh the list regardless of the response
                      await _fetchDoctors();
                      
                      if (mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Doctor updated successfully')),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('No changes detected')),
                        );
                      }
                    }
                  } catch (e) {
                    // Try to refresh the list even if there was an error
                    try {
                      await _fetchDoctors();
                    } catch (_) {
                      // Ignore any error from the refresh attempt
                    }
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update doctor: $e')),
                      );
                    }
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

  void _deleteDoctor(String doctorId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Doctor'),
        content: const Text('Are you sure you want to delete this doctor?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              try {
                await _doctorProvider.deleteDoctor(
                  token: widget.token,
                  doctorId: doctorId,
                );
                await _fetchDoctors();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Doctor deleted successfully.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete doctor: $e')),
                  );
                }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    final filteredDoctors = _doctorList.where((doc) {
      final q = _searchQuery.toLowerCase();
      return doc.name.toLowerCase().contains(q) ||
          doc.persId.toLowerCase().contains(q) ||
          doc.email.toLowerCase().contains(q) ||
          doc.mobileNumber.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const PageHeader(icon: Icons.person, title: 'Doctors Management'),
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
                    onChanged: (_adminHospitalId == null || _adminHospitalId!.isEmpty) ? null : (val) async {
                      if (val != null) {
                        setState(() => _filter = val);
                        await _fetchDoctors();
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
                    enabled: _adminHospitalId != null && _adminHospitalId!.isNotEmpty,
                    decoration: InputDecoration(
                      labelText: 'Search Doctors',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: (_adminHospitalId == null || _adminHospitalId!.isEmpty) ? null : _showAddDoctorDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Doctor'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: (_adminHospitalId == null || _adminHospitalId!.isEmpty) ? null : _fetchDoctors,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: (_adminHospitalId == null || _adminHospitalId!.isEmpty)
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
                            'You cannot view doctors because you are not assigned to any hospital.',
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
                  : _doctorList.isEmpty
                      ? const Center(child: Text('No doctors found.'))
                      : Column(
                      children: [
                        Expanded(
                          child: BetterPaginatedDataTable(
                            themeColor: const Color(0xFFEC407A),
                            rowsPerPage: 10,
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Pers ID')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Mobile')),
                              DataColumn(label: Text('Birth Date')),
                              DataColumn(label: Text('Suspended')),
                              DataColumn(label: Text('Patients')),
                              DataColumn(label: Text('Licenses')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: filteredDoctors.map((doc) {
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
                                        doc.name,
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
                                        doc.persId,
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
                                        doc.email,
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
                                        minWidth: 120,
                                        maxWidth: 150,
                                      ),
                                      child: Text(
                                        doc.mobileNumber,
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
                                        minWidth: 110,
                                        maxWidth: 130,
                                      ),
                                      child: Text(
                                        doc.birthDate.toIso8601String().split('T')[0],
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
                                      constraints: const BoxConstraints(
                                        minWidth: 80,
                                        maxWidth: 100,
                                      ),
                                      child: Text(
                                        doc.suspended ? 'Yes' : 'No',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.3,
                                          color: doc.suspended ? Colors.red : Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      constraints: const BoxConstraints(
                                        minWidth: 60,
                                        maxWidth: 80,
                                      ),
                                      child: Text(
                                        '${doc.patients.length}',
                                        maxLines: 1,
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
                                        minWidth: 180,
                                        maxWidth: 250,
                                      ),
                                      child: Text(
                                        doc.licenses.join(", "),
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
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _showEditDoctorDialog(doc),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteDoctor(doc.id),
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
          ],
        ),
      ),
    );
  }
}