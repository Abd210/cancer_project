import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../shared/theme/app_theme.dart';
import '../authentication/log_reg.dart';
import 'navbar/doctor_drawer.dart';

// Pages specific to the doctor
import 'notifications/doctor_notifications_page.dart';
import 'appointments/doctor_appointments_page.dart';
import 'patients/doctor_patients_page.dart';
import 'reports/doctor_reports_page.dart';

class DoctorPage extends StatefulWidget {
  final String doctorId;

  const DoctorPage({super.key, required this.doctorId});

  @override
  _DoctorPageState createState() => _DoctorPageState();
}

class _DoctorPageState extends State<DoctorPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

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
      // Index 4 => Logout
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
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DoctorDrawer(
        onMenuItemClicked: _onMenuItemClicked,
        selectedIndex: _selectedIndex,
      ),
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Container(
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
    );
  }
}
