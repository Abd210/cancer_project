const Doctor = require("../Models/Doctor");
const mongoose = require("mongoose");

/**
 * DoctorService provides functionality related to managing doctor data.
 * This includes methods for retrieving public information about doctors.
 * Sensitive data, such as personal ID, password, and timestamps, are excluded
 * from the data returned to ensure privacy and security.
 */
class DoctorService {

   /**
   * Retrieves the public information of a doctor, excluding sensitive fields.
   * 
   * @param {string} _id - The ID of the doctor whose public data is being retrieved.
   * @returns {Object} The public data of the doctor or an error message.
   * @throws Throws an error if the doctor is not found or any other issue occurs.
   */
  static async getPublicData(_id) {
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

      // If the doctor is not found, throw an error
      if (!doctor) {
        throw new Error("Doctor not found");
      }

      return doctor; // Returns the doctor's public data without sensitive information
    } catch (getDoctorPublicDataError) {
      return { error: getDoctorPublicDataError.message };
    }
  }
}

module.exports = DoctorService;
