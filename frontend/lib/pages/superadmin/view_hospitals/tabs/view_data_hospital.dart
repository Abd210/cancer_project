import 'package:flutter/material.dart';
import 'package:frontend/pages/superadmin/view_hospitals/tabs/patients_tab.dart';
import 'package:frontend/pages/superadmin/view_hospitals/tabs/doctors_tab.dart';
import 'package:frontend/pages/superadmin/view_hospitals/tabs/appointments_tab.dart';
import 'package:frontend/pages/superadmin/view_hospitals/tabs/devices_tab.dart';

/// A full-screen detail view for a single hospital,
/// with a TabBar showing Patients, Doctors, Appointments, and Devices.
class ViewHospitalTabs extends StatefulWidget {
  /// JWT or auth token
  final String token;
  /// ID of the hospital to display
  final String hospitalId;
  /// Display name for the AppBar
  final String hospitalName;
  /// Which tab to open initially: 0=Patients, 1=Doctors, 2=Appointments, 3=Devices
  final int initialTabIndex;
  /// Callback to return to the list view
  final VoidCallback onBack;

  const ViewHospitalTabs({
    Key? key,
    required this.token,
    required this.hospitalId,
    required this.hospitalName,
    this.initialTabIndex = 1,
    required this.onBack,
  }) : super(key: key);

  @override
  _ViewHospitalTabsState createState() => _ViewHospitalTabsState();
}

class _ViewHospitalTabsState extends State<ViewHospitalTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(widget.hospitalName),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Patients'),
            Tab(text: 'Doctors'),
            Tab(text: 'Appointments'),
            Tab(text: 'Devices'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          HospitalPatientsTab(
            token: widget.token,
            hospitalId: widget.hospitalId,
          ),
          HospitalDoctorsTab(
            token: widget.token,
            hospitalId: widget.hospitalId,
          ),
          HospitalAppointmentsTab(
            token: widget.token,
            hospitalId: widget.hospitalId,
          ),
          const HospitalDevicesTab(),
        ],
      ),
    );
  }
}