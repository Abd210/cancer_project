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
  }

  static async getDoctorData(_id) {
    // Find the doctor and include all fields
    const doctor = await Doctor.findOne(
      { _id, role: "doctor" } // Filter by _id and role
    );

    // If the doctor is not found, throw an error
    if (!doctor) {
        throw new Error("Doctor not found");
    }

    return doctor; // Returns the full doctor's data
  }

  static async updateDoctor(doctorId, updateFields) {
    // Validate the doctorId as a valid MongoDB ObjectId
    if (!mongoose.isValidObjectId(doctorId)) {
      throw new Error("doctorService-update doctor: Invalid doctorId");
    }

    // Prevent updating the _id field
    if (updateFields._id) {
        throw new Error("doctorService-update doctor: Changing the '_id' field is not allowed");
    }

    // Prevent updating the role field
    if (updateFields.role) {
        throw new Error("doctorService-update doctor: Changing the 'role' field is not allowed");
    }

    // Check if the new pers_id is being updated
    if (updateFields.pers_id) {
      const existingDoctor = await Doctor.findOne({ pers_id: updateFields.pers_id });
      if (existingDoctor && existingDoctor._id.toString() !== doctorId) {
        throw new Error(
          `doctorService-update doctor: The pers_id '${updateFields.pers_id}' is already in use by another doctor`
        );
      }
    }

    // Check if the new email is being updated
    if (updateFields.email) {
        const existingDoctor = await Doctor.findOne({ email: updateFields.email });
        if (existingDoctor && existingDoctor._id.toString() !== doctorId) {
            throw new Error(
                `doctorService-update doctor: The email '${updateFields.email}' is already in use by another doctor`
            );
        }
    }

    // Check if the new mobile_number is being updated
    if (updateFields.mobile_number) {
        const existingDoctor = await Doctor.findOne({ mobile_number: updateFields.mobile_number });
        if (existingDoctor && existingDoctor._id.toString() !== doctorId) {
            throw new Error(
                `doctorService-update doctor: The mobile number '${updateFields.mobile_number}' is already in use by another doctor`
            );
        }
    }

    // Check if the password is being updated and hash it
    if (updateFields.password) {
        const salt = await bcrypt.genSalt(10);
        updateFields.password = await bcrypt.hash(updateFields.password, salt);
    }

    // Perform the update
    const updatedDoctor = await Doctor.findByIdAndUpdate(
        doctorId,
        { $set: updateFields }, // Update only the provided fields
        { new: true, runValidators: true } // Return the updated document and run schema validators
    );

    if (!updatedDoctor) {
        throw new Error("doctorService-update doctor: Doctor not found");
    }

    return updatedDoctor;
  }


}

module.exports = DoctorService;