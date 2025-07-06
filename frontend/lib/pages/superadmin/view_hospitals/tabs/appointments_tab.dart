// lib/pages/superadmin/view_hospitals/tabs/appointments_tab.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/models/appointment_data.dart';
import 'package:frontend/providers/appointment_provider.dart';
import 'package:frontend/providers/patient_provider.dart';
import 'package:frontend/providers/doctor_provider.dart';
import 'package:frontend/models/patient_data.dart';
import 'package:frontend/models/doctor_data.dart';
import 'package:intl/intl.dart';
import '../../../../shared/components/responsive_data_table.dart'
    show BetterPaginatedDataTable;

class HospitalAppointmentsTab extends StatefulWidget {
  final String token;
  final String hospitalId;
  const HospitalAppointmentsTab({
    super.key,
    required this.token,
    required this.hospitalId,
  });

  @override
  State<HospitalAppointmentsTab> createState() =>
      _HospitalAppointmentsTabState();
}

class _HospitalAppointmentsTabState extends State<HospitalAppointmentsTab> {
  final _provider = AppointmentProvider();
  final _patientProvider = PatientProvider();
  final _doctorProvider = DoctorProvider();
  bool _loading = false;
  List<AppointmentData> _list = [];
  List<PatientData> _patients = [];
  List<DoctorData> _doctors = [];

  @override
  void initState() {
    super.initState();
    _fetch();
    _fetchPatients();
    _fetchDoctors();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      // Fetch both past and upcoming appointments to show all appointments
      final pastList = await _provider.getFilteredHospitalAppointments(
        token: widget.token,
        hospitalId: widget.hospitalId,
        timeDirection: 'past',
        suspendfilter: 'all',
      );
      
      final upcomingList = await _provider.getFilteredHospitalAppointments(
        token: widget.token,
        hospitalId: widget.hospitalId,
        timeDirection: 'upcoming',
        suspendfilter: 'all',
      );
      
      // Combine both lists to show all appointments
      _list = [...pastList, ...upcomingList];
    } catch (e) {
      Fluttertoast.showToast(msg: 'Load appointments failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchPatients() async {
    try {
      _patients = await _patientProvider.getPatients(
        token: widget.token,
        hospitalId: widget.hospitalId,
        filter: 'all',
      );
    } catch (e) {
      print('Error fetching patients: $e');
    }
  }

  Future<void> _fetchDoctors() async {
    try {
      _doctors = await _doctorProvider.getDoctors(
        token: widget.token,
        hospitalId: widget.hospitalId,
        filter: 'all',
      );
    } catch (e) {
      print('Error fetching doctors: $e');
    }
  }

  String _getPatientName(String patientId) {
    final patient = _patients.firstWhere(
      (p) => p.id == patientId,
      orElse: () => PatientData(
        id: patientId,
        name: 'Unknown Patient',
        email: '',
        mobileNumber: '',
        persId: '',
        status: '',
        diagnosis: '',
        birthDate: DateTime.now(),
        medicalHistory: [],
        hospitalId: '',
        doctorIds: [],
        suspended: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return patient.name;
  }

  String _getDoctorName(String doctorId) {
    final doctor = _doctors.firstWhere(
      (d) => d.id == doctorId,
      orElse: () => DoctorData(
        id: doctorId,
        name: 'Unknown Doctor',
        email: '',
        mobileNumber: '',
        persId: '',
        birthDate: DateTime.now(),
        licenses: [],
        description: '',
        hospitalId: '',
        patients: [],
        schedule: [],
        suspended: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return doctor.name;
  }

  void _showUpsert([AppointmentData? existing]) {
    final formKey = GlobalKey<FormState>();
    String patientId = existing?.patientId ?? '';
    String doctorId  = existing?.doctorId  ?? '';
    String startIso  = existing != null ? existing.start.toIso8601String() : '';
    String endIso    = existing != null ? existing.end.toIso8601String()   : '';
    String purpose   = existing?.purpose   ?? '';
    String status    = existing?.status    ?? '';
    bool suspended   = existing?.suspended ?? false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(existing == null ? Icons.event_available : Icons.edit, color: const Color(0xFFEC407A)),
              const SizedBox(width: 10),
              Text(existing == null ? 'Add Appointment' : 'Edit Appointment', 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                    initialValue: patientId,
                    decoration: const InputDecoration(
                      labelText: 'Patient ID',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Patient ID' : null,
                    onSaved: (v) => patientId = v!.trim(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: doctorId,
                    decoration: const InputDecoration(
                      labelText: 'Doctor ID',
                      prefixIcon: Icon(Icons.local_hospital),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Doctor ID' : null,
                    onSaved: (v) => doctorId = v!.trim(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: startIso,
                    decoration: const InputDecoration(
                      labelText: 'Start Date/Time (ISO-8601)',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 2024-01-15T09:00:00Z',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Start Date/Time' : null,
                    onSaved: (v) => startIso = v!.trim(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: endIso,
                    decoration: const InputDecoration(
                      labelText: 'End Date/Time (ISO-8601)',
                      prefixIcon: Icon(Icons.schedule),
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 2024-01-15T10:00:00Z',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter End Date/Time' : null,
                    onSaved: (v) => endIso = v!.trim(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: purpose,
                    decoration: const InputDecoration(
                      labelText: 'Purpose',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Purpose' : null,
                    onSaved: (v) => purpose = v!.trim(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.info),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Status' : null,
                    onSaved: (v) => status = v!.trim(),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Text('Suspended?'),
                    const SizedBox(width: 10),
                    Checkbox(
                      value: suspended,
                      onChanged: (v) => setDialogState(() => suspended = v ?? false),
                      activeColor: const Color(0xFFEC407A),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(existing == null ? 'Add Appointment' : 'Save Appointment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC407A),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                formKey.currentState!.save();
                Navigator.pop(context);

                setState(() => _loading = true);
                try {
                  if (existing == null) {
                    // FIX: parse ISO→DateTime for createAppointment
                    await _provider.createAppointment(
                      token: widget.token,
                      patientId: patientId,
                      doctorId: doctorId,
                      start: DateTime.parse(startIso),
                      end: DateTime.parse(endIso),
                      purpose: purpose,
                      status: status,
                      suspended: suspended,
                    );
                    Fluttertoast.showToast(msg: 'Appointment created.');
                  } else {
                    await _provider.updateAppointment(
                      token: widget.token,
                      appointmentId: existing.id,
                      updatedFields: {
                        'patient': patientId,
                        'doctor': doctorId,
                        'start': startIso,
                        'end': endIso,
                        'purpose': purpose,
                        'status': status,
                        'suspended': suspended,
                      },
                    );
                    Fluttertoast.showToast(msg: 'Appointment updated.');
                  }
                  await _fetch();
                  await _fetchPatients();
                  await _fetchDoctors();
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Save failed: $e');
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _delete(String id) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Appointment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Yes')),
        ],
      ),
    ).then((ok) async {
      if (ok != true) return;
      setState(() => _loading = true);
      try {
        await _provider.deleteAppointment(
          token: widget.token,
          appointmentId: id,
        );
        Fluttertoast.showToast(msg: 'Appointment deleted.');
        await _fetch();
        await _fetchPatients();
        await _fetchDoctors();
      } catch (e) {
        Fluttertoast.showToast(msg: 'Delete failed: $e');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final df = DateFormat('yyyy-MM-dd HH:mm');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            ElevatedButton.icon(
              onPressed: () => _showUpsert(),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC407A),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                _fetch();
                _fetchPatients();
                _fetchDoctors();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC407A),
                foregroundColor: Colors.white,
              ),
            ),
          ]),
        ),
        Expanded(
          child: _list.isEmpty
              ? const Center(child: Text('No upcoming appointments.'))
              : BetterPaginatedDataTable(
                  themeColor: const Color(0xFFEC407A),
                  rowsPerPage: 10,
                  columns: const [
                    DataColumn(label: Text('Patient')),
                    DataColumn(label: Text('Doctor')),
                    DataColumn(label: Text('Start')),
                    DataColumn(label: Text('End')),
                    DataColumn(label: Text('Purpose')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _list.map((a) => DataRow(cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        constraints: const BoxConstraints(
                          minWidth: 150,
                          maxWidth: 200,
                        ),
                        child: Text(
                          _getPatientName(a.patientId),
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
                          minWidth: 150,
                          maxWidth: 200,
                        ),
                        child: Text(
                          _getDoctorName(a.doctorId),
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
                          minWidth: 150,
                          maxWidth: 180,
                        ),
                        child: Text(
                          df.format(a.start),
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
                          minWidth: 150,
                          maxWidth: 180,
                        ),
                        child: Text(
                          df.format(a.end),
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
                          a.purpose,
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showUpsert(a),
                              tooltip: 'Edit Appointment',
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _delete(a.id),
                              tooltip: 'Delete Appointment',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ])).toList(),
                ),
        ),
      ],
    );
  }


}