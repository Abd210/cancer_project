// lib/providers/data_provider.dart
import 'package:flutter/material.dart';
import '../models/hospital.dart';
import '../models/doctor.dart';
import '../models/patient.dart';
import '../models/device.dart';
import '../models/appointment.dart';
import '../models/ticket.dart';
import '../services/static_data.dart';
import '../models/notification.dart' as custom;


class DataProvider with ChangeNotifier {
  // 1) Hospitals
  List<Hospital> _hospitals = StaticData.hospitals;
  List<Hospital> get hospitals => _hospitals;

  void addHospital(Hospital hospital) {
    _hospitals.add(hospital);
    notifyListeners();
  }
  // data_provider.dart

void unassignDeviceFromHospital(Device device, String hospitalId) {
  // 1) Find the patient for this device
  if (device.patientId.isEmpty) {
    // Already unassigned, do nothing
    return;
  }
  final patient = _patients.firstWhere(
    (p) => p.id == device.patientId,
    orElse: () => Patient(
      id: '',
      name: '',
      age: 0,
      diagnosis: '',
      doctorId: '',
      deviceId: '',
    ),
  );
  // 2) Check if that patient belongs to the given hospital
  if (patient.id.isEmpty) {
    // Means device was assigned to no one or not found, do nothing
    return;
  }
  final doctor = _doctors.firstWhere(
    (d) => d.id == patient.doctorId,
    orElse: () => Doctor(
      id: '',
      name: '',
      specialization: '',
      hospitalId: '',
    ),
  );
  if (doctor.hospitalId == hospitalId) {
    // 3) Unassign from patient
    //    Remove the link on both sides: device -> patient, patient -> device
    //    If you store deviceId in Patient, set it = ''
    patient.deviceId = '';
    // Then find the Device in _devices
    int index = _devices.indexWhere((d) => d.id == device.id);
    if (index != -1) {
      _devices[index].patientId = '';
    }
    notifyListeners();
  }
}
List<Patient> getPatientsForDoctor(String doctorId) {
  return _patients.where((patient) => patient.doctorId == doctorId).toList();
}
List<Appointment> getAppointmentsForDoctor(String doctorId) {
  return _appointments.where((appointment) => appointment.doctorId == doctorId).toList();
}

Doctor? findDoctorByUsername(String username) {
  try {
    return _doctors.firstWhere(
      (doctor) => doctor.name.toLowerCase() == username.toLowerCase(),
    );
  } catch (e) {
    return null; // Return null if no doctor matches the username
  }
}

  void updateHospital(Hospital hospital) {
    int index = _hospitals.indexWhere((h) => h.id == hospital.id);
    if (index != -1) {
      _hospitals[index] = hospital;
      notifyListeners();
    }
  }

  void deleteHospital(String id) {
    // (Optional) Before deleting, handle related entities
    _hospitals.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  // 2) Doctors
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
    // (Optional) handle related patients
    _doctors.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  // 3) Devices
  List<Device> _devices = StaticData.devices;
  List<Device> get devices => _devices;

  /// Add a device ensuring no two devices share the same `patientId`
  void addDevice(Device device) {
    // If the device is assigned to a patient, ensure that patient is free
    if (device.patientId.isNotEmpty) {
      bool assignedElsewhere = _devices.any(
        (d) => d.patientId == device.patientId,
      );
      if (assignedElsewhere) {
        throw Exception('This patient already has a device assigned!');
      }
    }
    _devices.add(device);
    notifyListeners();
  }

  /// Update a device ensuring the new `patientId` doesn't conflict
  void updateDevice(Device device) {
    // Check for conflict
    if (device.patientId.isNotEmpty) {
      bool assignedElsewhere = _devices.any(
        (d) => d.id != device.id && d.patientId == device.patientId,
      );
      if (assignedElsewhere) {
        throw Exception('This patient already has a device assigned!');
      }
    }
    // Actual update
    int index = _devices.indexWhere((d) => d.id == device.id);
    if (index != -1) {
      _devices[index] = device;
      notifyListeners();
    }
  }

  void deleteDevice(String id) {
    // (Optional) unassign device from the patient
    // But your code doesn't store deviceId in the Patient, so not needed.
    _devices.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  // 4) Patients
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
      bool isDeviceAssigned = _patients.any(
        (p) => p.deviceId == patient.deviceId && p.id != patient.id,
      );
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
    Patient? patient = _patients.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Patient not found'),
    );
    if (patient.deviceId.isNotEmpty) {
      Device? device = _devices.firstWhere(
        (d) => d.id == patient.deviceId,
        orElse: () => throw Exception('Device not found'),
      );
      device.patientId = ''; // Unassign
      notifyListeners();
    }
    _patients.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // 5) Appointments
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
  

  // 6) Tickets
  List<Ticket> _tickets = StaticData.tickets;
  List<Ticket> get tickets => _tickets;

  void addTicket(Ticket ticket) {
    _tickets.add(ticket);
    notifyListeners();
  }

  void approveTicket(String ticketId) {
    final ticket = _tickets.firstWhere(
      (t) => t.id == ticketId,
      orElse: () => throw Exception('Ticket not found'),
    );
    ticket.isApproved = true;
    notifyListeners();
  }

  void rejectTicket(String ticketId) {
    _tickets.removeWhere((t) => t.id == ticketId);
    notifyListeners();
  }
// Notifications
List<custom.Notification> _notifications = [];
List<custom.Notification> get notifications => _notifications;

// Add a notification
void addNotification(String message) {
  _notifications.add(custom.Notification(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    message: message,
    timestamp: DateTime.now(),
  ));
  notifyListeners();
}


// Approve appointment request
void approveAppointmentRequest(String notificationId, Appointment appointment) {
  _appointments.add(appointment);
  _notifications.removeWhere((n) => n.id == notificationId);
  addNotification("Appointment with ${appointment.patientId} has been approved.");
  notifyListeners();
}

// Reject appointment request
void rejectAppointmentRequest(String notificationId) {
  _notifications.removeWhere((n) => n.id == notificationId);
  addNotification("An appointment request was rejected.");
  notifyListeners();
}
// lib/providers/data_provider.dart

// Add notification management for appointment cancellation and rescheduling
void addAppointmentCancelledNotification(String appointmentId, String patientId) {
  _notifications.add(custom.Notification(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    message: "Appointment with $patientId has been canceled.",
    timestamp: DateTime.now(),
  ));
  notifyListeners();
}

void addAppointmentRescheduledNotification(String appointmentId, String patientId, DateTime newDateTime) {
  _notifications.add(custom.Notification(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    message: "Appointment with $patientId has been rescheduled to ${newDateTime.toLocal()}",
    timestamp: DateTime.now(),
  ));
  notifyListeners();
}

// Add method to handle patient cancellation requests
void handlePatientCancellationRequest(String notificationId, String appointmentId, bool approve) {
  final appointment = _appointments.firstWhere(
    (a) => a.id == appointmentId,
    orElse: () => throw Exception('Appointment not found'),
  );

  if (approve) {
    // Approve cancellation
    _appointments.removeWhere((a) => a.id == appointmentId);
    addAppointmentCancelledNotification(appointmentId, appointment.patientId);
  } else {
    // Disapprove cancellation
    addNotification("Cancellation request for appointment with ${appointment.patientId} was disapproved.");
  }

  // Remove the notification
  _notifications.removeWhere((n) => n.id == notificationId);
  notifyListeners();
}

}
