import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_data.dart';
import '../../providers/appointment_provider.dart';
import 'package:frontend/main.dart' show Logger;
import '../../../shared/components/loading_indicator.dart';

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
                        trailing: appointment.status == 'scheduled'
                            ? IconButton(
                                icon:
                                    const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () {
                                  // TODO: Implement cancel appointment functionality
                                  _showToast(
                                      'Cancel appointment functionality not implemented yet');
                                },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
      ),
      body: Column(
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
                          DropdownMenuItem(
                              value: 'scheduled', child: Text('Scheduled')),
                          DropdownMenuItem(
                              value: 'completed', child: Text('Completed')),
                          DropdownMenuItem(
                              value: 'cancelled', child: Text('Cancelled')),
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
        ],
      ),
    );
  }
}
