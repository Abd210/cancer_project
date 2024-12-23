// lib/pages/superadmin/hospitals/hospital_details_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/data_provider.dart';
import '../../../models/hospital.dart';
import '../../../models/patient.dart';
import '../../../models/doctor.dart';
import '../../../models/appointment.dart';
import '../../../models/device.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HospitalDetailsPage extends StatefulWidget {
  final Hospital hospital;

  const HospitalDetailsPage({required this.hospital, Key? key}) : super(key: key);

  @override
  _HospitalDetailsPageState createState() => _HospitalDetailsPageState();
}

class _HospitalDetailsPageState extends State<HospitalDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQueryPatients = '';
  String _searchQueryDoctors = '';
  String _searchQueryAppointments = '';
  String _searchQueryDevices = '';

  @override
  void initState() {
    super.initState();
    // Initialize TabController with 4 tabs: Patients, Doctors, Appointments, Devices
    _tabController = TabController(length: 4, vsync: this);
  }

  // Patients Section
  Widget _buildPatientsSection(DataProvider dataProvider) {
    List<Patient> patients = dataProvider.patients.where((p) {
      if (p.doctorId.isEmpty) return false;
      Doctor doctor = dataProvider.doctors.firstWhere(
            (d) => d.id == p.doctorId,
        orElse: () => Doctor(
          id: 'unknown',
          name: 'Unknown',
          specialization: 'Unknown',
          hospitalId: 'unknown',
        ),
      );
      // Ensure doctor is associated with the current hospital
      return doctor.hospitalId == widget.hospital.id;
    }).where((p) => p.name.toLowerCase().contains(_searchQueryPatients.toLowerCase())).toList();

    // Define DataTable Columns
    final columns = [
      DataColumn(label: Text('Name')),
      DataColumn(label: Text('Age')),
      DataColumn(label: Text('Diagnosis')),
      DataColumn(label: Text('Doctor')),
      DataColumn(label: Text('Device')),
    ];

    // Define DataTable Rows
    final rows = patients.map((patient) {
      Doctor doctor = dataProvider.doctors.firstWhere(
            (d) => d.id == patient.doctorId,
        orElse: () => Doctor(
          id: 'unknown',
          name: 'Unknown',
          specialization: 'Unknown',
          hospitalId: 'unknown',
        ),
      );
      Device device = dataProvider.devices.firstWhere(
            (d) => d.id == patient.deviceId,
        orElse: () => Device(
          id: 'unknown',
          type: 'Unassigned',
          patientId: '',
        ),
      );

      return DataRow(
        cells: [
          DataCell(Text(patient.name), onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailsPage(patient: patient),
              ),
            );
          }),
          DataCell(Text(patient.age.toString())),
          DataCell(Text(patient.diagnosis)),
          DataCell(Text(doctor.name)),
          DataCell(Text(device.type != 'Unassigned' ? device.type : 'Unassigned')),
        ],
      );
    }).toList();

    return Column(
      children: [
        // Search Bar for Patients
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Patients',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (value) {
              setState(() {
                _searchQueryPatients = value;
              });
            },
          ),
        ),
        // Patients DataTable
        Expanded(
          child: patients.isEmpty
              ? Center(child: Text('No patients found.'))
              : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: columns,
                rows: rows,
                headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[200]!),
                dataRowHeight: 60,
                columnSpacing: 20,
                onSelectAll: null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Doctors Section
  Widget _buildDoctorsSection(DataProvider dataProvider) {
    List<Doctor> doctors = dataProvider.doctors
        .where((d) => d.hospitalId == widget.hospital.id)
        .where((d) =>
    d.name.toLowerCase().contains(_searchQueryDoctors.toLowerCase()) ||
        d.specialization.toLowerCase().contains(_searchQueryDoctors.toLowerCase()))
        .toList();

    // Define DataTable Columns
    final columns = [
      DataColumn(label: Text('Name')),
      DataColumn(label: Text('Specialization')),
    ];

    // Define DataTable Rows
    final rows = doctors.map((doctor) {
      return DataRow(
        cells: [
          DataCell(Text(doctor.name), onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorDetailsPage(doctor: doctor),
              ),
            );
          }),
          DataCell(Text(doctor.specialization)),
        ],
      );
    }).toList();

    return Column(
      children: [
        // Search Bar for Doctors
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Doctors',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (value) {
              setState(() {
                _searchQueryDoctors = value;
              });
            },
          ),
        ),
        // Doctors DataTable
        Expanded(
          child: doctors.isEmpty
              ? Center(child: Text('No doctors found.'))
              : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: columns,
                rows: rows,
                headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[200]!),
                dataRowHeight: 60,
                columnSpacing: 20,
                onSelectAll: null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Appointments Section
  Widget _buildAppointmentsSection(DataProvider dataProvider) {
    List<Appointment> appointments = dataProvider.appointments.where((a) {
      if (a.doctorId.isEmpty) return false;
      Doctor doctor = dataProvider.doctors.firstWhere(
            (d) => d.id == a.doctorId,
        orElse: () => Doctor(
          id: 'unknown',
          name: 'Unknown',
          specialization: 'Unknown',
          hospitalId: 'unknown',
        ),
      );
      return doctor.hospitalId == widget.hospital.id;
    }).where((a) => a.status.toLowerCase().contains(_searchQueryAppointments.toLowerCase())).toList();

    // Define DataTable Columns
    final columns = [
      DataColumn(label: Text('Appointment ID')),
      DataColumn(label: Text('Doctor')),
      DataColumn(label: Text('Patient')),
      DataColumn(label: Text('Date')),
      DataColumn(label: Text('Status')),
    ];

    // Define DataTable Rows
    final rows = appointments.map((appointment) {
      Doctor doctor = dataProvider.doctors.firstWhere(
            (d) => d.id == appointment.doctorId,
        orElse: () => Doctor(
          id: 'unknown',
          name: 'Unknown',
          specialization: 'Unknown',
          hospitalId: 'unknown',
        ),
      );
      Patient patient = dataProvider.patients.firstWhere(
            (p) => p.id == appointment.patientId,
        orElse: () => Patient(
          id: 'unknown',
          name: 'Unknown',
          age: 0,
          diagnosis: 'Unknown',
          doctorId: '',
          deviceId: '',
        ),
      );

      return DataRow(
        cells: [
          DataCell(Text(appointment.id), onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailsPage(appointment: appointment),
              ),
            );
          }),
          DataCell(Text(doctor.name)),
          DataCell(Text(patient.name)),
          DataCell(Text(DateFormat('yyyy-MM-dd').format(appointment.dateTime))),
          DataCell(Text(appointment.status)),
        ],
      );
    }).toList();

    return Column(
      children: [
        // Search Bar for Appointments
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Appointments',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (value) {
              setState(() {
                _searchQueryAppointments = value;
              });
            },
          ),
        ),
        // Appointments DataTable
        Expanded(
          child: appointments.isEmpty
              ? Center(child: Text('No appointments found.'))
              : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: columns,
                rows: rows,
                headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[200]!),
                dataRowHeight: 60,
                columnSpacing: 20,
                onSelectAll: null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Devices Section
  Widget _buildDevicesSection(DataProvider dataProvider) {
    List<Device> devices = dataProvider.devices.where((d) {
      if (d.patientId.isEmpty) return false;
      Patient patient = dataProvider.patients.firstWhere(
            (p) => p.id == d.patientId,
        orElse: () => Patient(
          id: 'unknown',
          name: 'Unassigned',
          age: 0,
          diagnosis: 'Unknown',
          doctorId: '',
          deviceId: '',
        ),
      );
      if (patient.doctorId.isEmpty) return false;
      Doctor doctor = dataProvider.doctors.firstWhere(
            (d) => d.id == patient.doctorId,
        orElse: () => Doctor(
          id: 'unknown',
          name: 'Unknown',
          specialization: 'Unknown',
          hospitalId: 'unknown',
        ),
      );
      return doctor.hospitalId == widget.hospital.id;
    }).where((d) => d.type.toLowerCase().contains(_searchQueryDevices.toLowerCase())).toList();

    // Define DataTable Columns
    final columns = [
      DataColumn(label: Text('Device ID')),
      DataColumn(label: Text('Type')),
      DataColumn(label: Text('Assigned To')),
      DataColumn(label: Text('Doctor')),
    ];

    // Define DataTable Rows
    final rows = devices.map((device) {
      Patient patient = dataProvider.patients.firstWhere(
            (p) => p.id == device.patientId,
        orElse: () => Patient(
          id: 'unknown',
          name: 'Unassigned',
          age: 0,
          diagnosis: 'Unknown',
          doctorId: '',
          deviceId: '',
        ),
      );
      Doctor doctor = dataProvider.doctors.firstWhere(
            (d) => d.id == patient.doctorId,
        orElse: () => Doctor(
          id: 'unknown',
          name: 'Unknown',
          specialization: 'Unknown',
          hospitalId: 'unknown',
        ),
      );

      return DataRow(
        cells: [
          DataCell(Text(device.id), onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeviceDetailsPage(device: device),
              ),
            );
          }),
          DataCell(Text(device.type)),
          DataCell(Text(patient.name != 'Unknown' ? patient.name : 'Unassigned')),
          DataCell(Text(doctor.name)),
        ],
      );
    }).toList();

    return Column(
      children: [
        // Search Bar for Devices
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Devices',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (value) {
              setState(() {
                _searchQueryDevices = value;
              });
            },
          ),
        ),
        // Devices DataTable
        Expanded(
          child: devices.isEmpty
              ? Center(child: Text('No devices found.'))
              : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: columns,
                rows: rows,
                headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[200]!),
                dataRowHeight: 60,
                columnSpacing: 20,
                onSelectAll: null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('${widget.hospital.name} Details'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [

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

/// Patient Details Page
class PatientDetailsPage extends StatelessWidget {
  final Patient patient;

  const PatientDetailsPage({required this.patient, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    Doctor doctor = dataProvider.doctors.firstWhere(
          (d) => d.id == patient.doctorId,
      orElse: () => Doctor(
        id: 'unknown',
        name: 'Unknown',
        specialization: 'Unknown',
        hospitalId: 'unknown',
      ),
    );
    Device device = dataProvider.devices.firstWhere(
          (d) => d.id == patient.deviceId,
      orElse: () => Device(
        id: 'unknown',
        type: 'Unassigned',
        patientId: '',
      ),
    );
    List<Appointment> appointments = dataProvider.appointments.where((a) => a.patientId == patient.id).toList();

    // Define Appointments DataTable Columns
    final columns = [
      DataColumn(label: Text('Appointment ID')),
      DataColumn(label: Text('Doctor')),
      DataColumn(label: Text('Date')),
      DataColumn(label: Text('Status')),
    ];

    // Define Appointments DataTable Rows
    final rows = appointments.map((appointment) {
      Doctor apptDoctor = dataProvider.doctors.firstWhere(
            (d) => d.id == appointment.doctorId,
        orElse: () => Doctor(
          id: 'unknown',
          name: 'Unknown',
          specialization: 'Unknown',
          hospitalId: 'unknown',
        ),
      );

      return DataRow(
        cells: [
          DataCell(Text(appointment.id), onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailsPage(appointment: appointment),
              ),
            );
          }),
          DataCell(Text(apptDoctor.name)),
          DataCell(Text(DateFormat('yyyy-MM-dd').format(appointment.dateTime))),
          DataCell(Text(appointment.status)),
        ],
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${patient.name} Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Patient Information
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                title: Text(patient.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Age: ${patient.age}'),
                    Text('Diagnosis: ${patient.diagnosis}'),
                    Text('Doctor: ${doctor.name}'),
                    Text('Device: ${device.type != 'Unassigned' ? device.type : 'Unassigned'}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Appointments History
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Appointments History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  appointments.isEmpty
                      ? Center(child: Text('No appointments found.'))
                      : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: columns,
                        rows: rows,
                        headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[200]!),
                        dataRowHeight: 60,
                        columnSpacing: 20,
                        onSelectAll: null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Doctor Details Page
class DoctorDetailsPage extends StatelessWidget {
  final Doctor doctor;

  const DoctorDetailsPage({required this.doctor, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    List<Patient> patients = dataProvider.patients.where((p) => p.doctorId == doctor.id).toList();
    List<Appointment> appointments = dataProvider.appointments.where((a) => a.doctorId == doctor.id).toList();
    List<Device> devices = dataProvider.devices.where((d) => d.patientId.isNotEmpty && dataProvider.patients.any((p) => p.id == d.patientId && p.doctorId == doctor.id)).toList();

    // Define Patients DataTable Columns
    final patientColumns = [
      DataColumn(label: Text('Name')),
      DataColumn(label: Text('Diagnosis')),
    ];

    // Define Patients DataTable Rows
    final patientRows = patients.map((patient) {
      return DataRow(
        cells: [
          DataCell(Text(patient.name), onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailsPage(patient: patient),
              ),
            );
          }),
          DataCell(Text(patient.diagnosis)),
        ],
      );
    }).toList();

    // Define Devices DataTable Columns
    final deviceColumns = [
      DataColumn(label: Text('Device ID')),
      DataColumn(label: Text('Type')),
      DataColumn(label: Text('Assigned To')),
    ];

    // Define Devices DataTable Rows
    final deviceRows = devices.map((device) {
      Patient patient = dataProvider.patients.firstWhere(
            (p) => p.id == device.patientId,
        orElse: () => Patient(
          id: 'unknown',
          name: 'Unassigned',
          age: 0,
          diagnosis: 'Unknown',
          doctorId: '',
          deviceId: '',
        ),
      );

      return DataRow(
        cells: [
          DataCell(Text(device.id), onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeviceDetailsPage(device: device),
              ),
            );
          }),
          DataCell(Text(device.type)),
          DataCell(Text(patient.name)),
        ],
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${doctor.name} Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Doctor Information
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                title: Text(doctor.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                subtitle: Text('Specialization: ${doctor.specialization}'),
              ),
            ),
            SizedBox(height: 20),
            // Patients Managed
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patients Managed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  patients.isEmpty
                      ? Center(child: Text('No patients found.'))
                      : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: patientColumns,
                        rows: patientRows,
                        headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[200]!),
                        dataRowHeight: 60,
                        columnSpacing: 20,
                        onSelectAll: null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Devices Assigned
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Devices Assigned', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  devices.isEmpty
                      ? Center(child: Text('No devices assigned.'))
                      : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: deviceColumns,
                        rows: deviceRows,
                        headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[200]!),
                        dataRowHeight: 60,
                        columnSpacing: 20,
                        onSelectAll: null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Device Details Page
class DeviceDetailsPage extends StatelessWidget {
  final Device device;

  const DeviceDetailsPage({required this.device, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    Patient patient = dataProvider.patients.firstWhere(
          (p) => p.id == device.patientId,
      orElse: () => Patient(
        id: 'unknown',
        name: 'Unassigned',
        age: 0,
        diagnosis: 'Unknown',
        doctorId: '',
        deviceId: '',
      ),
    );
    Doctor doctor = dataProvider.doctors.firstWhere(
          (d) => d.id == patient.doctorId,
      orElse: () => Doctor(
        id: 'unknown',
        name: 'Unknown',
        specialization: 'Unknown',
        hospitalId: 'unknown',
      ),
    );

    // Fetch all patients assigned to this device
    List<Patient> assignedPatients = dataProvider.patients.where((p) => p.deviceId == device.id).toList();

    // Define Assigned Patients DataTable Columns
    final patientColumns = [
      DataColumn(label: Text('Name')),
      DataColumn(label: Text('Diagnosis')),
    ];

    // Define Assigned Patients DataTable Rows
    final patientRows = assignedPatients.map((p) {
      return DataRow(
        cells: [
          DataCell(Text(p.name), onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailsPage(patient: p),
              ),
            );
          }),
          DataCell(Text(p.diagnosis)),
        ],
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Device Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Device Information
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                title: Text('Device ID: ${device.id}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                subtitle: Text('Type: ${device.type}'),
              ),
            ),
            SizedBox(height: 20),
            // Assigned To
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                title: Text('Assigned To: ${patient.name}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                subtitle: Text('Doctor: ${doctor.name}'),
                onTap: () {
                  if (patient.id != 'unknown') {
                    // Navigate to Patient Details Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientDetailsPage(patient: patient),
                      ),
                    );
                  }
                },
              ),
            ),
            SizedBox(height: 20),
            // Assigned Patients
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assigned Patients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  assignedPatients.isEmpty
                      ? Center(child: Text('No patients assigned to this device.'))
                      : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: patientColumns,
                        rows: patientRows,
                        headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[200]!),
                        dataRowHeight: 60,
                        columnSpacing: 20,
                        onSelectAll: null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Appointment Details Page
class AppointmentDetailsPage extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailsPage({required this.appointment, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    Doctor doctor = dataProvider.doctors.firstWhere(
          (d) => d.id == appointment.doctorId,
      orElse: () => Doctor(
        id: 'unknown',
        name: 'Unknown',
        specialization: 'Unknown',
        hospitalId: 'unknown',
      ),
    );
    Patient patient = dataProvider.patients.firstWhere(
          (p) => p.id == appointment.patientId,
      orElse: () => Patient(
        id: 'unknown',
        name: 'Unknown',
        age: 0,
        diagnosis: 'Unknown',
        doctorId: '',
        deviceId: '',
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Appointment Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Appointment Information
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                title: Text('Appointment ID: ${appointment.id}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Doctor: ${doctor.name}'),
                    Text('Patient: ${patient.name}'),
                    Text('Date: ${DateFormat('yyyy-MM-dd').format(appointment.dateTime)}'),
                    Text('Status: ${appointment.status}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Additional Information or Actions
            // Add any other relevant information or actions here
          ],
        ),
      ),
    );
  }
}
