// lib/pages/superadmin/super_admin_dashboard.dart
import 'package:flutter/material.dart';
import '../../shared/components/custom_drawer.dart';
import '../../shared/theme/app_theme.dart';
import 'view_hospitals/view_hospitals_page.dart';
import 'view_doctors/view_doctors_page.dart';
import 'view_patients/view_patients_page.dart';
import '';
import 'devices/devices_page.dart';
import 'appointments/appointments_page.dart';
import 'tickets/tickets_page.dart';
import '../authentication/log_reg.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  _SuperAdminDashboardState createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HospitalsPage(),
    DoctorsPage(),
    PatientsPage(),
    DevicesPage(),
    AppointmentsPage(),
    TicketsPage(),
  ];

  void _onMenuItemClicked(int index) {
    if (index == 6) {
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
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(
        onMenuItemClicked: _onMenuItemClicked,
        selectedIndex: _selectedIndex,
      ),
      appBar: AppBar(
        title: Text('Super Admin Dashboard'),
      ),
      body: Container(
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
    );
  }
}
