import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../shared/components/custom_drawer.dart';
import '../../shared/theme/app_theme.dart';
import '../authentication/log_reg.dart';


// The pages for hospital user
import 'doctors/hospital_doctors_page.dart';
import 'patients/hospital_patients_page.dart';
import 'devices/hospital_devices_page.dart';
import 'appointments/hospital_appointments_page.dart';

class HospitalPage extends StatefulWidget {
  final String hospitalId;
  const HospitalPage({super.key, required this.hospitalId});

  @override
  _HospitalPageState createState() => _HospitalPageState();
}

class _HospitalPageState extends State<HospitalPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;
  final List<SidebarItem> _hospitalItems = [
    SidebarItem(icon: Icons.person, label: 'Doctors'),
    SidebarItem(icon: Icons.group, label: 'Patients'),
    SidebarItem(icon: Icons.device_hub, label: 'Devices'),
    SidebarItem(icon: Icons.event, label: 'Appointments'),
    SidebarItem(icon: Icons.logout, label: 'Logout'),
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      HospitalDoctorsPage(hospitalId: widget.hospitalId),
      HospitalPatientsPage(hospitalId: widget.hospitalId),
      HospitalDevicesPage(hospitalId: widget.hospitalId),
      HospitalAppointmentsPage(hospitalId: widget.hospitalId),
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
      // We remove drawer:. Instead, make a fixed sidebar:
      body: Row(
        children: [
          // 1) Our universal sidebar for hospital
          PersistentSidebar(
            headerTitle: 'Hospital Portal',
            items: _hospitalItems,
            selectedIndex: _selectedIndex,
            onMenuItemClicked: _onMenuItemClicked,
          ),

          // 2) Main content area
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
