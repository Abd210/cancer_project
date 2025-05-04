// // lib/pages/doctor/appointments/doctor_appointments_page.dart

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../providers/data_provider.dart';
// import '../../../models/appointment.dart';

// class DoctorAppointmentsPage extends StatelessWidget {
//   final String doctorId;

//   const DoctorAppointmentsPage({super.key, required this.doctorId});

//   @override
//   Widget build(BuildContext context) {
//     final dataProvider = Provider.of<DataProvider>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Appointments'),
//       ),
//       body: ListView.builder(
//         itemCount: dataProvider.getAppointmentsForDoctor(doctorId).length,
//         itemBuilder: (context, index) {
//           final appointment = dataProvider.getAppointmentsForDoctor(doctorId)[index];

//           return Card(
//             child: ListTile(
//               title: Text("Patient ID: ${appointment.patientId}"),
//               subtitle: Text("Date: ${appointment.dateTime}"),
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.edit, color: Colors.blue),
//                     onPressed: () {
//                       // Open a dialog to reschedule
//                       _showRescheduleDialog(context, dataProvider, appointment);
//                     },
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.delete, color: Colors.red),
//                     onPressed: () {
//                       // Cancel the appointment
//                       dataProvider.deleteAppointment(appointment.id);
//                       dataProvider.addAppointmentCancelledNotification(
//                         appointment.id,
//                         appointment.patientId,
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void _showRescheduleDialog(
//       BuildContext context, DataProvider dataProvider, Appointment appointment) {
//     final TextEditingController dateTimeController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Reschedule Appointment'),
//           content: TextField(
//             controller: dateTimeController,
//             decoration: const InputDecoration(
//               labelText: 'Enter new date and time',
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 final newDateTime = DateTime.parse(dateTimeController.text);
//                 dataProvider.updateAppointment(Appointment(
//                   id: appointment.id,
//                   patientId: appointment.patientId,
//                   doctorId: appointment.doctorId,
//                   dateTime: newDateTime,
//                   status: 'Rescheduled',
//                 ));
//                 dataProvider.addAppointmentRescheduledNotification(
//                   appointment.id,
//                   appointment.patientId,
//                   newDateTime,
//                 );
//                 Navigator.pop(context);
//               },
//               child: const Text('Reschedule'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:frontend/providers/appointment_provider.dart';
import 'package:frontend/models/appointment_data.dart';
import 'package:frontend/main.dart' show Logger;
import '../../../shared/components/loading_indicator.dart';
import '../../../providers/patient_provider.dart';
import '../../../pages/doctor/patients/patient_details_page.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  final String doctorId;
  final String token;

  const DoctorAppointmentsPage({
    Key? key,
    required this.doctorId,
    required this.token,
  }) : super(key: key);

  @override
  _DoctorAppointmentsPageState createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  final AppointmentProvider _appointmentProvider = AppointmentProvider();
  final PatientProvider _patientProvider = PatientProvider();

  bool _isLoading = false;
  String _searchQuery = '';
  bool _showFilters = false;
  List<AppointmentData> _upcomingAppointments = [];
  List<AppointmentData> _historyAppointments = [];
  Map<String, Map<String, String>> _patientInfoCache = {};
  String _selectedDateRange = 'all';
  String _selectedStatus = 'all';
  String? _errorMessage;

  String _filterByRole = 'doctor';
  String _filterById = '';

  late ScaffoldMessengerState _scaffoldMessenger;

  void _showToast(String message) {
    _scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    Logger.log(
        'DoctorAppointmentsPage.initState: doctorId=${widget.doctorId}, token length=${widget.token.length}');
    _filterById = widget.doctorId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAppointments();
    });
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _patientInfoCache.clear();
    });

    try {
      if (widget.doctorId.isEmpty || widget.token.isEmpty) {
        Logger.log(
            'Error: Missing doctorId or token. doctorId=${widget.doctorId}, token length=${widget.token.length}');
        throw Exception('Missing doctorId or token');
      }

      Logger.log(
          'Starting to fetch appointments for doctor ${widget.doctorId}');

      // Get past appointments (history)
      List<AppointmentData> historyList = [];
      try {
        Logger.log('Fetching history appointments...');
        historyList = await _appointmentProvider.getAppointmentsHistory(
          token: widget.token,
          suspendfilter: 'all',
          filterByRole: _filterByRole,
          filterById: _filterById,
        );
        Logger.log(
            'Successfully fetched ${historyList.length} history appointments');
      } catch (e) {
        Logger.log('Error fetching history appointments: $e');
      }

      // Get future appointments (upcoming)
      List<AppointmentData> upcomingList = [];
      try {
        Logger.log('Fetching upcoming appointments...');
        upcomingList = await _appointmentProvider.getUpcoming(
          token: widget.token,
          entityRole: _filterByRole,
          entityId: _filterById,
          suspendfilter: 'all',
        );
        Logger.log(
            'Successfully fetched ${upcomingList.length} upcoming appointments');
      } catch (e) {
        Logger.log('Error fetching upcoming appointments: $e');
      }

      // Fetch patient info for all appointments
      final allAppointments = [...historyList, ...upcomingList];
      final uniquePatientIds = allAppointments.map((a) => a.patientId).toSet();
      for (final patientId in uniquePatientIds) {
        try {
          final patient = await _patientProvider.getPatientById(
            token: widget.token,
            patientId: patientId,
          );
          _patientInfoCache[patientId] = {
            'name': patient.name,
            'email': patient.email,
          };
        } catch (e) {
          _patientInfoCache[patientId] = {
            'name': 'Unknown',
            'email': '',
          };
        }
      }

      if (!mounted) {
        Logger.log('Widget not mounted, returning early');
        return;
      }

      // Apply client-side filtering
      var filteredHistory = historyList;
      var filteredUpcoming = upcomingList;

      Logger.log(
          'Applying filters: dateRange=$_selectedDateRange, status=$_selectedStatus, searchQuery=$_searchQuery');

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
                .where((a) =>
                    a.start.isAfter(today) && a.start.isBefore(weekLater))
                .toList();
            filteredUpcoming = filteredUpcoming
                .where((a) =>
                    a.start.isAfter(today) && a.start.isBefore(weekLater))
                .toList();
            break;
          case 'month':
            final monthLater = DateTime(today.year, today.month + 1, today.day);
            filteredHistory = filteredHistory
                .where((a) =>
                    a.start.isAfter(today) && a.start.isBefore(monthLater))
                .toList();
            filteredUpcoming = filteredUpcoming
                .where((a) =>
                    a.start.isAfter(today) && a.start.isBefore(monthLater))
                .toList();
            break;
        }
        Logger.log(
            'After date filter: ${filteredHistory.length} history, ${filteredUpcoming.length} upcoming');
      }

      // Status filter
      if (_selectedStatus != 'all') {
        filteredHistory =
            filteredHistory.where((a) => a.status == _selectedStatus).toList();
        filteredUpcoming =
            filteredUpcoming.where((a) => a.status == _selectedStatus).toList();
        Logger.log(
            'After status filter: ${filteredHistory.length} history, ${filteredUpcoming.length} upcoming');
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filteredHistory = filteredHistory
            .where((a) =>
                a.patientName.toLowerCase().contains(query) ||
                a.patientEmail.toLowerCase().contains(query) ||
                a.purpose.toLowerCase().contains(query))
            .toList();
        filteredUpcoming = filteredUpcoming
            .where((a) =>
                a.patientName.toLowerCase().contains(query) ||
                a.patientEmail.toLowerCase().contains(query) ||
                a.purpose.toLowerCase().contains(query))
            .toList();
        Logger.log(
            'After search filter: ${filteredHistory.length} history, ${filteredUpcoming.length} upcoming');
      }

      // Sort by date
      filteredHistory.sort((a, b) => b.start.compareTo(a.start));
      filteredUpcoming.sort((a, b) => a.start.compareTo(b.start));

      Logger.log(
          'Final counts: ${filteredHistory.length} history appointments, ${filteredUpcoming.length} upcoming appointments');

      setState(() {
        _historyAppointments = filteredHistory;
        _upcomingAppointments = filteredUpcoming;
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

  Future<void> _cancelAppointment(AppointmentData appointment) async {
    try {
      setState(() => _isLoading = true);
      await _appointmentProvider.cancelAppointment(
        token: widget.token,
        appointmentId: appointment.id,
      );
      _showToast('Appointment cancelled successfully');
      _fetchAppointments();
    } catch (e) {
      _showToast('Failed to cancel appointment: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildAppointmentList(
      List<AppointmentData> appointments, String title) {
    if (appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No $title appointments found'),
        ),
      );
    }

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
          child: ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              final isPastAppointment =
                  appointment.start.isBefore(DateTime.now());
              final patientInfo = _patientInfoCache[appointment.patientId];
              final patientName = patientInfo != null
                  ? patientInfo['name'] ?? 'Unknown'
                  : 'Loading...';
              final patientEmail =
                  patientInfo != null ? patientInfo['email'] ?? '' : '';

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                try {
                                  final patient =
                                      await _patientProvider.getPatientById(
                                    token: widget.token,
                                    patientId: appointment.patientId,
                                  );
                                  if (!mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PatientDetailsPage(
                                        patient: patient,
                                        token: widget.token,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Failed to load patient details: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      (patientName.isNotEmpty)
                                          ? patientName[0].toUpperCase()
                                          : "?",
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    patientName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (patientEmail.isNotEmpty)
                                          Text(
                                            patientEmail,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.blue,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (appointment.status == 'scheduled' &&
                              !isPastAppointment)
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _cancelAppointment(appointment),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date & Time: ${DateFormat('EEEE, MMMM d, yyyy').format(appointment.start)} at ${DateFormat('h:mm a').format(appointment.start)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Duration: ${appointment.end.difference(appointment.start).inMinutes} minutes',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Purpose: ${appointment.purpose}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(appointment.status),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              appointment.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (appointment.suspended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SUSPENDED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rescheduled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    _scaffoldMessenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAppointments,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _fetchAppointments();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDateRange,
                      decoration: const InputDecoration(
                        labelText: 'Date Range',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'today', child: Text('Today')),
                        DropdownMenuItem(
                            value: 'week', child: Text('This Week')),
                        DropdownMenuItem(
                            value: 'month', child: Text('This Month')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedDateRange = value!);
                        _fetchAppointments();
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
                        DropdownMenuItem(
                            value: 'scheduled', child: Text('Scheduled')),
                        DropdownMenuItem(
                            value: 'completed', child: Text('Completed')),
                        DropdownMenuItem(
                            value: 'cancelled', child: Text('Cancelled')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStatus = value!);
                        _fetchAppointments();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
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
        ],
      ),
    );
  }
}
