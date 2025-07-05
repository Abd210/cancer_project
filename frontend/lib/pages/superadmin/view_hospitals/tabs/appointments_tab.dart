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
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Appointment' : 'Edit Appointment'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _txt('Patient ID',       initial: patientId, save: (v) => patientId = v),
              _txt('Doctor ID',        initial: doctorId,  save: (v) => doctorId = v),
              _txt('Start (ISO-8601)', initial: startIso,  save: (v) => startIso = v),
              _txt('End (ISO-8601)',   initial: endIso,    save: (v) => endIso = v),
              _txt('Purpose',          initial: purpose,  save: (v) => purpose = v),
              _txt('Status',           initial: status,   save: (v) => status = v),
              Row(children: [
                const Text('Suspended?'),
                Checkbox(
                  value: suspended,
                  onChanged: (v) => setState(() => suspended = v ?? false),
                ),
              ]),
            ]),
          ),
        ),
        actions: [
          TextButton(
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
            child: const Text('Save'),
          ),
        ],
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
            ),
          ]),
        ),
        Expanded(
          child: _list.isEmpty
              ? const Center(child: Text('No upcoming appointments.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Patient')),
                      DataColumn(label: Text('Doctor')),
                      DataColumn(label: Text('Start')),
                      DataColumn(label: Text('End')),
                      DataColumn(label: Text('Purpose')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _list.map((a) => DataRow(cells: [
                      DataCell(Text(_getPatientName(a.patientId))),
                      DataCell(Text(_getDoctorName(a.doctorId))),
                      DataCell(Text(df.format(a.start))),
                      DataCell(Text(df.format(a.end))),
                      DataCell(Text(a.purpose)),
                      DataCell(Row(children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showUpsert(a),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _delete(a.id),
                        ),
                      ])),
                    ])).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _txt(String label,
      {String initial = '',
      bool obscure = false,
      required void Function(String) save}) {
    return TextFormField(
      initialValue: initial,
      obscureText: obscure,
      decoration: InputDecoration(labelText: label),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter $label' : null,
      onSaved: (v) => save(v!.trim()),
    );
  }
}