import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/shared/theme/app_theme.dart';
import 'package:frontend/shared/widgets/logo_bar.dart';
import 'package:frontend/pages/authentication/log_reg.dart';

// The pages
import '../../shared/components/custom_drawer.dart';
import 'view_hospitals/view_hospitals_page.dart';
import 'view_doctors/view_doctors_page.dart';
import 'view_patients/view_patients_page.dart';
import 'devices/devices_page.dart';
import 'appointments/appointments_page.dart';
import 'tickets/tickets_page.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  _SuperAdminDashboardState createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;

  // The pages
  final List<Widget> _pages = [
    HospitalsPage(),
    DoctorsPage(),
    PatientsPage(),
    DevicesPage(),
    AppointmentsPage(),
    TicketsPage(),
  ];

  // The sidebar items for Super Admin
  final List<SidebarItem> _adminItems = [
    SidebarItem(icon: Icons.local_hospital, label: 'Hospitals'),
    SidebarItem(icon: Icons.person, label: 'Doctors'),
    SidebarItem(icon: Icons.group, label: 'Patients'),
    SidebarItem(icon: Icons.device_hub, label: 'Devices'),
    SidebarItem(icon: Icons.event, label: 'Appointments'),
    SidebarItem(icon: Icons.rocket, label: 'Tickets'),
    SidebarItem(icon: Icons.logout, label: 'Logout'),
  ];

  void _onMenuItemClicked(int index) {
    // If "Logout"
    if (index == 6) {
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
      body: Row(
        children: [
          // 1) Our universal sidebar
          PersistentSidebar(
            headerTitle: 'Super Admin',
            items: _adminItems,
            selectedIndex: _selectedIndex,
            onMenuItemClicked: _onMenuItemClicked,
          ),

          // 2) Main content area
          Expanded(
            child: Column(
              children: [
                const LogoLine(), // your custom logo bar on top
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
          ),
        ],
      ),
    );
  }
}
