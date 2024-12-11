const Doctor = require("../Models/Doctor");
const mongoose = require("mongoose");

class DoctorService {
  static async getPublicData({ _id }) {
    try {
      // Find the doctor and exclude sensitive fields
      const doctor = await Doctor.findOne(
        { _id, role: "doctor" },
        {
          pers_id: 0, // Exclude the personal ID
          password: 0, // Exclude the password
          role: 0, // Exclude the role field
          createdAt: 0, // Exclude the createdAt field
          updatedAt: 0, // Exclude the updatedAt field
        }
      );

      if (!doctor) {
        throw new Error("Doctor not found");
      }

      return doctor; // Returns the public data of the doctor
    } catch (getDoctorPublicDataError) {
      return { error: getDoctorPublicDataError.message };
    }
  }
}

module.exports = DoctorService;
