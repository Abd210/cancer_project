// lib/pages/superadmin/view_appointments/view_appointments_page.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import 'package:frontend/providers/appointment_provider.dart';
import 'package:frontend/models/appointment_data.dart';

// Shared
import '../../../shared/components/loading_indicator.dart';
import '../../../shared/components/responsive_data_table.dart' show BetterDataTable;

class AppointmentsPage extends StatefulWidget {
  final String token;
  const AppointmentsPage({Key? key, required this.token}) : super(key: key);

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final AppointmentProvider _appointmentProvider = AppointmentProvider();

  bool _isLoading = false;
  String _searchQuery = '';

  // For the GET filtering
  String _suspendFilter = 'unsuspended'; // or 'suspended'
  String _filterByRole = 'patient'; // or 'doctor', 'admin', etc.
  String _filterById = '67731e4f23997df9d739418a'; // you can change as needed

  List<AppointmentData> _appointmentList = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  /// The main GET call => /api/appointment/history with the custom headers
  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);

    try {
      final list = await _appointmentProvider.getAppointmentsHistory(
        token: widget.token,
        suspendfilter: _suspendFilter,
        filterbyrole: _filterByRole,
        filterbyid: _filterById,
      );
      setState(() {
        _appointmentList = list;
      });

      Fluttertoast.showToast(msg: 'Loaded ${list.length} appointments');
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      Fluttertoast.showToast(msg: 'Failed to load appointments: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Example: Create a new appointment
  void _showAddAppointmentDialog() {
    final formKey = GlobalKey<FormState>();
    String patientId = '';
    String doctorId = '';
    DateTime selectedDate = DateTime.now();
    String purpose = 'New Purpose';
    String status = 'scheduled';
    bool suspended = false;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Appointment'),
        content: Form(
          key: formKey,
          child: StatefulBuilder(
            builder: (ctx, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Patient ID'),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter patient ID' : null,
                      onSaved: (val) => patientId = val!.trim(),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Doctor ID'),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter doctor ID' : null,
                      onSaved: (val) => doctorId = val!.trim(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Date: ${DateFormat("yyyy-MM-dd").format(selectedDate)}'),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: const Text('Select Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Purpose'),
                      initialValue: purpose,
                      onSaved: (val) => purpose = val?.trim() ?? '',
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Status'),
                      initialValue: status,
                      onSaved: (val) => status = val?.trim() ?? 'scheduled',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Suspended?'),
                        Checkbox(
                          value: suspended,
                          onChanged: (val) {
                            setStateDialog(() {
                              suspended = val ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(ctx);

                setState(() => _isLoading = true);
                try {
                  await _appointmentProvider.createAppointment(
                    token: widget.token,
                    patientId: patientId,
                    doctorId: doctorId,
                    date: selectedDate,
                    purpose: purpose,
                    status: status,
                    suspended: suspended,
                  );

                  // Re-fetch
                  await _fetchAppointments();
                  Fluttertoast.showToast(msg: 'Appointment added successfully.');
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Failed to add: $e');
                } finally {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Edit Appointment (PUT)
  void _showEditAppointmentDialog(AppointmentData appt) {
    final formKey = GlobalKey<FormState>();

    String patientId = appt.patientId;
    String doctorId = appt.doctorId;
    DateTime selectedDate = appt.date;
    String purpose = appt.purpose;
    String status = appt.status;
    bool suspended = appt.suspended;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Appointment'),
        content: Form(
          key: formKey,
          child: StatefulBuilder(
            builder: (ctx, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: patientId,
                      decoration: const InputDecoration(labelText: 'Patient ID'),
                      onSaved: (val) => patientId = val?.trim() ?? '',
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: doctorId,
                      decoration: const InputDecoration(labelText: 'Doctor ID'),
                      onSaved: (val) => doctorId = val?.trim() ?? '',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Date: ${DateFormat("yyyy-MM-dd").format(selectedDate)}'),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: const Text('Select Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: purpose,
                      decoration: const InputDecoration(labelText: 'Purpose'),
                      onSaved: (val) => purpose = val?.trim() ?? '',
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      onSaved: (val) => status = val?.trim() ?? '',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Suspended?'),
                        Checkbox(
                          value: suspended,
                          onChanged: (val) {
                            setStateDialog(() {
                              suspended = val ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              formKey.currentState!.save();
              Navigator.pop(ctx);

              setState(() => _isLoading = true);
              try {
                final updatedFields = {
                  "patient": patientId,
                  "doctor": doctorId,
                  "appointment_date": DateFormat("yyyy-MM-dd").format(selectedDate),
                  "purpose": purpose,
                  "status": status,
                  "suspended": suspended,
                };

                await _appointmentProvider.updateAppointment(
                  token: widget.token,
                  appointmentId: appt.id,
                  updatedFields: updatedFields,
                );

                // Re-fetch
                await _fetchAppointments();
                Fluttertoast.showToast(msg: 'Appointment updated.');
              } catch (e) {
                Fluttertoast.showToast(msg: 'Failed to update: $e');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// DELETE
  void _deleteAppointment(String apptId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _appointmentProvider.deleteAppointment(
                  token: widget.token,
                  appointmentId: apptId,
                );
                await _fetchAppointments();
                Fluttertoast.showToast(msg: 'Deleted.');
              } catch (e) {
                Fluttertoast.showToast(msg: 'Failed to delete: $e');
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
      return const LoadingIndicator();
    }

    // We'll show a row that includes:
    //   - suspendfilter dropdown
    //   - filterbyrole text field
    //   - filterbyid text field
    //   - a "Fetch" button
    //   - a "Search" text field for local filtering
    final filtered = _appointmentList.where((appt) {
      final q = _searchQuery.toLowerCase();
      return appt.id.toLowerCase().contains(q) ||
          appt.status.toLowerCase().contains(q) ||
          appt.patientName.toLowerCase().contains(q) ||
          appt.doctorName.toLowerCase().contains(q) ||
          appt.purpose.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments (History)'),
        actions: [
          IconButton(
            onPressed: _showAddAppointmentDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Add Appointment',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1) Filter row
            Row(
              children: [
                // suspendfilter
                Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 8),
                  child: DropdownButtonFormField<String>(
                    value: _suspendFilter,
                    decoration: const InputDecoration(labelText: 'SuspendFilter'),
                    items: const [
                      DropdownMenuItem(value: 'unsuspended', child: Text('unsuspended')),
                      DropdownMenuItem(value: 'suspended', child: Text('suspended')),
                    ],
                    onChanged: (val) => setState(() => _suspendFilter = val ?? 'unsuspended'),
                  ),
                ),
                const SizedBox(width: 8),

                // filterbyrole
                Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 8),
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'filterbyrole'),
                    initialValue: _filterByRole,
                    onChanged: (val) => _filterByRole = val.trim(),
                  ),
                ),

                // filterbyid
                Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 8),
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'filterbyid'),
                    initialValue: _filterById,
                    onChanged: (val) => _filterById = val.trim(),
                  ),
                ),

                ElevatedButton(
                  onPressed: _fetchAppointments,
                  child: const Text('Fetch'),
                ),

                const Spacer(),

                // local search
                Container(
                  width: 200,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search local',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2) Show table
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No appointments found.'))
                  : BetterDataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Patient Name')),
                        DataColumn(label: Text('Doctor Name')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Purpose')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: filtered.map((appt) {
                        return DataRow(cells: [
                          DataCell(Text(appt.id)),
                          DataCell(Text(appt.patientName)),
                          DataCell(Text(appt.doctorName)),
                          DataCell(Text(DateFormat('yyyy-MM-dd').format(appt.date))),
                          DataCell(Text(appt.purpose)),
                          DataCell(Text(appt.status)),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditAppointmentDialog(appt),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteAppointment(appt.id),
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
