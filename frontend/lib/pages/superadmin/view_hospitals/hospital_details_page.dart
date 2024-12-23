// lib/pages/superadmin/view_hospitals/hospital_details_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/data_provider.dart';
import '../../../models/hospital.dart';
import '../../../models/patient.dart';
import '../../../models/doctor.dart';
import '../../../models/appointment.dart';
import '../../../models/device.dart';
import 'package:intl/intl.dart';
import '../../../shared/components/custom_paginated_table.dart'; // Import the new widget

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

  // Patients Section using CustomPaginatedTable
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

    // Prepare data for CustomPaginatedTable
    List<String> columns = ['ID', 'Name', 'Age', 'Diagnosis', 'Doctor', 'Device'];
    List<Map<String, dynamic>> data = patients.map((patient) {
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

      return {
        'ID': patient.id,
        'Name': patient.name,
        'Age': patient.age,
        'Diagnosis': patient.diagnosis,
        'Doctor': doctor.name,
        'Device': device.type != 'Unassigned' ? device.type : 'Unassigned',
      };
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
          child: data.isEmpty
              ? Center(child: Text('No patients found.'))
              : CustomPaginatedTable(
            data: data,
            columns: columns,
            tableTitle: 'Patients',
            onRowTap: (Map<String, dynamic> row) {
              // Navigate to Patient Details Page
              Patient selectedPatient = dataProvider.patients.firstWhere(
                    (p) => p.id == row['ID'],
                orElse: () => Patient(
                  id: 'unknown',
                  name: 'Unknown',
                  age: 0,
                  diagnosis: 'Unknown',
                  doctorId: '',
                  deviceId: '',
                ),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientDetailsPage(patient: selectedPatient),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Doctors Section using CustomPaginatedTable
  Widget _buildDoctorsSection(DataProvider dataProvider) {
    List<Doctor> doctors = dataProvider.doctors
        .where((d) => d.hospitalId == widget.hospital.id)
        .where((d) =>
    d.name.toLowerCase().contains(_searchQueryDoctors.toLowerCase()) ||
        d.specialization.toLowerCase().contains(_searchQueryDoctors.toLowerCase()))
        .toList();

    // Prepare data for CustomPaginatedTable
    List<String> columns = ['ID', 'Name', 'Specialization'];
    List<Map<String, dynamic>> data = doctors.map((doctor) {
      return {
        'ID': doctor.id,
        'Name': doctor.name,
        'Specialization': doctor.specialization,
      };
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
          child: data.isEmpty
              ? Center(child: Text('No doctors found.'))
              : CustomPaginatedTable(
            data: data,
            columns: columns,
            tableTitle: 'Doctors',
            onRowTap: (Map<String, dynamic> row) {
              // Navigate to Doctor Details Page
              Doctor selectedDoctor = dataProvider.doctors.firstWhere(
                    (d) => d.id == row['ID'],
                orElse: () => Doctor(
                  id: 'unknown',
                  name: 'Unknown',
                  specialization: 'Unknown',
                  hospitalId: 'unknown',
                ),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorDetailsPage(doctor: selectedDoctor),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Appointments Section using CustomPaginatedTable
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

    // Prepare data for CustomPaginatedTable
    List<String> columns = ['ID', 'Doctor', 'Patient', 'Date', 'Status'];
    List<Map<String, dynamic>> data = appointments.map((appointment) {
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

      return {
        'ID': appointment.id,
        'Doctor': doctor.name,
        'Patient': patient.name,
        'Date': appointment.dateTime,
        'Status': appointment.status,
      };
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
          child: data.isEmpty
              ? Center(child: Text('No appointments found.'))
              : CustomPaginatedTable(
            data: data,
            columns: columns,
            tableTitle: 'Appointments',
            onRowTap: (Map<String, dynamic> row) {
              // Navigate to Appointment Details Page
              Appointment selectedAppointment = dataProvider.appointments.firstWhere(
                    (a) => a.id == row['ID'],
                orElse: () => Appointment(
                  id: 'unknown',
                  doctorId: 'unknown',
                  patientId: 'unknown',
                  dateTime: DateTime.now(),
                  status: 'Unknown',
                ),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentDetailsPage(appointment: selectedAppointment),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Devices Section using CustomPaginatedTable
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

    // Prepare data for CustomPaginatedTable
    List<String> columns = ['ID', 'Type', 'Patient', 'Doctor'];
    List<Map<String, dynamic>> data = devices.map((device) {
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

      return {
        'ID': device.id,
        'Type': device.type,
        'Patient': patient.name != 'Unknown' ? patient.name : 'Unassigned',
        'Doctor': doctor.name,
      };
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
          child: data.isEmpty
              ? Center(child: Text('No devices found.'))
              : CustomPaginatedTable(
            data: data,
            columns: columns,
            tableTitle: 'Devices',
            onRowTap: (Map<String, dynamic> row) {
              // Navigate to Device Details Page
              Device selectedDevice = dataProvider.devices.firstWhere(
                    (d) => d.id == row['ID'],
                orElse: () => Device(
                  id: 'unknown',
                  type: 'Unassigned',
                  patientId: '',
                ),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeviceDetailsPage(device: selectedDevice),
                ),
              );
            },
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

/// Extension methods for models to convert to Map
extension PatientExtension on Patient {
  Map<String, dynamic> toMap() {
    return {
      'ID': id,
      'Name': name,
      'Age': age,
      'Diagnosis': diagnosis,
      'Doctor': doctorId,
      'Device': deviceId,
    };
  }
}

extension DoctorExtension on Doctor {
  Map<String, dynamic> toMap() {
    return {
      'ID': id,
      'Name': name,
      'Specialization': specialization,
    };
  }
}

extension AppointmentExtension on Appointment {
  Map<String, dynamic> toMap() {
    return {
      'ID': id,
      'Doctor': doctorId,
      'Patient': patientId,
      'Date': dateTime,
      'Status': status,
    };
  }
}

extension DeviceExtension on Device {
  Map<String, dynamic> toMap() {
    return {
      'ID': id,
      'Type': type,
      'Patient': patientId,
    };
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
                  Expanded(
                    child: appointments.isEmpty
                        ? Center(child: Text('No appointments found.'))
                        : ListView.builder(
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final appointment = appointments[index];
                        Doctor apptDoctor = dataProvider.doctors.firstWhere(
                              (d) => d.id == appointment.doctorId,
                          orElse: () => Doctor(
                            id: 'unknown',
                            name: 'Unknown',
                            specialization: 'Unknown',
                            hospitalId: 'unknown',
                          ),
                        );

                        return Card(
                          elevation: 1,
                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                          child: ListTile(
                            title: Text('Appointment ID: ${appointment.id}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Doctor: ${apptDoctor.name}'),
                                Text('Date: ${DateFormat('yyyy-MM-dd').format(appointment.dateTime)}'),
                                Text('Status: ${appointment.status}'),
                              ],
                            ),
                            onTap: () {
                              // Navigate to Appointment Details Page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AppointmentDetailsPage(appointment: appointment),
                                ),
                              );
                            },
                          ),
                        );
                      },
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
    List<Device> devices = dataProvider.devices
        .where((d) => d.patientId.isNotEmpty && dataProvider.patients.any((p) => p.id == d.patientId && p.doctorId == doctor.id))
        .toList();

    // Prepare data for CustomPaginatedTable
    List<String> patientColumns = ['ID', 'Name', 'Diagnosis'];
    List<Map<String, dynamic>> patientData = patients.map((p) {
      return {
        'ID': p.id,
        'Name': p.name,
        'Diagnosis': p.diagnosis,
      };
    }).toList();

    List<String> deviceColumns = ['ID', 'Type', 'Patient'];
    List<Map<String, dynamic>> deviceData = devices.map((d) {
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
      return {
        'ID': d.id,
        'Type': d.type,
        'Patient': patient.name != 'Unknown' ? patient.name : 'Unassigned',
      };
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
                  Expanded(
                    child: patients.isEmpty
                        ? Center(child: Text('No patients found.'))
                        : CustomPaginatedTable(
                      data: patientData,
                      columns: patientColumns,
                      tableTitle: 'Patients Managed',
                      onRowTap: (Map<String, dynamic> row) {
                        // Navigate to Patient Details Page
                        Patient selectedPatient = dataProvider.patients.firstWhere(
                              (p) => p.id == row['ID'],
                          orElse: () => Patient(
                            id: 'unknown',
                            name: 'Unknown',
                            age: 0,
                            diagnosis: 'Unknown',
                            doctorId: '',
                            deviceId: '',
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientDetailsPage(patient: selectedPatient),
                          ),
                        );
                      },
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
                  Expanded(
                    child: devices.isEmpty
                        ? Center(child: Text('No devices assigned.'))
                        : CustomPaginatedTable(
                      data: deviceData,
                      columns: deviceColumns,
                      tableTitle: 'Devices Assigned',
                      onRowTap: (Map<String, dynamic> row) {
                        // Navigate to Device Details Page
                        Device selectedDevice = dataProvider.devices.firstWhere(
                              (d) => d.id == row['ID'],
                          orElse: () => Device(
                            id: 'unknown',
                            type: 'Unassigned',
                            patientId: '',
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeviceDetailsPage(device: selectedDevice),
                          ),
                        );
                      },
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

    // Prepare data for CustomPaginatedTable
    List<String> patientColumns = ['ID', 'Name', 'Diagnosis'];
    List<Map<String, dynamic>> patientData = assignedPatients.map((p) {
      return {
        'ID': p.id,
        'Name': p.name,
        'Diagnosis': p.diagnosis,
      };
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
                  Expanded(
                    child: assignedPatients.isEmpty
                        ? Center(child: Text('No patients assigned to this device.'))
                        : CustomPaginatedTable(
                      data: patientData,
                      columns: patientColumns,
                      tableTitle: 'Assigned Patients',
                      onRowTap: (Map<String, dynamic> row) {
                        // Navigate to Patient Details Page
                        Patient selectedPatient = dataProvider.patients.firstWhere(
                              (p) => p.id == row['ID'],
                          orElse: () => Patient(
                            id: 'unknown',
                            name: 'Unassigned',
                            age: 0,
                            diagnosis: 'Unknown',
                            doctorId: '',
                            deviceId: '',
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientDetailsPage(patient: selectedPatient),
                          ),
                        );
                      },
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
