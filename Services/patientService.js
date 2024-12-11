// services/patientService.js
const Patient = require("../Models/Patient");
const mongoose = require("mongoose");

class PatientService {
  static async getDiagnosis({ patient_id }) {
    if (!mongoose.isValidObjectId(patient_id)) {
      throw new Error("patientService-getPatientData: Invalid patient_id");
    }

    // Find the patient and exclude _id from the result
    const patient = await this.findPatient(patient_id);

    if (!patient) {
      throw new Error("Patient not found");
    }

    return patient.diagnosis; // Returns the entire Patient object excluding _id
  }

  static async findPatient(patient_id) {
    if (!mongoose.isValidObjectId(patient_id)) {
      throw new Error("patientService-find patient: Invalid patient id");
    }

    return await Patient.findOne({ _id: patient_id });
  }
}

module.exports = PatientService;
