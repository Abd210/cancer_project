import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../shared/components/custom_drawer.dart';
import '../../shared/theme/app_theme.dart';
import '../authentication/log_reg.dart';

// Our universal sidebar

// Doctor pages
import 'notifications/doctor_notifications_page.dart';
import 'appointments/doctor_appointments_page.dart';
import 'patients/doctor_patients_page.dart';
import 'reports/doctor_reports_page.dart';

class DoctorPage extends StatefulWidget {
  final String doctorId;
  const DoctorPage({Key? key, required this.doctorId}) : super(key: key);

  @override
  _DoctorPageState createState() => _DoctorPageState();
}

class _DoctorPageState extends State<DoctorPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;
  final List<SidebarItem> _doctorItems = [
    SidebarItem(icon: Icons.notifications, label: 'Notifications'),
    SidebarItem(icon: Icons.event, label: 'Appointments'),
    SidebarItem(icon: Icons.group, label: 'Patients'),
    SidebarItem(icon: Icons.description, label: 'Reports'),
    SidebarItem(icon: Icons.logout, label: 'Logout'),
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      DoctorNotificationsPage(doctorId: widget.doctorId),
      DoctorAppointmentsPage(doctorId: widget.doctorId),
      DoctorPatientsPage(doctorId: widget.doctorId),
      DoctorReportsPage(doctorId: widget.doctorId),
    ];
  }

  void _onMenuItemClicked(int index) {
    if (index == 4) {
      // Logout
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LogIn()),
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
                  image: AssetImage(AppTheme.backgroundImage),
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
