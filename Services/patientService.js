// services/patientService.js
const Patient = require("../Models/Patient");
const mongoose = require("mongoose");

class PatientService {
  static async findPatient(patient_id) {
    try {
      if (!mongoose.isValidObjectId(patient_id)) {
        throw new Error("patientService-find patient: Invalid patient id");
      }

      return await Patient.findOne({ _id: patient_id });
    } catch (findPatientError) {
      return { error: findPatientError.message };
    }
  }

  static async findAllPatients() {
    try {
      // Fetch all patient data
      return await Patient.find({});
    } catch (findAllPatientsError) {
      return { error: findAllPatientsError.message };
    }
  }
}

module.exports = PatientService;
