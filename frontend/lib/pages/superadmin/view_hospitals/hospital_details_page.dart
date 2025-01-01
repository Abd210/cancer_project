import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../providers/data_provider.dart';
import '../../../models/hospital.dart';
import '../../../models/patient.dart';
import '../../../models/doctor.dart';
import '../../../models/appointment.dart';
import '../../../models/device.dart';

// We import our "ResponsiveDataTable":
import '../../../shared/components/components.dart';

class HospitalDetailsPage extends StatefulWidget {
  final Hospital hospital;

  const HospitalDetailsPage({required this.hospital, Key? key}) : super(key: key);

  @override
  _HospitalDetailsPageState createState() => _HospitalDetailsPageState();
}

class _HospitalDetailsPageState extends State<HospitalDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // separate search queries for each tab
  String _searchQueryPatients = '';
  String _searchQueryDoctors = '';
  String _searchQueryAppointments = '';
  String _searchQueryDevices = '';

  @override
  void initState() {
    super.initState();
    // We have 4 tabs: Patients, Doctors, Appointments, Devices
    _tabController = TabController(length: 4, vsync: this);
  }

  /// --------------------
  /// 1) Patients Section
  /// --------------------
  Widget _buildPatientsSection(DataProvider dataProvider) {
    // Filter only patients belonging to this hospital’s doctors + search
    final patients = dataProvider.patients.where((p) {
      if (p.doctorId.isEmpty) return false;
      final doctor = dataProvider.doctors.firstWhere(
            (d) => d.id == p.doctorId,
        orElse: () => Doctor(id: 'unknown', name: 'Unknown', specialization: '', hospitalId: ''),
      );
      if (doctor.hospitalId != widget.hospital.id) return false;
      return p.name.toLowerCase().contains(_searchQueryPatients.toLowerCase());
    }).toList();

    // DataTable columns
    final columns = [
      DataColumn(label: Text('Name')),
      DataColumn(label: Text('Age')),
      DataColumn(label: Text('Diagnosis')),
      DataColumn(label: Text('Doctor')),
      DataColumn(label: Text('Device')),
    ];

    // Build each row
    final rows = patients.map((patient) {
      final doctor = dataProvider.doctors.firstWhere(
            (d) => d.id == patient.doctorId,
        orElse: () => Doctor(id: 'unknown', name: 'Unknown', specialization: '', hospitalId: ''),
      );
      final device = dataProvider.devices.firstWhere(
            (dev) => dev.id == patient.deviceId,
        orElse: () => Device(id: 'unknown', type: 'Unassigned', patientId: ''),
      );

      return DataRow(
        cells: [
          DataCell(Text(patient.name)),
          DataCell(Text('${patient.age}')),
          DataCell(Text(patient.diagnosis)),
          DataCell(Text(doctor.name)),
          DataCell(Text(device.type)),
        ],
      );
    }).toList();

    return Column(
      children: [
        // The search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Patients',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (value) {
              setState(() => _searchQueryPatients = value);
            },
          ),
        ),
        // The responsive DataTable
        Expanded(
          child: patients.isEmpty
              ? Center(child: Text('No patients found.'))
              : ResponsiveDataTable(
            columns: columns,
            rows: rows,
          ),
        ),
      ],
    );
  }

  /// --------------------
  /// 2) Doctors Section
  /// --------------------
  Widget _buildDoctorsSection(DataProvider dataProvider) {
    final doctors = dataProvider.doctors.where((d) {
      if (d.hospitalId != widget.hospital.id) return false;
      final q = _searchQueryDoctors.toLowerCase();
      return d.name.toLowerCase().contains(q) ||
          d.specialization.toLowerCase().contains(q);
    }).toList();

    final columns = [
      DataColumn(label: Text('Name')),
      DataColumn(label: Text('Specialization')),
    ];

    final rows = doctors.map((doctor) {
      return DataRow(
        cells: [
          DataCell(Text(doctor.name)),
          DataCell(Text(doctor.specialization)),
        ],
      );
    }).toList();

    return Column(
      children: [
        // The search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Doctors',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (value) {
              setState(() => _searchQueryDoctors = value);
            },
          ),
        ),
        // The responsive DataTable
        Expanded(
          child: doctors.isEmpty
              ? Center(child: Text('No doctors found.'))
              : ResponsiveDataTable(
            columns: columns,
            rows: rows,
          ),
        ),
      ],
    );
  }

  /// -------------------------
  /// 3) Appointments Section
  /// -------------------------
  Widget _buildAppointmentsSection(DataProvider dataProvider) {
    final appointments = dataProvider.appointments.where((appt) {
      // only those whose doctor belongs to this hospital
      final doc = dataProvider.doctors.firstWhere(
            (d) => d.id == appt.doctorId,
        orElse: () => Doctor(id: '', name: '', specialization: '', hospitalId: ''),
      );
      if (doc.hospitalId != widget.hospital.id) return false;

      // filter by status with search
      return appt.status.toLowerCase().contains(_searchQueryAppointments.toLowerCase());
    }).toList();

    final columns = [
      DataColumn(label: Text('Appointment ID')),
      DataColumn(label: Text('Doctor')),
      DataColumn(label: Text('Patient')),
      DataColumn(label: Text('Date')),
      DataColumn(label: Text('Status')),
    ];

    final rows = appointments.map((a) {
      final doctor = dataProvider.doctors.firstWhere(
            (d) => d.id == a.doctorId,
        orElse: () => Doctor(id: '', name: 'Unknown', specialization: '', hospitalId: ''),
      );
      final patient = dataProvider.patients.firstWhere(
            (p) => p.id == a.patientId,
        orElse: () => Patient(id: '', name: 'Unknown', age: 0, diagnosis: '', doctorId: '', deviceId: ''),
      );

      return DataRow(
        cells: [
          DataCell(Text(a.id)),
          DataCell(Text(doctor.name)),
          DataCell(Text(patient.name)),
          DataCell(Text(DateFormat('yyyy-MM-dd').format(a.dateTime))),
          DataCell(Text(a.status)),
        ],
      );
    }).toList();

    return Column(
      children: [
        // The search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Appointments',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (value) {
              setState(() => _searchQueryAppointments = value);
            },
          ),
        ),
        // The responsive DataTable
        Expanded(
          child: appointments.isEmpty
              ? Center(child: Text('No appointments found.'))
              : ResponsiveDataTable(
            columns: columns,
            rows: rows,
          ),
        ),
      ],
    );
  }

  /// --------------------
  /// 4) Devices Section
  /// --------------------
  Widget _buildDevicesSection(DataProvider dataProvider) {
    final devices = dataProvider.devices.where((dev) {
      // only devices assigned to a patient whose doctor is in this hospital
      if (dev.patientId.isEmpty) return false;

      final patient = dataProvider.patients.firstWhere(
            (p) => p.id == dev.patientId,
        orElse: () => Patient(id: '', name: 'Unassigned', age: 0, diagnosis: '', doctorId: '', deviceId: ''),
      );
      if (patient.doctorId.isEmpty) return false;

      final doc = dataProvider.doctors.firstWhere(
            (d) => d.id == patient.doctorId,
        orElse: () => Doctor(id: '', name: '', specialization: '', hospitalId: ''),
      );
      if (doc.hospitalId != widget.hospital.id) return false;

      return dev.type.toLowerCase().contains(_searchQueryDevices.toLowerCase());
    }).toList();

    final columns = [
      DataColumn(label: Text('Device ID')),
      DataColumn(label: Text('Type')),
      DataColumn(label: Text('Assigned To')),
      DataColumn(label: Text('Doctor')),
    ];

    final rows = devices.map((dev) {
      final patient = dataProvider.patients.firstWhere(
            (p) => p.id == dev.patientId,
        orElse: () => Patient(id: '', name: 'Unassigned', age: 0, diagnosis: '', doctorId: '', deviceId: ''),
      );
      final doctor = dataProvider.doctors.firstWhere(
            (d) => d.id == patient.doctorId,
        orElse: () => Doctor(id: '', name: 'Unknown', specialization: '', hospitalId: ''),
      );
      return DataRow(
        cells: [
          DataCell(Text(dev.id)),
          DataCell(Text(dev.type)),
          DataCell(Text(patient.name)),
          DataCell(Text(doctor.name)),
        ],
      );
    }).toList();

    return Column(
      children: [
        // The search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Devices',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (value) {
              setState(() => _searchQueryDevices = value);
            },
          ),
        ),
        // The responsive DataTable
        Expanded(
          child: devices.isEmpty
              ? Center(child: Text('No devices found.'))
              : ResponsiveDataTable(
            columns: columns,
            rows: rows,
          ),
        ),
      ],
    );
  }

  /// --------------------
  /// Main build
  /// --------------------
  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (ctx, dataProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('${widget.hospital.name} Details'),
            bottom: TabBar(
              controller: _tabController,
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
            controller: _tabController,
            children: [
              _buildPatientsSection(dataProvider),
              _buildDoctorsSection(dataProvider),
              _buildAppointmentsSection(dataProvider),
              _buildDevicesSection(dataProvider),
            ],
          ),
        );
      },
    );
  }
}
