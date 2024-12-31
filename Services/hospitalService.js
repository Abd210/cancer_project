const Hospital = require("../Models/Hospital");
const Patient = require("../Models/Patient");
const Doctor = require("../Models/Doctor");
const Appointment = require("../Models/Appointment");
const Test = require("../Models/Test");
const Admin = require("../Models/Admin");
const mongoose = require("mongoose");

class HospitalService {
  static async register({ hospital_name, hospital_address, mobile_numbers, emails,}) {
    /**Create a new Hospital instance to validate data*/
    const hospital = new Hospital({
      hospital_name,
      hospital_address,
      mobile_numbers,
      emails,
    });

    /**Check if there's any other hospital with the same name and address*/
    const existingHospital = await Hospital.findOne({
      hospital_name,
      hospital_address,
    });

    if (existingHospital) {
      throw new Error(
        "HospitalService-Register: A hospital with the same name and address already exists."
      );
    }

    /**Validate the data against the schema*/
    const validationError = hospital.validateSync();
    if (validationError) {
      throw new Error(
        `HospitalService-Register-Validation Error: ${validationError.message}`
      );
    }

    /**Save the hospital to the database*/
    const result = await hospital.save();
    return result;
  }

  static async deleteHospital(hospitalId) {
    try {
      // Validate hospital ID
      if (!mongoose.isValidObjectId(hospitalId)) {
        throw new Error("HospitalService-Delete: Invalid hospital ID");
      }

      // Check if the hospital exists
      const hospital = await Hospital.findById(hospitalId);
      if (!hospital) {
        throw new Error("HospitalService-Delete: Hospital not found");
      }

      // Find patients, doctors, and admins associated with the hospital
      const patients = await Patient.find({ hospital: hospitalId });
      const doctors = await Doctor.find({ hospital: hospitalId });
      const admins = await Admin.find({ hospital: hospitalId });

      // Collect IDs of patients, doctors, and admins
      const patientIds = patients.map((patient) => patient._id);
      const doctorIds = doctors.map((doctor) => doctor._id);
      const adminIds = admins.map((admin) => admin._id);

      // Delete all associated appointments and tests
      await Appointment.deleteMany({
        $or: [{ patient: { $in: patientIds } }, { doctor: { $in: doctorIds } }],
      });

      await Test.deleteMany({
        $or: [{ patient: { $in: patientIds } }, { doctor: { $in: doctorIds } }],
      });

      // Delete all associated patients, doctors, and admins
      await Patient.deleteMany({ hospital: hospitalId });
      await Doctor.deleteMany({ hospital: hospitalId });
      await Admin.deleteMany({ hospital: hospitalId });

      // Delete the hospital itself
      const deletedHospital = await Hospital.findByIdAndDelete(hospitalId);

      return {
        message: "Hospital and all associated data successfully deleted",
        deletedHospital,
      };
    } catch (error) {
      return { error: error.message };
    }
  }
}
module.exports = HospitalService;
