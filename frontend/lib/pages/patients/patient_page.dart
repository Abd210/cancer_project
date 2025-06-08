import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../providers/patient_provider.dart';
import '../../../models/patient_data.dart';
import '../../../models/hospital_data.dart';
import '../../../models/doctor_data.dart';
import 'patient_profile_page.dart';
import 'patient_appointments_page.dart';
import 'patient_diagnosis_page.dart';

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
  final String? patientId;

  const PatientPage({
    Key? key,
    this.doctorId,
    this.token,
    this.patientId,
  }) : super(key: key);

  @override
  State<PatientPage> createState() => _PatientPageState();
}

/// We'll store the pages in an IndexedStack, with no special transitions.
class _PatientPageState extends State<PatientPage> {
  static const Color pinkColor = Color.fromARGB(255, 218, 73, 143);

  int _currentIndex = 0;

  final PatientProvider _patientProvider = PatientProvider();
  late Future<PatientData> _patientDataFuture;

  @override
  void initState() {
    super.initState();
    _patientDataFuture = _patientProvider
        .getPatients(
      token: widget.token ?? '',
      patientId: widget.patientId ?? '',
    )
        .then((list) {
      if (list.isEmpty) {
        throw Exception("Patient data not found.");
      }
      return list.first;
    });
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
      body: FutureBuilder<PatientData>(
        future: _patientDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No patient data available'));
          }

          final patientData = snapshot.data!;

          // We define the 5 sub-pages AFTER patientData is loaded
          final List<Widget> pages = [
            HomeTab(patientData: patientData),
            PatientAppointmentsPage(
              token: widget.token ?? '',
              patientId: widget.patientId ?? '',
            ),
            PatientDiagnosisPage(
              token: widget.token ?? '',
              patientId: widget.patientId ?? '',
              patientData: patientData,
            ),
            const SupportTab(),
            PatientProfilePage(
              token: widget.token ?? '',
              patientId: widget.patientId ?? '',
            ),
          ];

          return IndexedStack(
            index: _currentIndex,
            children: pages,
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: Colors.white,
        selectedItemColor: pinkColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Diagnosis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Support',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
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
        return "Diagnosis";
      case 3:
        return "Support";
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
                      backgroundColor: _PatientPageState.pinkColor,
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
// HOME TAB
// -----------------------------------------------------------------------------
class HomeTab extends StatelessWidget {
  final PatientData? patientData;
  const HomeTab({Key? key, this.patientData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to Curanics Clinic!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to Curanics Clinic!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Clinic Hours', 'Monday - Friday: 9 AM - 5 PM'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Contact',
                      'Phone: 555-123-4567 | Email: info@curanics.com'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Address', '123 Clinic St, Health City'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SUPPORT TAB
// -----------------------------------------------------------------------------
class SupportTab extends StatelessWidget {
  const SupportTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Support Tab"),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: APPOINTMENTS
// -----------------------------------------------------------------------------
class AppointmentsTab extends StatelessWidget {
  const AppointmentsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Appointments Tab"),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: TICKETS
// -----------------------------------------------------------------------------
class TicketsTab extends StatelessWidget {
  const TicketsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Tickets Tab"),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: NOTIFICATIONS
// -----------------------------------------------------------------------------
class NotificationsTab extends StatelessWidget {
  const NotificationsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Notifications Tab"),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 4: PROFILE
//    Replaces old side drawer: "Settings," "Logout," plus any advanced info
// -----------------------------------------------------------------------------
class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Profile Tab"),
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
