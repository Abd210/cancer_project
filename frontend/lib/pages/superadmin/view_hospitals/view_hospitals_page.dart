import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../../providers/data_provider.dart';
import '../../../models/hospital.dart';
import '../../../models/patient.dart';
import '../../../models/doctor.dart';
import '../../../models/appointment.dart';
import '../../../models/device.dart';

// Import your shared UI components
import '../../../shared/components/loading_indicator.dart';
import '../../../shared/components/components.dart';
import '../../../shared/components/responsive_data_table.dart'
    show BetterDataTable, BetterPaginatedDataTable;

class HospitalsPage extends StatefulWidget {
  const HospitalsPage({Key? key}) : super(key: key);

  @override
  _HospitalsPageState createState() => _HospitalsPageState();
}

class _HospitalsPageState extends State<HospitalsPage>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  bool _isLoading = false;

  // The hospital that’s currently selected to view details
  Hospital? _selectedHospital;

  // Tab controller for the detail tabs
  late TabController _tabController;

  // separate search queries for each tab in detail
  String _searchQueryPatients = '';
  String _searchQueryDoctors = '';
  String _searchQueryAppointments = '';
  String _searchQueryDevices = '';

  @override
  void initState() {
    super.initState();
    // We have 4 tabs for the hospital details: Patients, Doctors, Appointments, Devices
    _tabController = TabController(length: 4, vsync: this);
  }

  // CREATE / EDIT / DELETE HOSPITAL
  void _showAddHospitalDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String address = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Hospital'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Hospital Name'),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Enter name' : null,
                onSaved: (value) => name = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Enter address' : null,
                onSaved: (value) => address = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                final newHospital = Hospital(
                  id: 'h${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  address: address,
                );
                Provider.of<DataProvider>(context, listen: false)
                    .addHospital(newHospital);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Hospital added successfully.');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditHospitalDialog(BuildContext context, Hospital hospital) {
    final _formKey = GlobalKey<FormState>();
    String name = hospital.name;
    String address = hospital.address;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Hospital'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: hospital.name,
                decoration: const InputDecoration(labelText: 'Hospital Name'),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Enter name' : null,
                onSaved: (value) => name = value!,
              ),
              TextFormField(
                initialValue: hospital.address,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Enter address' : null,
                onSaved: (value) => address = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                final updatedHospital = Hospital(
                  id: hospital.id,
                  name: name,
                  address: address,
                );
                Provider.of<DataProvider>(context, listen: false)
                    .updateHospital(updatedHospital);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Hospital updated successfully.');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteHospital(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hospital'),
        content: const Text('Are you sure you want to delete this hospital?'),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<DataProvider>(context, listen: false)
                  .deleteHospital(id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Hospital deleted successfully.');
              // If we had been viewing the deleted hospital’s details, clear it
              if (_selectedHospital?.id == id) {
                setState(() {
                  _selectedHospital = null;
                });
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  /// Patients Section
  Widget _buildPatientsSection(DataProvider dataProvider) {
    if (_selectedHospital == null) return const SizedBox();
    final patients = dataProvider.patients.where((p) {
      if (p.doctorId.isEmpty) return false;
      final doctor = dataProvider.doctors.firstWhere(
            (d) => d.id == p.doctorId,
        orElse: () => Doctor(
          id: 'unknown',
          name: 'Unknown',
          specialization: '',
          hospitalId: '',
        ),
      );
      if (doctor.hospitalId != _selectedHospital!.id) return false;
      return p.name.toLowerCase().contains(_searchQueryPatients.toLowerCase());
    }).toList();

    final columns = const [
      DataColumn(label: Text('Name')),
      DataColumn(label: Text('Age')),
      DataColumn(label: Text('Diagnosis')),
      DataColumn(label: Text('Doctor')),
      DataColumn(label: Text('Device')),
    ];

    final rows = patients.map((patient) {
      final doctor = dataProvider.doctors.firstWhere(
            (d) => d.id == patient.doctorId,
        orElse: () => Doctor(
          id: 'unknown',
          name: 'Unknown',
          specialization: '',
          hospitalId: '',
        ),
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Patients',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQueryPatients = value);
            },
          ),
        ),
        Expanded(
          child: patients.isEmpty
              ? const Center(child: Text('No patients found.'))
              : BetterDataTable(columns: columns, rows: rows),
        ),
      ],
    );
  }

  /// Doctors Section
  Widget _buildDoctorsSection(DataProvider dataProvider) {
    if (_selectedHospital == null) return const SizedBox();
    final doctors = dataProvider.doctors.where((d) {
      if (d.hospitalId != _selectedHospital!.id) return false;
      final q = _searchQueryDoctors.toLowerCase();
      return d.name.toLowerCase().contains(q) ||
          d.specialization.toLowerCase().contains(q);
    }).toList();

    final columns = const [
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Doctors',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQueryDoctors = value);
            },
          ),
        ),
        Expanded(
          child: doctors.isEmpty
              ? const Center(child: Text('No doctors found.'))
              : BetterDataTable(columns: columns, rows: rows),
        ),
      ],
    );
  }

  /// Appointments Section
  Widget _buildAppointmentsSection(DataProvider dataProvider) {
    if (_selectedHospital == null) return const SizedBox();
    final appointments = dataProvider.appointments.where((appt) {
      // only those whose doctor belongs to this hospital
      final doc = dataProvider.doctors.firstWhere(
            (d) => d.id == appt.doctorId,
        orElse: () => Doctor(
          id: '',
          name: '',
          specialization: '',
          hospitalId: '',
        ),
      );
      if (doc.hospitalId != _selectedHospital!.id) return false;

      // filter by status or ID with search
      return appt.status
          .toLowerCase()
          .contains(_searchQueryAppointments.toLowerCase());
    }).toList();

    final columns = const [
      DataColumn(label: Text('Appointment ID')),
      DataColumn(label: Text('Doctor')),
      DataColumn(label: Text('Patient')),
      DataColumn(label: Text('Date')),
      DataColumn(label: Text('Status')),
    ];

    final rows = appointments.map((a) {
      final doctor = dataProvider.doctors.firstWhere(
            (d) => d.id == a.doctorId,
        orElse: () => Doctor(
          id: '',
          name: 'Unknown',
          specialization: '',
          hospitalId: '',
        ),
      );
      final patient = dataProvider.patients.firstWhere(
            (p) => p.id == a.patientId,
        orElse: () => Patient(
          id: '',
          name: 'Unknown',
          age: 0,
          diagnosis: '',
          doctorId: '',
          deviceId: '',
        ),
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Appointments',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQueryAppointments = value);
            },
          ),
        ),
        Expanded(
          child: appointments.isEmpty
              ? const Center(child: Text('No appointments found.'))
              : BetterDataTable(columns: columns, rows: rows),
        ),
      ],
    );
  }

  /// Devices Section
  Widget _buildDevicesSection(DataProvider dataProvider) {
    if (_selectedHospital == null) return const SizedBox();
    final devices = dataProvider.devices.where((dev) {
      // only devices assigned to a patient whose doctor is in this hospital
      if (dev.patientId.isEmpty) return false;
      final patient = dataProvider.patients.firstWhere(
            (p) => p.id == dev.patientId,
        orElse: () => Patient(
          id: '',
          name: 'Unassigned',
          age: 0,
          diagnosis: '',
          doctorId: '',
          deviceId: '',
        ),
      );
      if (patient.doctorId.isEmpty) return false;
      final doc = dataProvider.doctors.firstWhere(
            (d) => d.id == patient.doctorId,
        orElse: () => Doctor(
          id: '',
          name: '',
          specialization: '',
          hospitalId: '',
        ),
      );
      if (doc.hospitalId != _selectedHospital!.id) return false;

      return dev.type.toLowerCase().contains(_searchQueryDevices.toLowerCase());
    }).toList();

    final columns = const [
      DataColumn(label: Text('Device ID')),
      DataColumn(label: Text('Type')),
      DataColumn(label: Text('Assigned To')),
      DataColumn(label: Text('Doctor')),
    ];

    final rows = devices.map((dev) {
      final patient = dataProvider.patients.firstWhere(
            (p) => p.id == dev.patientId,
        orElse: () => Patient(
          id: '',
          name: 'Unassigned',
          age: 0,
          diagnosis: '',
          doctorId: '',
          deviceId: '',
        ),
      );
      final doctor = dataProvider.doctors.firstWhere(
            (d) => d.id == patient.doctorId,
        orElse: () => Doctor(
          id: '',
          name: 'Unknown',
          specialization: '',
          hospitalId: '',
        ),
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Devices',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQueryDevices = value);
            },
          ),
        ),
        Expanded(
          child: devices.isEmpty
              ? const Center(child: Text('No devices found.'))
              : BetterDataTable(columns: columns, rows: rows),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        if (_isLoading) {
          return const LoadingIndicator();
        }

        // If we have selected a hospital, show details (tabs).
        if (_selectedHospital != null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.black),
              title: Text(
                '${_selectedHospital!.name} Details',
                style: const TextStyle(color: Colors.black),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() => _selectedHospital = null);
                },
              ),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Patients'),
                  Tab(text: 'Doctors'),
                  Tab(text: 'Appointments'),
                  Tab(text: 'Devices'),
                ],
              ),
            ),
            body: Container(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPatientsSection(dataProvider),
                  _buildDoctorsSection(dataProvider),
                  _buildAppointmentsSection(dataProvider),
                  _buildDevicesSection(dataProvider),
                ],
              ),
            ),
          );
        }

        // Otherwise, show the hospital list
        List<Hospital> hospitals = dataProvider.hospitals.where((h) {
          return h.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              h.address.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search and Add Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Search Hospitals',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _showAddHospitalDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Hospital'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView.builder(
                  itemCount: hospitals.length,
                  itemBuilder: (context, index) {
                    final hospital = hospitals[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          hospital.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          hospital.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _showEditHospitalDialog(context, hospital),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _deleteHospital(context, hospital.id),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Show details in the same screen
                          setState(() {
                            _selectedHospital = hospital;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
