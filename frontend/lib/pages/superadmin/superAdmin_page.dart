// lib/pages/superadmin/superAdmin_page.dart

import 'package:flutter/material.dart';
import 'package:frontend/shared/theme/app_theme.dart';
import 'package:frontend/shared/widgets/logo_bar.dart';
import 'package:frontend/pages/authentication/log_reg.dart';

import 'package:frontend/shared/components/custom_drawer.dart';

// Import these pages
import 'view_hospitals/view_hospitals_page.dart';
import 'view_admins/view_admins_page.dart';
import 'view_doctors/view_doctors_page.dart';
import 'view_patients/view_patients_page.dart';
import 'devices/devices_page.dart';
import 'appointments/appointments_page.dart';
import 'tickets/tickets_page.dart';

class SuperAdminDashboard extends StatefulWidget {
  final String token;
  const SuperAdminDashboard({Key? key, required this.token}) : super(key: key);

  @override
  _SuperAdminDashboardState createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;

  // The sidebar items
  final List<SidebarItem> _adminItems = [
    SidebarItem(icon: Icons.local_hospital, label: 'Hospitals'),
    SidebarItem(icon: Icons.admin_panel_settings, label: 'Admins'),
    SidebarItem(icon: Icons.person, label: 'Doctors'),
    SidebarItem(icon: Icons.group, label: 'Patients'),
    SidebarItem(icon: Icons.device_hub, label: 'Devices'),
    SidebarItem(icon: Icons.event, label: 'Appointments'),
    SidebarItem(icon: Icons.rocket, label: 'Tickets'),
    SidebarItem(icon: Icons.logout, label: 'Logout'),
  ];

  void _onMenuItemClicked(int index) {
    // If logout
    if (index == 7) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LogIn()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild your pages every time build() is called
    final pages = [
      HospitalsPage(token: widget.token), // 0
      AdminsPage(token: widget.token),                 // 1
      DoctorsPage(token: widget.token),                // 2
      PatientsPage(token: widget.token),               // 3
      DevicesPage(token: widget.token),                // 4
      AppointmentsPage(token: widget.token),           // 5
      TicketsPage(token: widget.token),                // 6
    ];

    return Scaffold(
      body: Row(
        children: [
          // 1) Sidebar
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
                // Your custom logo bar at the top
                const LogoLine(),
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
                    child: pages[_selectedIndex],
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
