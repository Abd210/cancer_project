import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../providers/patient_provider.dart';
import '../../../models/patient_data.dart';

/// ---------------------------------------------------------------------------
/// SINGLE-FILE PATIENT PAGE
/// - Pink-themed bottom nav bar
/// - No side drawer
/// - 5 tabs: Home, Appointments, Tickets, Notifications, Profile
/// - Polished UI with consistent spacing, advanced pink cards
/// - Full form fields (name/email/phone/address/problem/status/gender) for "change data"
/// - No animation between tabs
/// ---------------------------------------------------------------------------
class PatientPage extends StatefulWidget {
  final String? doctorId;
  final String? token;

  const PatientPage({Key? key, this.doctorId, this.token}) : super(key: key);

  @override
  State<PatientPage> createState() => _PatientPageState();
}

/// We'll store the pages in an IndexedStack, with no special transitions.
class _PatientPageState extends State<PatientPage> {
  static const Color pinkColor = Color.fromARGB(255, 218, 73, 143);

  int _currentIndex = 0;

  // We define the 5 sub-pages
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeTab(
          doctorId: widget.doctorId,
          token: widget.token), // Pass doctorId and token
      const AppointmentsTab(),
      const TicketsTab(),
      const NotificationsTab(),
      const ProfileTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // White top app bar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text(
          _titleForIndex(_currentIndex),
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          // Debug button to force API call
          if (widget.doctorId != null && widget.token != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.red),
              onPressed: () {
                print("Manually triggering API call");
                // Fallback approach using a brand new API call
                final patientProvider = PatientProvider();
                patientProvider
                    .getPatientsForDoctor(
                  token: widget.token!,
                  doctorId: widget.doctorId!,
                )
                    .then((patients) {
                  print("Manual API call returned ${patients.length} patients");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Found ${patients.length} patients")),
                  );
                }).catchError((error) {
                  print("Manual API call error: $error");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Error: $error"),
                        backgroundColor: Colors.red),
                  );
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.search, color: pinkColor),
            onPressed: () {
              // Show a search bottom sheet
              showModalBottomSheet(
                context: context,
                builder: (_) => const _SearchBottomSheet(),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: Colors.white,
        selectedItemColor: pinkColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.string(
              _currentIndex == 0 ? homeActiveSvg : homeInactiveSvg,
              height: 24,
              width: 24,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.string(
              _currentIndex == 1 ? calendarActiveSvg : calendarInactiveSvg,
              height: 24,
              width: 24,
            ),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.string(
              _currentIndex == 2 ? ticketActiveSvg : ticketInactiveSvg,
              height: 24,
              width: 24,
            ),
            label: 'Tickets',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.string(
              _currentIndex == 3 ? bellActiveSvg : bellInactiveSvg,
              height: 24,
              width: 24,
            ),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.string(
              _currentIndex == 4 ? userActiveSvg : userInactiveSvg,
              height: 24,
              width: 24,
            ),
            label: 'Profile',
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return "Home";
      case 1:
        return "Appointments";
      case 2:
        return "Tickets";
      case 3:
        return "Notifications";
      case 4:
      default:
        return "Profile";
    }
  }
}

// -----------------------------------------------------------------------------
// SEARCH BOTTOM SHEET
// -----------------------------------------------------------------------------
class _SearchBottomSheet extends StatefulWidget {
  const _SearchBottomSheet({Key? key}) : super(key: key);

  @override
  State<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<_SearchBottomSheet> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      minChildSize: 0.3,
      builder: (ctx, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: ListView(
            controller: scrollController,
            children: [
              const Text(
                "Search",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  labelText: "Enter search query",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text("Searching for: ${_searchCtrl.text}")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HomeTab.pinkColor,
                    ),
                    child: const Text("Search"),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 0: HOME
// -----------------------------------------------------------------------------
/// Displays patient info + device info in pink cards, referencing PDF logic
class HomeTab extends StatefulWidget {
  final String? doctorId;
  final String? token;

  const HomeTab({Key? key, this.doctorId, this.token}) : super(key: key);

  static const Color pinkColor = Color.fromARGB(255, 218, 73, 143);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool isLoading = true;
  late _PatientInfo _patient;
  late _DeviceInfo _device;
  final PatientProvider _patientProvider = PatientProvider();
  List<PatientData> _patients = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Debug information
    print('HomeTab.initState called');
    print('doctorId: ${widget.doctorId}');
    print('token: ${widget.token != null ? "has token" : "no token"}');

    if (widget.doctorId != null && widget.token != null) {
      // Fetch patients from the backend
      _fetchPatientsForDoctor();
    } else {
      print('Using static data because doctorId or token is null');
      // Fake loading with static data (for backward compatibility)
      _loadStaticData();
    }
  }

  Future<void> _fetchPatientsForDoctor() async {
    try {
      setState(() {
        isLoading = true;
        _errorMessage = null;
      });

      print('Fetching patients for doctor: ${widget.doctorId}');
      print('Using token: ${widget.token}');

      final patients = await _patientProvider.getPatientsForDoctor(
        token: widget.token!,
        doctorId: widget.doctorId!,
      );

      print('Received ${patients.length} patients from API');

      setState(() {
        _patients = patients;
        isLoading = false;

        // If we have patients, use the first one for display
        if (_patients.isNotEmpty) {
          final patient = _patients.first;
          print('First patient: ${patient.name}, ${patient.diagnosis}');
          _patient = _PatientInfo(
            name: patient.name,
            email: patient.email,
            phone: patient.mobileNumber,
            address: "No address provided", // PatientData doesn't have address
            problem: patient.diagnosis,
            status: patient.status,
            gender: "Not specified", // PatientData doesn't have gender
            doctor:
                "Dr. Unknown", // Use static value as PatientData doesn't have doctorName
            hospital: "Hospital", // PatientData doesn't have hospitalName
          );

          _device = const _DeviceInfo(
            id: "102567",
            mac: "33:24:XX:XX:XX:XX",
            isOn: true,
          );
        } else {
          print('No patients found for doctor ${widget.doctorId}');
        }
      });
    } catch (e) {
      print('ERROR fetching patients: $e');
      setState(() {
        isLoading = false;
        _errorMessage = 'Failed to load patients: $e';
      });

      // Show the error in a snackbar for better visibility
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _loadStaticData() {
    // Fake loading with static data
    Timer(const Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
        // Some placeholder data
        _patient = const _PatientInfo(
          name: "Abbey Carter",
          email: "abbey.carter@example.com",
          phone: "+91 9505999901",
          address: "Hyderabad, Telangana",
          problem: "Brain Tumor",
          status: "On Recovery",
          gender: "Female",
          doctor: "Dr. Preethi",
          hospital: "Somewhere, ?",
        );
        _device = const _DeviceInfo(
          id: "102567",
          mac: "33:24:XX:XX:XX:XX",
          isOn: true,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    print(
        'HomeTab.build: isLoading=$isLoading, hasError=${_errorMessage != null}, patientCount=${_patients.length}');

    if (isLoading) {
      return const _SkeletonListView(count: 2);
    }

    // Show error message if there was a problem
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              "Error Loading Patients",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _fetchPatientsForDoctor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomeTab.pinkColor,
                  ),
                  child: const Text("Try Again"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // DEBUG: Print details about the requests
                    print("DEBUG INFO:");
                    print("doctorId: ${widget.doctorId}");
                    print("token: ${widget.token?.substring(0, 10)}...");

                    // Make an explicit API call
                    final provider = PatientProvider();
                    provider
                        .getPatientsForDoctor(
                      token: widget.token!,
                      doctorId: widget.doctorId!,
                    )
                        .then((patients) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("Found ${patients.length} patients")),
                      );
                    }).catchError((e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("API Error: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text("Debug Call"),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // If no patients found when using real data
    if (widget.doctorId != null && widget.token != null && _patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "No patients found",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "You don't have any patients assigned to you yet",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchPatientsForDoctor,
              style: ElevatedButton.styleFrom(
                backgroundColor: HomeTab.pinkColor,
              ),
              child: const Text("Refresh"),
            ),
          ],
        ),
      );
    }

    // Show 2 advanced pink cards
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPatientInfoCard(),
          const SizedBox(height: 16),
          _buildDeviceInfoCard(),

          // Only show patient list if we have more than one patient
          if (widget.doctorId != null &&
              widget.token != null &&
              _patients.length > 1)
            _buildPatientsListCard(),
        ],
      ),
    );
  }

  Widget _buildPatientsListCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: _cardBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Patients",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _patients.length,
            itemBuilder: (context, index) {
              final patient = _patients[index];
              return ListTile(
                title: Text(patient.name),
                subtitle: Text(patient.diagnosis),
                trailing: Icon(Icons.circle,
                    color: patient.suspended ? Colors.red : Colors.green,
                    size: 12),
                onTap: () {
                  setState(() {
                    _patient = _PatientInfo(
                      name: patient.name,
                      email: patient.email,
                      phone: patient.mobileNumber,
                      address:
                          "No address provided", // PatientData doesn't have address
                      problem: patient.diagnosis,
                      status: patient.status,
                      gender:
                          "Not specified", // PatientData doesn't have gender
                      doctor: "Dr. Unknown", // No doctorName in PatientData
                      hospital: "Hospital", // No hospitalName in PatientData
                    );
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Patient Information",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          _infoRow("Name:", _patient.name),
          _infoRow("Email:", _patient.email),
          _infoRow("Phone:", _patient.phone),
          _infoRow("Problem:", _patient.problem),
          _infoRow("Status:", _patient.status),
          _infoRow("Gender:", _patient.gender),
          _infoRow("Address:", _patient.address),
          _infoRow("Doctor:", _patient.doctor),
          _infoRow("Hospital:", _patient.hospital),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: _showChangeRequestForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HomeTab.pinkColor,
                ),
                child: const Text("Request Change"),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {
                  // Fake refresh
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Patient info refreshed (static).")),
                  );
                },
                child: const Text("Refresh"),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Device Information",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          _infoRow("Device ID:", _device.id),
          _infoRow("MAC:", _device.mac),
          _infoRow("Status:", _device.isOn ? "ON" : "OFF"),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _device = _device.copyWith(isOn: !_device.isOn);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: HomeTab.pinkColor,
                ),
                child: Text(_device.isOn ? "Turn OFF" : "Turn ON"),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: _showDeviceReports,
                child: const Text("View Reports"),
              )
            ],
          )
        ],
      ),
    );
  }

  // Build a field label -> value row
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  BoxDecoration _cardBoxDecoration() {
    return BoxDecoration(
      color: Colors.pink[50],
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        )
      ],
    );
  }

  // Show a bottom sheet to request changes for all relevant fields
  void _showChangeRequestForm() {
    final nameCtrl = TextEditingController(text: _patient.name);
    final emailCtrl = TextEditingController(text: _patient.email);
    final phoneCtrl = TextEditingController(text: _patient.phone);
    final addressCtrl = TextEditingController(text: _patient.address);
    final problemCtrl = TextEditingController(text: _patient.problem);
    final statusCtrl = TextEditingController(text: _patient.status);
    final genderCtrl = TextEditingController(text: _patient.gender);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: ListView(
              controller: scrollController,
              children: [
                const Text(
                  "Request Profile Changes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildLabeledField("New Name", nameCtrl),
                const SizedBox(height: 8),
                _buildLabeledField("New Email", emailCtrl),
                const SizedBox(height: 8),
                _buildLabeledField("New Phone", phoneCtrl),
                const SizedBox(height: 8),
                _buildLabeledField("New Address", addressCtrl),
                const SizedBox(height: 8),
                _buildLabeledField("New Problem", problemCtrl),
                const SizedBox(height: 8),
                _buildLabeledField("New Status", statusCtrl),
                const SizedBox(height: 8),
                _buildLabeledField("New Gender", genderCtrl),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // In real usage, you'd send these changes to your backend for approval
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Change request submitted (static).")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomeTab.pinkColor,
                  ),
                  child: const Text("Submit Request"),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Return"),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabeledField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  // Show device reports
  void _showDeviceReports() {
    // Fake data
    final reports = [
      _DeviceReport(
        id: 2000,
        dateTime: DateTime.now().subtract(const Duration(hours: 4)),
        reading: "Vitals stable, 36.8°C, 72 bpm",
      ),
      _DeviceReport(
        id: 2001,
        dateTime: DateTime.now().subtract(const Duration(days: 1)),
        reading: "Slight anomaly detected at 03:00 AM",
      ),
    ];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Device Reports"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: reports.map((r) {
              return Card(
                color: Colors.pink[50],
                child: ListTile(
                  title: Text("Report #${r.id}"),
                  subtitle: Text("Date: ${r.dateTime}\nReading: ${r.reading}"),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Return"),
          )
        ],
      ),
    );
  }
}

// For skeleton placeholders
class _SkeletonListView extends StatelessWidget {
  final int count;
  const _SkeletonListView({Key? key, this.count = 2}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, i) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// Data models for Home tab
class _PatientInfo {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String problem;
  final String status;
  final String gender;
  final String doctor;
  final String hospital;

  const _PatientInfo({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.problem,
    required this.status,
    required this.gender,
    required this.doctor,
    required this.hospital,
  });
}

class _DeviceInfo {
  final String id;
  final String mac;
  final bool isOn;

  const _DeviceInfo({
    required this.id,
    required this.mac,
    required this.isOn,
  });

  _DeviceInfo copyWith({
    String? id,
    String? mac,
    bool? isOn,
  }) {
    return _DeviceInfo(
      id: id ?? this.id,
      mac: mac ?? this.mac,
      isOn: isOn ?? this.isOn,
    );
  }
}

class _DeviceReport {
  final int id;
  final DateTime dateTime;
  final String reading;
  const _DeviceReport({
    required this.id,
    required this.dateTime,
    required this.reading,
  });
}

// -----------------------------------------------------------------------------
// TAB 1: APPOINTMENTS
// -----------------------------------------------------------------------------
class AppointmentsTab extends StatefulWidget {
  const AppointmentsTab({Key? key}) : super(key: key);

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  bool isLoading = true;
  final List<_Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    // Fake load
    Timer(const Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
        // Some placeholders
        _appointments.addAll([
          _Appointment(
            id: 900,
            doctorName: "Dr. Banner",
            dateTime: DateTime.now().add(const Duration(days: 2)),
            status: "Scheduled",
            notes: "MRI results discussion",
          ),
          _Appointment(
            id: 901,
            doctorName: "Dr. Strange",
            dateTime: DateTime.now().add(const Duration(days: 5)),
            status: "Scheduled",
            notes: "Check medication progress",
          ),
        ]);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _SkeletonListView(count: 2);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var appt in _appointments) _buildAppointmentCard(appt),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddAppointmentForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: HomeTab.pinkColor,
            ),
            icon: const Icon(Icons.add),
            label: const Text("Add Appointment"),
          )
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(_Appointment appt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Appointment #${appt.id} with ${appt.doctorName}",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          Text("Date: ${appt.dateTime.toString().split(' ').first}"),
          Text("Status: ${appt.status}"),
          Text("Notes: ${appt.notes}"),
          const SizedBox(height: 8),
          if (appt.status == "Scheduled")
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _reschedule(appt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomeTab.pinkColor,
                  ),
                  child: const Text("Reschedule"),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _cancel(appt),
                  child: const Text("Cancel"),
                )
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: appt.status == "Canceled"
                    ? Colors.red[100]
                    : Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(appt.status,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            )
        ],
      ),
    );
  }

  void _showAddAppointmentForm() {
    final docCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime chosen = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: ListView(
              controller: scrollController,
              children: [
                const Text(
                  "Add Appointment",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: docCtrl,
                  decoration: const InputDecoration(
                    labelText: "Doctor Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: "Notes",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text("Date: ${chosen.toString().split(' ').first}"),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final pick = await showDatePicker(
                          context: context,
                          initialDate: chosen,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pick != null) {
                          setState(() => chosen = pick);
                        }
                      },
                      child: const Text("Pick Date"),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final newAppt = _Appointment(
                      id: Random().nextInt(999999),
                      doctorName: docCtrl.text.trim(),
                      dateTime: chosen,
                      status: "Scheduled",
                      notes: notesCtrl.text.trim(),
                    );
                    setState(() => _appointments.add(newAppt));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomeTab.pinkColor,
                  ),
                  child: const Text("Submit"),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Return"),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void _reschedule(_Appointment appt) async {
    final now = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: appt.dateTime.isBefore(now) ? now : appt.dateTime,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (newDate != null) {
      setState(() {
        final idx = _appointments.indexOf(appt);
        if (idx != -1) {
          _appointments[idx] = _appointments[idx].copyWith(dateTime: newDate);
        }
      });
    }
  }

  void _cancel(_Appointment appt) {
    setState(() {
      final idx = _appointments.indexOf(appt);
      if (idx != -1) {
        _appointments[idx] = _appointments[idx].copyWith(status: "Canceled");
      }
    });
  }
}

class _Appointment {
  final int id;
  final String doctorName;
  final DateTime dateTime;
  final String status; // "Scheduled", "Canceled", ...
  final String notes;

  _Appointment({
    required this.id,
    required this.doctorName,
    required this.dateTime,
    required this.status,
    required this.notes,
  });

  _Appointment copyWith({
    String? doctorName,
    DateTime? dateTime,
    String? status,
    String? notes,
  }) {
    return _Appointment(
      id: id,
      doctorName: doctorName ?? this.doctorName,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: TICKETS
// -----------------------------------------------------------------------------
class TicketsTab extends StatefulWidget {
  const TicketsTab({Key? key}) : super(key: key);

  @override
  State<TicketsTab> createState() => _TicketsTabState();
}

class _TicketsTabState extends State<TicketsTab> {
  bool isLoading = true;
  final List<_Ticket> _tickets = [];

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
        _tickets.addAll([
          _Ticket(
            id: 700,
            title: "Battery Issue",
            description: "Device battery drains quickly",
            status: "Open",
            dateReported: DateTime.now().subtract(const Duration(days: 1)),
          ),
          _Ticket(
            id: 701,
            title: "Sensor Malfunction",
            description: "Vitals not recorded from 2-3 AM",
            status: "Open",
            dateReported: DateTime.now().subtract(const Duration(hours: 6)),
          ),
        ]);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _SkeletonListView(count: 2);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var t in _tickets) _buildTicketCard(t),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddTicketForm,
            icon: const Icon(Icons.add),
            label: const Text("Report Ticket"),
            style: ElevatedButton.styleFrom(backgroundColor: HomeTab.pinkColor),
          )
        ],
      ),
    );
  }

  Widget _buildTicketCard(_Ticket t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ticket #${t.id}: ${t.title}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Text("Status: ${t.status}"),
          Text("Reported: ${t.dateReported.toString().split(' ').first}"),
          const SizedBox(height: 8),
          Text("Description: ${t.description}"),
          const SizedBox(height: 12),
          if (t.status == "Open")
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final idx = _tickets.indexOf(t);
                  if (idx != -1) {
                    _tickets[idx] = _tickets[idx].copyWith(status: "Closed");
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HomeTab.pinkColor,
              ),
              child: const Text("Close Ticket"),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("Closed",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
        ],
      ),
    );
  }

  void _showAddTicketForm() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: ListView(
              controller: scrollController,
              children: [
                const Text(
                  "Report New Ticket",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: "Ticket Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final newTicket = _Ticket(
                      id: Random().nextInt(999999),
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      status: "Open",
                      dateReported: DateTime.now(),
                    );
                    setState(() => _tickets.insert(0, newTicket));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: HomeTab.pinkColor),
                  child: const Text("Submit"),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Return"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Ticket {
  final int id;
  final String title;
  final String description;
  final String status; // "Open", "Closed"
  final DateTime dateReported;

  _Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.dateReported,
  });

  _Ticket copyWith({String? status}) {
    return _Ticket(
      id: id,
      title: title,
      description: description,
      status: status ?? this.status,
      dateReported: dateReported,
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: NOTIFICATIONS
// -----------------------------------------------------------------------------
class NotificationsTab extends StatefulWidget {
  const NotificationsTab({Key? key}) : super(key: key);

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  bool isLoading = true;
  final List<_NotificationItem> _items = [];

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
        _items.addAll([
          _NotificationItem(
            id: 1000,
            title: "Appointment Reminder",
            content: "You have an appointment in 2 days with Dr. Banner",
            date: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          _NotificationItem(
            id: 1001,
            title: "Ticket Update",
            content: "Your battery issue ticket was received by support.",
            date: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ]);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _SkeletonListView(count: 2);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _items.map((n) => _buildNotificationCard(n)).toList(),
      ),
    );
  }

  Widget _buildNotificationCard(_NotificationItem n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Notification #${n.id}: ${n.title}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Text("Date: ${n.date.toString().split(' ').first}"),
          const SizedBox(height: 4),
          Text("Content: ${n.content}"),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _items.remove(n);
              });
            },
            icon: const Icon(Icons.delete),
            label: const Text("Remove"),
            style: ElevatedButton.styleFrom(
              backgroundColor: HomeTab.pinkColor,
            ),
          )
        ],
      ),
    );
  }
}

class _NotificationItem {
  final int id;
  final String title;
  final String content;
  final DateTime date;

  _NotificationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
  });
}

// -----------------------------------------------------------------------------
// TAB 4: PROFILE
//    Replaces old side drawer: "Settings," "Logout," plus any advanced info
// -----------------------------------------------------------------------------
class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fake load
    Timer(const Duration(seconds: 1), () {
      setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _SkeletonListView(count: 2);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsCard(),
          const SizedBox(height: 16),
          _buildLogoutCard(),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardBoxDecoration(),
      child: ListTile(
        leading: const Icon(Icons.settings),
        title: const Text("Settings"),
        subtitle: const Text("Configure advanced preferences here."),
        onTap: () {
          // just a placeholder
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Settings tapped (static).")),
          );
        },
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardBoxDecoration(),
      child: ListTile(
        leading: const Icon(Icons.exit_to_app),
        title: const Text("Logout"),
        subtitle: const Text("Sign out from this account"),
        onTap: () {
          // Fake logout
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Logged out (static demo).")),
          );
        },
      ),
    );
  }

  BoxDecoration _cardBoxDecoration() {
    return BoxDecoration(
      color: Colors.pink[50],
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        )
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// BOTTOM NAV ICONS
// -----------------------------------------------------------------------------
const homeActiveSvg = '''
<svg width="24" height="24" fill="#DA498F" xmlns="http://www.w3.org/2000/svg">
<path d="M2 12L12 3l10 9h-3v8H5v-8H2Z"/></svg>
''';
const homeInactiveSvg = '''
<svg width="24" height="24" fill="#ccc" xmlns="http://www.w3.org/2000/svg">
<path d="M2 12L12 3l10 9h-3v8H5v-8H2Z"/></svg>
''';

const calendarActiveSvg = '''
<svg width="24" height="24" fill="#DA498F" xmlns="http://www.w3.org/2000/svg">
<path d="M7 2a1 1 0 0 1 2 0v1h6V2a1
1 0 1 1 2 0v1h2a2 2 0 0 1
2 2v13a2 2 0 0 1-2 2H5a2 2 0
0 1-2-2V5a2 2 0 0 1
2-2h2V2ZM5 9v11h14V9H5Z"/>
''';
const calendarInactiveSvg = '''
<svg width="24" height="24" fill="#ccc" xmlns="http://www.w3.org/2000/svg">
<path d="M7 2a1 1 0 0 1 2
0v1h6V2a1 1 0 1 1 2 0v1h2a2
2 0 0 1 2 2v13a2 2 0 0 1-2
2H5a2 2 0 0 1-2-2V5a2
2 0 0 1 2-2h2V2ZM5
9v11h14V9H5Z"/>
''';

const ticketActiveSvg = '''
<svg width="24" height="24" fill="#DA498F" xmlns="http://www.w3.org/2000/svg">
<path d="M2 11v2c1.657 0 3
1.343 3 3v4c0 1.657 1.343 3
3 3h8c1.657 0 3-1.343
3-3v-4c0-1.657 1.343-3
3-3v-2c-1.657 0-3-1.343
3-3V5c0-1.657-1.343-3-3-3H8C6.343
2 5 3.343 5 5v4c0 1.657-1.343 3-3 3Z"/>
''';
const ticketInactiveSvg = '''
<svg width="24" height="24" fill="#ccc" xmlns="http://www.w3.org/2000/svg">
<path d="M2 11v2c1.657
0 3 1.343 3 3v4c0 1.657 1.343
3 3 3h8c1.657 0 3-1.343
3-3v-4c0-1.657 1.343-3 3-3v-2c-1.657
0-3-1.343-3-3V5c0-1.657-1.343-3-3-3H8C6.343
2 5 3.343 5 5v4c0 1.657-1.343 3-3 3Z"/>
''';

const bellActiveSvg = '''
<svg width="24" height="24" fill="#DA498F" xmlns="http://www.w3.org/2000/svg">
<path d="M12 22c1.657 0
3-1.343 3-3H9c0 1.657 1.343
3 3 3zm6.707-5.707c-.393-.391-.707-1.303-.707-2.293V10c0-3.314-1.93-5.899-5-6.659V3a1
1 0 1 0-2 0v.341C7.93 4.101 6
6.686 6 10v4c0 .99-.314 1.902-.707
2.293A.996.996 0 0 0 5
17c0 .552.448 1 1
1h12c.552 0 1-.448
1-1 0-.265-.105-.52-.293-.707z"/>
</svg>
''';
const bellInactiveSvg = '''
<svg width="24" height="24" fill="#ccc" xmlns="http://www.w3.org/2000/svg">
<path d="M12 22c1.657 0
3-1.343 3-3H9c0
1.657 1.343 3 3 3zm6.707-5.707c-.393-.391-.707-1.303-.707-2.293V10c0-3.314-1.93-5.899-5-6.659V3a1
1 0 1 0-2 0v.341C7.93
4.101 6 6.686 6
10v4c0 .99-.314 1.902-.707
2.293A.996.996 0 0 0
5 17c0 .552.448
1 1 1h12c.552 0 1-.448
1-1 0-.265-.105-.52-.293-.707z"/>
''';

const userActiveSvg = '''
<svg width="24" height="24" fill="#DA498F" xmlns="http://www.w3.org/2000/svg">
<path d="M12 2C9.79
2 8 3.79 8 6s1.79 4 4 4
4-1.79 4-4-1.79-4-4-4zM4
20c0-3.866 3.134-7 7-7h2c3.866
0 7 3.134 7 7v1H4v-1z"/>
</svg>
''';
const userInactiveSvg = '''
<svg width="24" height="24" fill="#ccc" xmlns="http://www.w3.org/2000/svg">
<path d="M12
2C9.79 2 8 3.79 8
6s1.79 4 4 4 4-1.79
4-4-1.79-4-4-4zM4
20c0-3.866 3.134-7 7-7h2c3.866
0 7 3.134 7 7v1H4v-1z"/>
''';
