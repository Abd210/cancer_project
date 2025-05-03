import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../shared/components/custom_drawer.dart';
import '../../shared/theme/app_theme.dart';
import '../authentication/log_reg.dart';
import '../../models/doctor_data.dart';
import '../../models/hospital_data.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/hospital_provider.dart';

// Doctor pages
import 'notifications/doctor_notifications_page.dart';
import 'appointments/doctor_appointments_page.dart';
import 'patients/doctor_patients_page.dart';
import 'reports/doctor_reports_page.dart';

class DoctorPage extends StatefulWidget {
  final String doctorId;
  final String token;

  const DoctorPage({super.key, required this.doctorId, required this.token});

  @override
  _DoctorPageState createState() => _DoctorPageState();
}

class _DoctorPageState extends State<DoctorPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;
  final List<SidebarItem> _doctorItems = [
    SidebarItem(icon: Icons.person, label: 'Personal Data'),
    SidebarItem(icon: Icons.group, label: 'Assigned Patients'),
    SidebarItem(icon: Icons.event, label: 'Appointments'),
    SidebarItem(icon: Icons.rocket, label: 'Tickets'),
    SidebarItem(icon: Icons.logout, label: 'Logout'),
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      // Personal Data page
      DoctorPersonalDataPage(doctorId: widget.doctorId, token: widget.token),
      // Assigned Patients page
      DoctorPatientsPage(doctorId: widget.doctorId, token: widget.token),
      // Appointments page
      DoctorAppointmentsPage(doctorId: widget.doctorId, token: widget.token),
      // Tickets page
      DoctorTicketsPage(doctorId: widget.doctorId, token: widget.token),
    ];
  }

  void _onMenuItemClicked(int index) {
    if (index == 4) {
      // Logout
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LogIn()),
      );
      Fluttertoast.showToast(msg: 'Logged out successfully.');
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No drawer; we do a persistent sidebar
      body: Row(
        children: [
          // 1) Our universal sidebar for doctor
          PersistentSidebar(
            headerTitle: 'Doctor Portal',
            items: _doctorItems,
            selectedIndex: _selectedIndex,
            onMenuItemClicked: _onMenuItemClicked,
          ),

          // 2) Main content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage(AppTheme.backgroundImage),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.8),
                    BlendMode.dstATop,
                  ),
                ),
              ),
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder implementations of required pages
class DoctorPersonalDataPage extends StatefulWidget {
  final String doctorId;
  final String token;

  const DoctorPersonalDataPage(
      {super.key, required this.doctorId, required this.token});

  @override
  _DoctorPersonalDataPageState createState() => _DoctorPersonalDataPageState();
}

class _DoctorPersonalDataPageState extends State<DoctorPersonalDataPage> {
  final DoctorProvider _doctorProvider = DoctorProvider();
  final HospitalProvider _hospitalProvider = HospitalProvider();

  bool _isLoading = true;
  DoctorData? _doctorData;
  String? _hospitalName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDoctorData();
  }

  Future<void> _fetchDoctorData() async {
    setState(() => _isLoading = true);
    try {
      // For doctor's personal data, the backend uses the token to extract the doctor's ID
      // We don't need to pass the doctorId explicitly for personal data
      final List<DoctorData> doctors = await _doctorProvider.getDoctors(
        token: widget.token,
        // The doctorId should be omitted when fetching a doctor's own data,
        // as the backend will use the ID from the JWT token
      );

      if (doctors.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Doctor data not found';
        });
        return;
      }

      final doctorData = doctors.first;

      // Fetch hospital data to get the hospital name
      String hospitalName = 'Unknown Hospital';
      if (doctorData.hospitalId.isNotEmpty) {
        try {
          final hospitals = await _hospitalProvider.getHospitals(
            token: widget.token,
            hospitalId: doctorData.hospitalId,
          );

          if (hospitals.isNotEmpty) {
            hospitalName = hospitals.first.name;
          }
        } catch (e) {
          // If we fail to get hospital name, we'll just use the default
          print('Failed to fetch hospital data: $e');
        }
      }

      setState(() {
        _doctorData = doctorData;
        _hospitalName = hospitalName;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load doctor data: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load doctor data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDoctorData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_doctorData == null) {
      return const Center(child: Text('Doctor data not available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and profile image
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.person, size: 60, color: Colors.blue),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _doctorData!.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _doctorData!.suspended
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _doctorData!.suspended ? 'Suspended' : 'Active',
                        style: TextStyle(
                          color: _doctorData!.suspended
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.local_hospital,
                            size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            // Navigate to hospital details
                            if (_doctorData!.hospitalId.isNotEmpty) {
                              // You can navigate to a hospital details page here
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Viewing hospital details: ${_hospitalName ?? "Unknown Hospital"}'),
                                ),
                              );
                            }
                          },
                          child: Text(
                            _hospitalName ?? 'Unknown Hospital',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Personal Information Section
          _buildSectionHeader('Personal Information'),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow('ID', _doctorData!.persId),
                  const Divider(),
                  _buildInfoRow('Email', _doctorData!.email),
                  const Divider(),
                  _buildInfoRow('Mobile Number', _doctorData!.mobileNumber),
                  const Divider(),
                  _buildInfoRow(
                      'Birth Date', _formatDate(_doctorData!.birthDate)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Professional Information Section
          _buildSectionHeader('Professional Information'),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Licenses', ''),
                  const SizedBox(height: 8),
                  ..._doctorData!.licenses
                      .map((license) => Padding(
                            padding:
                                const EdgeInsets.only(left: 16.0, bottom: 4.0),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    size: 16, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(child: Text(license)),
                              ],
                            ),
                          ))
                      .toList(),
                  const Divider(),
                  _buildInfoRow('Description', _doctorData!.description),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Schedule Section
          _buildSectionHeader('Working Schedule'),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _doctorData!.schedule.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No schedule defined'),
                          ),
                        )
                      : Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(1.5),
                            2: FlexColumnWidth(1.5),
                          },
                          border: TableBorder.all(
                            color: Colors.grey.shade300,
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(color: Colors.blue),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Day',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Start Time',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'End Time',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ..._doctorData!.schedule
                                .map((schedule) => TableRow(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(schedule['day'] ?? ''),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(schedule['start'] ?? ''),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(schedule['end'] ?? ''),
                                        ),
                                      ],
                                    ))
                                .toList(),
                          ],
                        ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class DoctorPatientsPage extends StatelessWidget {
  final String doctorId;
  final String token;

  const DoctorPatientsPage(
      {super.key, required this.doctorId, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Patients'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView.builder(
        itemCount: 5, // Placeholder count
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text('Patient ${index + 1}'),
              subtitle: Text('Patient ID: P10${index + 1}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.blue),
                    onPressed: () {
                      // View patient details
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.event, color: Colors.green),
                    onPressed: () {
                      // Schedule appointment
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DoctorAppointmentsPage extends StatelessWidget {
  final String doctorId;
  final String token;

  const DoctorAppointmentsPage(
      {super.key, required this.doctorId, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView.builder(
        itemCount: 3, // Placeholder count
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.event, color: Colors.white),
              ),
              title: Text('Appointment with Patient ${index + 1}'),
              subtitle: Text(
                  'Date: ${DateTime.now().add(Duration(days: index + 1)).toString().substring(0, 16)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      // Edit appointment
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Cancel appointment
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DoctorTicketsPage extends StatelessWidget {
  final String doctorId;
  final String token;

  const DoctorTicketsPage(
      {super.key, required this.doctorId, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Create new ticket
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text('Create New Ticket'),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 2, // Placeholder count
              itemBuilder: (context, index) {
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.rocket, color: Colors.white),
                    ),
                    title: Text('Ticket #10${index + 1}'),
                    subtitle: Text('Status: ${index == 0 ? 'Open' : 'Closed'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                      onPressed: () {
                        // View ticket details
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
