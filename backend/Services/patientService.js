// Ensure all models are imported
const Patient = require("../Models/Patient");
const Doctor = require("../Models/Doctor");
const Admin = require("../Models/Admin");
const SuperAdmin = require("../Models/SuperAdmin");
const mongoose = require("mongoose");
const bcrypt = require("bcrypt");

class PatientService {
  static async findPatient(patient_id) {
    if (!mongoose.isValidObjectId(patient_id)) {
      throw new Error("patientService-find patient: Invalid patient id");
    }

    return await Patient.findOne({ _id: patient_id });
  }

  static async findAllPatients() {
    // Fetch all patient data
    return await Patient.find({});
  }


  static async updatePatient(patientId, updateFields, user) {
    // Validate the patientId as a valid MongoDB ObjectId
    if (!mongoose.isValidObjectId(patientId)) {
      throw new Error("patientService-update patient: Invalid patientId");
    }

    // Prevent updating the _id field
    if (updateFields._id) {
      throw new Error("patientService-update patient: Changing the '_id' field is not allowed");
    }

    // Prevent updating the role field
    if (updateFields.role) {
      throw new Error("patientService-update patient: Changing the 'role' field is not allowed");
    }

    // Internal helper function to check uniqueness across collections
    const checkUniqueness = async (field, value) => {
      const collections = [Patient, Doctor, Admin, SuperAdmin];
      for (const Collection of collections) {
        const existingUser = await Collection.findOne({ [field]: value });
        if (existingUser && existingUser._id.toString() !== patientId) {
          throw new Error(
            `patientService-update patient: The ${field} '${value}' is already in use by another user`
          );
        }
      }
    };

    // Check uniqueness for pers_id, email, and mobile_number
    if (updateFields.pers_id) {
      await checkUniqueness("pers_id", updateFields.pers_id);
    }
    if (updateFields.email) {
      await checkUniqueness("email", updateFields.email);
    }
    if (updateFields.mobile_number) {
      await checkUniqueness("mobile_number", updateFields.mobile_number);
    }

    // Check if the new pers_id is being updated
    // if (updateFields.pers_id) {
    //   const existingPatient = await Patient.findOne({ pers_id: updateFields.pers_id });
    //   if (existingPatient && existingPatient._id.toString() !== patientId) {
    //     throw new Error(
    //       `patientService-update patient: The pers_id '${updateFields.pers_id}' is already in use by another patient`
    //     );
    //   }
    // }

    // // Check if the new email is being updated
    // if (updateFields.email) {
    //   const existingPatient = await Patient.findOne({ email: updateFields.email });
    //   if (existingPatient && existingPatient._id.toString() !== patientId) {
    //     throw new Error(
    //       `patientService-update patient: The email '${updateFields.email}' is already in use by another patient`
    //     );
    //   }
    // }

    // // Check if the new mobile_number is being updated
    // if (updateFields.mobile_number) {
    //   const existingPatient = await Patient.findOne({ mobile_number: updateFields.mobile_number });
    //   if (existingPatient && existingPatient._id.toString() !== patientId) {
    //     throw new Error(
    //       `patientService-update patient: The mobile number '${updateFields.mobile_number}' is already in use by another patient`
    //     );
    //   }
    // }

    if (updateFields.password) {
      //console.log("Before hashing:", updateFields.password);
      const salt = await bcrypt.genSalt(10);
      updateFields.password = await bcrypt.hash(updateFields.password, salt);
      //console.log("After hashing:", updateFields.password);
    }

    if (updateFields.suspended) {
      // Only superadmins can suspend patients
      if (user.role !== "superadmin") {
        throw new Error("patientService-update patient: Only superadmins can suspend patients");
      }
    }

    // Perform the update
    const updatedPatient = await Patient.findByIdAndUpdate(
      patientId,
      { $set: updateFields }, // Update only the provided fields
      { new: true, runValidators: true } // Return the updated document and run schema validators
    );

    if (!updatedPatient) {
      throw new Error("patientService-update patient: Patient not found");
    }

    return updatedPatient;
  }

  static async deletePatient(patientId) {
    // Validate the patientId as a valid MongoDB ObjectId
    if (!mongoose.isValidObjectId(patientId)) {
      throw new Error("patientService-delete patient: Invalid patientId");
    }

    // Find and delete the patient by ID
    const deletedPatient = await Patient.findByIdAndDelete(patientId);

    if (!deletedPatient) {
      throw new Error("patientService-delete patient: Patient not found");
    }

    return {
      message: "Patient successfully deleted",
      deletedPatient, // Optionally return the deleted patient data
    };
  }
  
  
}

module.exports = PatientService;
