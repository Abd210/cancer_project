import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../authentication/log_reg.dart';
import '../../../providers/patient_provider.dart';
import '../../../models/patient_data.dart';
import '../../shared/components/custom_drawer.dart';
import '../../shared/widgets/logo_bar.dart';
import '../../shared/theme/app_theme.dart';
import './components/patient_home_tab.dart';
import './patient_appointments_page.dart';
import './patient_diagnosis_page.dart';
import './patient_profile_page.dart';
import './components/patient_theme.dart';

class PatientPageWeb extends StatefulWidget {
  final String? doctorId;
  final String token;
  final String patientId;
  final VoidCallback onSwitchToMobile;

  const PatientPageWeb({
    Key? key,
    required this.token,
    required this.patientId,
    this.doctorId,
    required this.onSwitchToMobile,
  }) : super(key: key);

  @override
  State<PatientPageWeb> createState() => _PatientPageWebState();
}

class _PatientPageWebState extends State<PatientPageWeb> with TickerProviderStateMixin {
  final PatientProvider _patientProvider = PatientProvider();
  late Future<PatientData> _patientDataFuture;
  int _selectedIndex = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late List<SidebarItem> _sidebarItems;

  @override
  void initState() {
    super.initState();

    _patientDataFuture = _patientProvider.getPatients(
      token: widget.token,
      patientId: widget.patientId,
    ).then((list) {
      if (list.isEmpty) throw Exception('Patient not found');
      return list.first;
    });

    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();

    _sidebarItems = [
      SidebarItem(icon: Icons.dashboard, label: 'Dashboard'),
      SidebarItem(icon: Icons.calendar_month, label: 'Appointments'),
      SidebarItem(icon: Icons.description, label: 'Reports'),
      SidebarItem(icon: Icons.person, label: 'Profile'),
      SidebarItem(icon: Icons.phone_android, label: 'Mobile UI'),
      SidebarItem(icon: Icons.logout, label: 'Logout'),
    ];
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PatientData>(
      future: _patientDataFuture,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final patient = snap.data!;

        final pages = [
          PatientHomeTab(patientData: patient),
          PatientAppointmentsPage(token: widget.token, patientId: widget.patientId),
          PatientDiagnosisPage(token: widget.token, patientId: widget.patientId, patientData: patient),
          PatientProfilePage(token: widget.token, patientId: widget.patientId),
        ];
        final titles = [
          'Dashboard',
          'Appointments',
          'Reports',
          'Profile',
        ];

        return Scaffold(
          body: Row(
            children: [
              // Sidebar identical to superadmin style
              PersistentSidebar(
                headerTitle: 'Patient',
                items: _sidebarItems,
                selectedIndex: _selectedIndex,
                onMenuItemClicked: (index) {
                  // Logout selected
                  if (index == 5) {
                    _signOut(context);
                    return;
                  }
                  // Switch to mobile layout
                  if (index == 4) {
                    widget.onSwitchToMobile();
                    return;
                  }
                  setState(() => _selectedIndex = index);
                },
              ),

              // Main content area
              Expanded(
                child: Column(
                  children: [
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
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: pages[_selectedIndex],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _signOut(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LogIn()),
      (route) => false,
    );
  }
} 