// lib/providers/data_provider.dart
import 'package:flutter/material.dart';
import '../models/hospital.dart';
import '../models/doctor.dart';
import '../models/patient.dart';
import '../models/device.dart';
import '../models/appointment.dart';
import '../models/ticket.dart';
import '../services/static_data.dart';

class DataProvider with ChangeNotifier {
  // Hospitals
  List<Hospital> _hospitals = StaticData.hospitals;

  List<Hospital> get hospitals => _hospitals;

  void addHospital(Hospital hospital) {
    _hospitals.add(hospital);
    notifyListeners();
  }

  void updateHospital(Hospital hospital) {
    int index = _hospitals.indexWhere((h) => h.id == hospital.id);
    if (index != -1) {
      _hospitals[index] = hospital;
      notifyListeners();
    }
  }

  void deleteHospital(String id) {
    // Before deleting a hospital, optionally handle related entities
    _hospitals.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  // Doctors
  List<Doctor> _doctors = StaticData.doctors;

  List<Doctor> get doctors => _doctors;

  void addDoctor(Doctor doctor) {
    _doctors.add(doctor);
    notifyListeners();
  }

  void updateDoctor(Doctor doctor) {
    int index = _doctors.indexWhere((d) => d.id == doctor.id);
    if (index != -1) {
      _doctors[index] = doctor;
      notifyListeners();
    }
  }

  void deleteDoctor(String id) {
    // Optionally handle related patients before deleting
    _doctors.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  // Devices
  List<Device> _devices = StaticData.devices;

  List<Device> get devices => _devices;

  void addDevice(Device device) {
    _devices.add(device);
    notifyListeners();
  }

  void updateDevice(Device device) {
    int index = _devices.indexWhere((d) => d.id == device.id);
    if (index != -1) {
      _devices[index] = device;
      notifyListeners();
    }
  }

  void deleteDevice(String id) {
    // Optionally unassign device from patient before deleting
    _devices.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  // Patients
  List<Patient> _patients = StaticData.patients;

  List<Patient> get patients => _patients;

  void addPatient(Patient patient) {
    // Check if the device is already assigned
    if (patient.deviceId.isNotEmpty) {
      bool isDeviceAssigned = _patients.any((p) => p.deviceId == patient.deviceId);
      if (isDeviceAssigned) {
        throw Exception('Device is already assigned to another patient.');
      }
    }
    _patients.add(patient);
    notifyListeners();
  }

  void updatePatient(Patient patient) {
    // Check if the new device is already assigned to another patient
    if (patient.deviceId.isNotEmpty) {
      bool isDeviceAssigned = _patients.any((p) => p.deviceId == patient.deviceId && p.id != patient.id);
      if (isDeviceAssigned) {
        throw Exception('Device is already assigned to another patient.');
      }
    }

    int index = _patients.indexWhere((p) => p.id == patient.id);
    if (index != -1) {
      _patients[index] = patient;
      notifyListeners();
    }
  }

  void deletePatient(String id) {
    // Unassign the device when deleting a patient
    Patient? patient = _patients.firstWhere((p) => p.id == id, orElse: () => throw Exception('Patient not found'));
    if (patient.deviceId.isNotEmpty) {
      Device? device = _devices.firstWhere((d) => d.id == patient.deviceId, orElse: () => throw Exception('Device not found'));
      device.patientId = '';
      notifyListeners();
    }
    _patients.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // Appointments
  List<Appointment> _appointments = StaticData.appointments;

  List<Appointment> get appointments => _appointments;

  void addAppointment(Appointment appointment) {
    _appointments.add(appointment);
    notifyListeners();
  }

  void updateAppointment(Appointment appointment) {
    int index = _appointments.indexWhere((a) => a.id == appointment.id);
    if (index != -1) {
      _appointments[index] = appointment;
      notifyListeners();
    }
  }

  void deleteAppointment(String id) {
    _appointments.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  // Tickets
  List<Ticket> _tickets = StaticData.tickets;

  List<Ticket> get tickets => _tickets;

  void addTicket(Ticket ticket) {
    _tickets.add(ticket);
    notifyListeners();
  }

  void approveTicket(String ticketId) {
    final ticket = _tickets.firstWhere((t) => t.id == ticketId, orElse: () => throw Exception('Ticket not found'));
    ticket.isApproved = true;
    notifyListeners();
  }

  void rejectTicket(String ticketId) {
    _tickets.removeWhere((t) => t.id == ticketId);
    notifyListeners();
  }
}
