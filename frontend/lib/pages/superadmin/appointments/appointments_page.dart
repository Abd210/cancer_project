// lib/pages/superadmin/view_appointments/view_appointments_page.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import 'package:frontend/providers/appointment_provider.dart';
import 'package:frontend/models/appointment_data.dart';

import '../../../shared/components/loading_indicator.dart';
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

  bool _isLoading = false;
  String _searchQuery = '';

  // For GET filtering
  String _suspendFilter = 'unsuspended';
  String _filterByRole = ''; // Default to empty to get all initially
  String _filterById = '';

  List<AppointmentData> _appointmentList = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final list = await _appointmentProvider.getAppointmentsHistory(
        token: widget.token,
        suspendfilter: _suspendFilter,
        filterByRole: _filterByRole.isEmpty ? null : _filterByRole, // Pass null if empty
        filterById: _filterById.isEmpty ? null : _filterById,       // Pass null if empty
      );
      setState(() {
        _appointmentList = list;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${list.length} appointments')),
        );
      }
    } catch (e) {
      print('Error fetching appointments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load appointments: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddAppointmentDialog() {
    final formKey = GlobalKey<FormState>();
    String patientId = '';
    String doctorId = '';
    DateTime selectedStartDate = DateTime.now();
    TimeOfDay selectedStartTime = TimeOfDay.now();
    DateTime selectedEndDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedEndTime = TimeOfDay.fromDateTime(selectedEndDate);
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
                  mainAxisSize: MainAxisSize.min, // Important for SingleChildScrollView
                  children: [
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Patient ID'),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter patient ID'
                          : null,
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
                    // Start Date & Time Picker
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                              'Start: ${DateFormat("yyyy-MM-dd").format(selectedStartDate)} ${selectedStartTime.format(ctx)}'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: ctx,
                              initialDate: selectedStartDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              final pickedTime = await showTimePicker(
                                context: ctx,
                                initialTime: selectedStartTime,
                              );
                              if (pickedTime != null) {
                                setStateDialog(() {
                                  selectedStartDate = pickedDate;
                                  selectedStartTime = pickedTime;
                                  // Ensure end time is after start time
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
                                  if (endDateTime.isBefore(startDateTime)) {
                                    selectedEndDate = selectedStartDate;
                                    selectedEndTime = TimeOfDay.fromDateTime(
                                        startDateTime.add(const Duration(hours: 1)));
                                  }
                                });
                              }
                            }
                          },
                          child: const Text('Select Start'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // End Date & Time Picker
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                              'End: ${DateFormat("yyyy-MM-dd").format(selectedEndDate)} ${selectedEndTime.format(ctx)}'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: ctx,
                              initialDate: selectedEndDate,
                              firstDate: selectedStartDate, // Can't end before start date
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              final pickedTime = await showTimePicker(
                                context: ctx,
                                initialTime: selectedEndTime,
                              );
                              if (pickedTime != null) {
                                // Validate end time is after start time
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
                                  setStateDialog(() {
                                    selectedEndDate = pickedDate;
                                    selectedEndTime = pickedTime;
                                  });
                                } else {
                                  Fluttertoast.showToast(
                                      msg: 'End time must be after start time.');
                                }
                              }
                            }
                          },
                          child: const Text('Select End'),
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

                final finalStartDateTime = DateTime(
                  selectedStartDate.year,
                  selectedStartDate.month,
                  selectedStartDate.day,
                  selectedStartTime.hour,
                  selectedStartTime.minute,
                );
                final finalEndDateTime = DateTime(
                  selectedEndDate.year,
                  selectedEndDate.month,
                  selectedEndDate.day,
                  selectedEndTime.hour,
                  selectedEndTime.minute,
                );

                setState(() => _isLoading = true);
                try {
                  await _appointmentProvider.createAppointment(
                    token: widget.token,
                    patientId: patientId,
                    doctorId: doctorId,
                    start: finalStartDateTime,
                    end: finalEndDateTime,
                    purpose: purpose,
                    status: status,
                    suspended: suspended,
                  );
                  await _fetchAppointments();
                  Fluttertoast.showToast(
                      msg: 'Appointment added successfully.');
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

  void _showEditAppointmentDialog(AppointmentData appt) {
    final formKey = GlobalKey<FormState>();

    String patientId = appt.patientId;
    String doctorId = appt.doctorId;
    DateTime selectedStartDate = appt.start;
    TimeOfDay selectedStartTime = TimeOfDay.fromDateTime(appt.start);
    DateTime selectedEndDate = appt.end;
    TimeOfDay selectedEndTime = TimeOfDay.fromDateTime(appt.end);
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: patientId,
                      decoration:
                          const InputDecoration(labelText: 'Patient ID'),
                      onSaved: (val) => patientId = val?.trim() ?? '',
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: doctorId,
                      decoration: const InputDecoration(labelText: 'Doctor ID'),
                      onSaved: (val) => doctorId = val?.trim() ?? '',
                    ),
                    const SizedBox(height: 10),
                    // Start Date & Time Picker
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                              'Start: ${DateFormat("yyyy-MM-dd").format(selectedStartDate)} ${selectedStartTime.format(ctx)}'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: ctx,
                              initialDate: selectedStartDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              final pickedTime = await showTimePicker(
                                context: ctx,
                                initialTime: selectedStartTime,
                              );
                              if (pickedTime != null) {
                                setStateDialog(() {
                                  selectedStartDate = pickedDate;
                                  selectedStartTime = pickedTime;
                                  // Ensure end time is after start time
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
                                  if (endDateTime.isBefore(startDateTime)) {
                                    selectedEndDate = selectedStartDate;
                                    selectedEndTime = TimeOfDay.fromDateTime(
                                        startDateTime.add(const Duration(hours: 1)));
                                  }
                                });
                              }
                            }
                          },
                          child: const Text('Select Start'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // End Date & Time Picker
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                              'End: ${DateFormat("yyyy-MM-dd").format(selectedEndDate)} ${selectedEndTime.format(ctx)}'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: ctx,
                              initialDate: selectedEndDate,
                              firstDate: selectedStartDate, // Can't end before start date
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              final pickedTime = await showTimePicker(
                                context: ctx,
                                initialTime: selectedEndTime,
                              );
                              if (pickedTime != null) {
                                // Validate end time is after start time
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
                                  setStateDialog(() {
                                    selectedEndDate = pickedDate;
                                    selectedEndTime = pickedTime;
                                  });
                                } else {
                                  Fluttertoast.showToast(
                                      msg: 'End time must be after start time.');
                                }
                              }
                            }
                          },
                          child: const Text('Select End'),
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

              final finalStartDateTime = DateTime(
                selectedStartDate.year,
                selectedStartDate.month,
                selectedStartDate.day,
                selectedStartTime.hour,
                selectedStartTime.minute,
              );
              final finalEndDateTime = DateTime(
                selectedEndDate.year,
                selectedEndDate.month,
                selectedEndDate.day,
                selectedEndTime.hour,
                selectedEndTime.minute,
              );

              setState(() => _isLoading = true);
              try {
                final updatedFields = {
                  "patient": patientId,
                  "doctor": doctorId,
                  "start": finalStartDateTime.toIso8601String(),
                  "end": finalEndDateTime.toIso8601String(),
                  "purpose": purpose,
                  "status": status,
                  "suspended": suspended,
                };

                await _appointmentProvider.updateAppointment(
                  token: widget.token,
                  appointmentId: appt.id,
                  updatedFields: updatedFields,
                );
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
      return const Center(child: LoadingIndicator());
    }

    final filtered = _appointmentList.where((appt) {
      final q = _searchQuery.toLowerCase();
      // Check against relevant fields, handle potential nulls if necessary
      return appt.id.toLowerCase().contains(q) ||
          appt.status.toLowerCase().contains(q) ||
          (appt.patientName?.toLowerCase().contains(q) ?? false) || // Use patientName if available
          (appt.doctorName?.toLowerCase().contains(q) ?? false) || // Use doctorName if available
          appt.patientId.toLowerCase().contains(q) || // Fallback to IDs
          appt.doctorId.toLowerCase().contains(q) ||
          appt.purpose.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter and Search Row
            Row(
              children: [
                // Suspend Filter Dropdown
                Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 8),
                  child: DropdownButtonFormField<String>(
                    value: _suspendFilter,
                    decoration: const InputDecoration(
                      labelText: 'Suspend Filter',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'unsuspended', child: Text('Active')),
                      DropdownMenuItem(
                          value: 'suspended', child: Text('Suspended')),
                      DropdownMenuItem(
                          value: 'all', child: Text('All')),
                    ],
                    onChanged: (val) async {
                      setState(() => _suspendFilter = val ?? 'unsuspended');
                      await _fetchAppointments();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Role Filter Dropdown
                Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 8),
                  child: DropdownButtonFormField<String>(
                    value: _filterByRole.isEmpty ? null : _filterByRole, // Handle empty value
                    hint: const Text('Role'),
                    decoration: const InputDecoration(
                      labelText: 'Role Filter',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Any Role')),
                      DropdownMenuItem(value: 'patient', child: Text('Patient')),
                      DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                    ],
                    onChanged: (val) {
                       setState(() => _filterByRole = val ?? '');
                       // Optionally trigger fetch immediately or wait for ID input
                    },
                  ),
                ),
                // ID Filter Text Field
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Filter by ID',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),
                      initialValue: _filterById,
                      onChanged: (val) => setState(() => _filterById = val.trim()),
                      onEditingComplete: _fetchAppointments, // Fetch when done editing ID
                    ),
                  ),
                ),
                // Search Field
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search Appointments',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Add Button
                ElevatedButton.icon(
                  onPressed: _showAddAppointmentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
                const SizedBox(width: 10),
                // Refresh Button
                ElevatedButton.icon(
                  onPressed: _fetchAppointments,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Data Table
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No appointments found.'))
                  : BetterPaginatedDataTable(
                      themeColor: const Color(0xFFEC407A), // Pinkish color
                      rowsPerPage: 10, // Show 10 rows per page
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
                      rows: filtered.map((appt) {
                        return DataRow(cells: [
                          DataCell(Text(appt.id)),
                          DataCell(Text(appt.patientName ?? appt.patientId)), // Show name or ID
                          DataCell(Text(appt.doctorName ?? appt.doctorId)),   // Show name or ID
                          DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(appt.start))),
                          DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(appt.end))),
                          DataCell(Text(appt.purpose)),
                          DataCell(Text(appt.status)),
                          DataCell(Text(appt.suspended.toString())),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
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
