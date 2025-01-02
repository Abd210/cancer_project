import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../providers/data_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../authentication/log_reg.dart';

// These are the pages we created for the Hospital user
import 'doctors/hospital_doctors_page.dart';
import 'patients/hospital_patients_page.dart';
import 'devices/hospital_devices_page.dart';
import 'appointments/hospital_appointments_page.dart';

// This is a custom drawer just for the hospital user
import 'hospital_drawer.dart';

class HospitalPage extends StatefulWidget {
  final String hospitalId;

  /// Pass the hospitalId (e.g. “h0”) after the user logs in
  const HospitalPage({super.key, required this.hospitalId});

  @override
  _HospitalPageState createState() => _HospitalPageState();
}

class _HospitalPageState extends State<HospitalPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    
    // Initialize each tab/page with a reference to this hospital
    _pages = [
      HospitalDoctorsPage(hospitalId: widget.hospitalId),
      HospitalPatientsPage(hospitalId: widget.hospitalId),
      HospitalDevicesPage(hospitalId: widget.hospitalId),
      HospitalAppointmentsPage(hospitalId: widget.hospitalId),
    ];
  }

  /// Called when a menu item is tapped in the hospital drawer
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
      // A custom drawer for hospital-level navigation
      drawer: HospitalDrawer(
        onMenuItemClicked: _onMenuItemClicked,
        selectedIndex: _selectedIndex,
      ),
      appBar: AppBar(
        title: const Text('Hospital Dashboard'),
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
        // Show the selected page
        child: _pages[_selectedIndex],
      ),
    );
  }
}
