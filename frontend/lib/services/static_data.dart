// lib/services/static_data.dart
import '../models/hospital.dart';
import '../models/doctor.dart';
import '../models/patient.dart';
import '../models/device.dart';
import '../models/appointment.dart';
import '../models/ticket.dart';

class StaticData {
  static List<Hospital> hospitals = List.generate(
    50,
        (index) => Hospital(
      id: 'h$index',
      name: 'Hospital ${index + 1}',
      address: '123${index} Main St, City',
    ),
  );

  static List<Doctor> doctors = List.generate(
    50,
        (index) => Doctor(
      id: 'd$index',
      name: 'Dr. Smith $index',
      specialization: 'Oncologist',
      hospitalId: hospitals[index % hospitals.length].id,
    ),
  );

  static List<Device> devices = List.generate(
    50,
        (index) => Device(
      id: 'dev$index',
      type: 'Breast Cancer Device ${index + 1}',
      patientId: '', // Initially unassigned
    ),
  );

  static List<Patient> patients = List.generate(
    50,
        (index) => Patient(
      id: 'p$index',
      name: 'Patient ${index + 1}',
      age: 30 + (index % 50),
      diagnosis: 'Breast Cancer',
      doctorId: doctors[index % doctors.length].id,
      deviceId: '', // Initially unassigned
    ),
  );

  static List<Appointment> appointments = List.generate(
    50,
        (index) => Appointment(
      id: 'a$index',
      patientId: patients[index % patients.length].id,
      doctorId: doctors[index % doctors.length].id,
      dateTime: DateTime.now().add(Duration(days: index % 30)),
      status: 'Scheduled',
    ),
  );

  static List<Ticket> tickets = List.generate(
    50,
        (index) => Ticket(
      id: 't$index',
      requester: 'Requester ${index + 1}',
      requestType: 'Data Update',
      description: 'Request description $index',
      date: DateTime.now().subtract(Duration(days: index)),
    ),
  );

  // Optionally, assign some devices to patients uniquely
  static void assignDevicesToPatients() {
    for (int i = 0; i < devices.length && i < patients.length; i++) {
      devices[i].patientId = patients[i].id;
      patients[i].deviceId = devices[i].id;
    }
  }
}
