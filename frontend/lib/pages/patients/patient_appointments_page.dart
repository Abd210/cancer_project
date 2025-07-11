import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_data.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/patient_provider.dart';
import '../../models/doctor_data.dart';
import '../../models/patient_data.dart';
import 'package:frontend/main.dart' show Logger;
import '../../../shared/components/loading_indicator.dart';
import '../../providers/hospital_provider.dart';
import '../../models/hospital_data.dart';

class PatientAppointmentsPage extends StatefulWidget {
  final String token;
  final String patientId;

  const PatientAppointmentsPage({
    Key? key,
    required this.token,
    required this.patientId,
  }) : super(key: key);

  @override
  State<PatientAppointmentsPage> createState() =>
      _PatientAppointmentsPageState();
}

class _PatientAppointmentsPageState extends State<PatientAppointmentsPage> {
  final AppointmentProvider _appointmentProvider = AppointmentProvider();
  final DoctorProvider _doctorProvider = DoctorProvider();
  final PatientProvider _patientProvider = PatientProvider();
  final HospitalProvider _hospitalProvider = HospitalProvider();

  List<DoctorData> _doctorList = [];
  PatientData? _patientData;
  HospitalData? _hospitalData;
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedDateRange = 'all';
  String _selectedStatus = 'all';
  List<AppointmentData> _upcomingAppointments = [];
  List<AppointmentData> _historyAppointments = [];
  String? _errorMessage;
  ScaffoldMessengerState? _scaffoldMessenger;

  void _showToast(String message) {
    _scaffoldMessenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
    _fetchPatientAndDoctors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.patientId.isEmpty || widget.token.isEmpty) {
        throw Exception('Missing patientId or token');
      }

      final allAppointments =
          await _appointmentProvider.getAppointmentsForPatient(
        token: widget.token,
        patientId: widget.patientId,
        suspendfilter: 'all',
      );

      // Split appointments into upcoming and history
      final now = DateTime.now();
      _upcomingAppointments = allAppointments
          .where((a) => a.start.isAfter(now))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));

      _historyAppointments = allAppointments
          .where((a) => a.start.isBefore(now))
          .toList()
        ..sort((a, b) => b.start.compareTo(a.start));

      // Apply filters
      _applyFilters();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      Logger.log('Error in _fetchAppointments: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load appointments: $e';
          _isLoading = false;
        });
        _showToast('Failed to load appointments: $e');
      }
    }
  }

  Future<void> _fetchPatientAndDoctors() async {
    try {
      // Fetch patient data (for doctorIds & hospital info)
      final patients = await _patientProvider.getPatients(
        token: widget.token,
        patientId: widget.patientId,
      );
      if (patients.isNotEmpty) {
        _patientData = patients.first;
        // Fetch hospital data if patient has hospitalId
        if (_patientData!.hospitalId.isNotEmpty) {
          final hospitals = await _hospitalProvider.getHospitals(
            token: widget.token,
            hospitalId: _patientData!.hospitalId,
          );
          if (hospitals.isNotEmpty) {
            _hospitalData = hospitals.first;
          }
        }
      }

      // Fetch doctors (filter later)
      final allDoctors = await _doctorProvider.getDoctors(
        token: widget.token,
        filter: 'all',
      );

      if (_patientData != null) {
        _doctorList = allDoctors
            .where((doc) => _patientData!.doctorIds.contains(doc.id))
            .toList();
      } else {
        _doctorList = [];
      }
      if (_doctorList.isEmpty && _patientData != null && _patientData!.doctorIds.isNotEmpty) {
        List<DoctorData> fallbackList = [];
        for (final docId in _patientData!.doctorIds) {
          try {
            final docs = await _doctorProvider.getDoctors(
              token: widget.token,
              doctorId: docId,
            );
            if (docs.isNotEmpty) fallbackList.addAll(docs);
          } catch (_) {}
        }
        if (fallbackList.isNotEmpty) {
          _doctorList = fallbackList;
        }
      }
      setState(() {});
    } catch (e) {
      Logger.log('Error fetching patient/doctors: $e');
    }
  }

  void _applyFilters() {
    var filteredUpcoming = _upcomingAppointments;
    var filteredHistory = _historyAppointments;

    // Date range filter
    if (_selectedDateRange != 'all') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      switch (_selectedDateRange) {
        case 'today':
          final tomorrow = today.add(const Duration(days: 1));
          filteredHistory = filteredHistory
              .where(
                  (a) => a.start.isAfter(today) && a.start.isBefore(tomorrow))
              .toList();
          filteredUpcoming = filteredUpcoming
              .where(
                  (a) => a.start.isAfter(today) && a.start.isBefore(tomorrow))
              .toList();
          break;
        case 'week':
          final weekLater = today.add(const Duration(days: 7));
          filteredHistory = filteredHistory
              .where(
                  (a) => a.start.isAfter(today) && a.start.isBefore(weekLater))
              .toList();
          filteredUpcoming = filteredUpcoming
              .where(
                  (a) => a.start.isAfter(today) && a.start.isBefore(weekLater))
              .toList();
          break;
        case 'month':
          final monthLater = DateTime(today.year, today.month + 1, today.day);
          filteredHistory = filteredHistory
              .where(
                  (a) => a.start.isAfter(today) && a.start.isBefore(monthLater))
              .toList();
          filteredUpcoming = filteredUpcoming
              .where(
                  (a) => a.start.isAfter(today) && a.start.isBefore(monthLater))
              .toList();
          break;
      }
    }

    // Status filter
    if (_selectedStatus != 'all') {
      filteredHistory =
          filteredHistory.where((a) => a.status == _selectedStatus).toList();
      filteredUpcoming =
          filteredUpcoming.where((a) => a.status == _selectedStatus).toList();
    }

    // Search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredHistory = filteredHistory
          .where((a) =>
              a.doctorName.toLowerCase().contains(query) ||
              a.doctorEmail.toLowerCase().contains(query) ||
              a.purpose.toLowerCase().contains(query))
          .toList();
      filteredUpcoming = filteredUpcoming
          .where((a) =>
              a.doctorName.toLowerCase().contains(query) ||
              a.doctorEmail.toLowerCase().contains(query) ||
              a.purpose.toLowerCase().contains(query))
          .toList();
    }

    setState(() {
      _upcomingAppointments = filteredUpcoming;
      _historyAppointments = filteredHistory;
    });
  }

  Widget _buildAppointmentList(
      List<AppointmentData> appointments, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: appointments.isEmpty
              ? Center(child: Text('No $title appointments found'))
              : ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ListTile(
                        title: Text(appointment.doctorName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Date: ${DateFormat('MMM dd, yyyy').format(appointment.start)}'),
                            Text(
                                'Time: ${DateFormat('HH:mm').format(appointment.start)} - ${DateFormat('HH:mm').format(appointment.end)}'),
                            Text('Purpose: ${appointment.purpose}'),
                            Text('Status: ${appointment.status}'),
                          ],
                        ),
                        trailing: (appointment.status == 'scheduled' || appointment.status == 'pending')
                            ? IconButton(
                                icon:
                                    const Icon(Icons.cancel, color: Colors.red),
                                tooltip: 'Cancel Appointment',
                                onPressed: () => _confirmCancel(appointment),
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmCancel(AppointmentData appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Appointment'),
        content: Text(
          'Are you sure you want to cancel your appointment with ${appointment.doctorName} on ${DateFormat('MMM dd, yyyy HH:mm').format(appointment.start)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await _cancelAppointment(appointment.id);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    setState(() => _isLoading = true);
    try {
      await _appointmentProvider.cancelAppointment(
        token: widget.token,
        appointmentId: appointmentId,
      );
      _showToast('Appointment cancelled');
      await _fetchAppointments();
    } catch (e) {
      _showToast('Failed to cancel appointment: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDateRange,
                        decoration: const InputDecoration(
                          labelText: 'Date Range',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('All Time')),
                          DropdownMenuItem(
                              value: 'today', child: Text('Today')),
                          DropdownMenuItem(
                              value: 'week', child: Text('This Week')),
                          DropdownMenuItem(
                              value: 'month', child: Text('This Month')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDateRange = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'declined', child: Text('Declined')),
                          DropdownMenuItem(value: 'completed', child: Text('Completed')),
                          DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : (_upcomingAppointments.isEmpty &&
                            _historyAppointments.isEmpty)
                        ? const Center(child: Text('No appointments found'))
                        : Row(
                            children: [
                              Expanded(
                                child: _buildAppointmentList(
                                    _upcomingAppointments, 'Upcoming'),
                              ),
                              const VerticalDivider(),
                              Expanded(
                                child: _buildAppointmentList(
                                    _historyAppointments, 'History'),
                              ),
                            ],
                          ),
          ),
          // Book appointment button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Book Appointment'),
                onPressed: _isLoading ? null : _showBookAppointmentDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey : null,
                ),
              ),
            ),
          ),
        ],
    );
  }

  void _showBookAppointmentDialog() {
    if (_patientData == null) {
      _showToast('Patient data not loaded yet');
      return;
    }

    final formKey = GlobalKey<FormState>();

    String? selectedDoctorId;
    DateTime selectedStartDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedStartTime = TimeOfDay(hour: 9, minute: 0);
    DateTime selectedEndDate = selectedStartDate.add(const Duration(hours: 1));
    TimeOfDay selectedEndTime = TimeOfDay(hour: 10, minute: 0);
    String purpose = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final hasDoctors = _doctorList.isNotEmpty;
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.calendar_month, color: const Color(0xFFEC407A)),
                const SizedBox(width: 10),
                const Text('Book Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      // Hospital Info Section (top)
                      if (_hospitalData != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Hospital',
                              prefixIcon: Icon(Icons.local_hospital),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _hospitalData!.name,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      // Doctor Section
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
                            Text('Doctor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFEC407A))),
                            const SizedBox(height: 16),
                            if (!hasDoctors)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'No doctors are currently assigned to you. Please contact your hospital or admin to be assigned a doctor before booking an appointment.',
                                  style: TextStyle(color: Colors.red.shade700, fontSize: 15),
                                ),
                              )
                            else
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Select Doctor',
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(),
                                ),
                                value: selectedDoctorId,
                                items: _doctorList.map((doc) {
                                  return DropdownMenuItem<String>(
                                    value: doc.id,
                                    child: Text(doc.name),
                                  );
                                }).toList(),
                                validator: (val) => val == null || val.isEmpty ? 'Choose a doctor' : null,
                                onChanged: (val) {
                                  setDialogState(() {
                                    selectedDoctorId = val;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Appointment Details
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
                            Text('Appointment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFEC407A))),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Purpose',
                                prefixIcon: Icon(Icons.description),
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              validator: (v) => v == null || v.isEmpty ? 'Provide purpose' : null,
                              onSaved: (v) => purpose = v!.trim(),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Start Date & Time',
                                      prefixIcon: Icon(Icons.access_time),
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Text('${DateFormat('yyyy-MM-dd').format(selectedStartDate)} ${selectedStartTime.format(context)}'),
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
                                          final startDT = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                                          final endDT = startDT.add(const Duration(hours: 1));
                                          selectedEndDate = endDT;
                                          selectedEndTime = TimeOfDay.fromDateTime(endDT);
                                        });
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'End Date & Time',
                                      prefixIcon: Icon(Icons.access_time),
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Text('${DateFormat('yyyy-MM-dd').format(selectedEndDate)} ${selectedEndTime.format(context)}'),
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
                                        final startDT = DateTime(selectedStartDate.year, selectedStartDate.month, selectedStartDate.day, selectedStartTime.hour, selectedStartTime.minute);
                                        final potentialEnd = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                                        if (potentialEnd.isAfter(startDT)) {
                                          setDialogState(() {
                                            selectedEndDate = pickedDate;
                                            selectedEndTime = pickedTime;
                                          });
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: !hasDoctors
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        formKey.currentState!.save();

                        if (selectedDoctorId == null) {
                          _showToast('Please select a doctor');
                          return;
                        }

                        final startDT = DateTime(selectedStartDate.year, selectedStartDate.month, selectedStartDate.day, selectedStartTime.hour, selectedStartTime.minute);
                        final endDT = DateTime(selectedEndDate.year, selectedEndDate.month, selectedEndDate.day, selectedEndTime.hour, selectedEndTime.minute);

                        if (startDT.isBefore(DateTime.now())) {
                          _showToast('Start time must be in the future');
                          return;
                        }
                        if (!endDT.isAfter(startDT)) {
                          _showToast('End time must be after start');
                          return;
                        }

                        Navigator.pop(ctx);
                        setState(() => _isLoading = true);
                        try {
                          await _appointmentProvider.createAppointment(
                            token: widget.token,
                            patientId: widget.patientId,
                            doctorId: selectedDoctorId!,
                            start: startDT,
                            end: endDT,
                            purpose: purpose,
                            status: 'pending',
                            suspended: false,
                          );
                          _showToast('Appointment request sent');
                          await _fetchAppointments();
                        } catch (e) {
                          _showToast('Failed to create appointment: $e');
                          setState(() => _isLoading = false);
                        }
                      },
                child: const Text('Book'),
              ),
            ],
          );
        },
      ),
    );
  }
}
