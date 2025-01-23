const Hospital = require("../Models/Hospital");
const Patient = require("../Models/Patient");
const Doctor = require("../Models/Doctor");
const Appointment = require("../Models/Appointment");
const Test = require("../Models/Test");
const Admin = require("../Models/Admin");
const SuperAdmin = require("../Models/SuperAdmin");
const mongoose = require("mongoose");

class HospitalService {
  static async register({
    hospital_name,
    hospital_address,
    mobile_numbers,
    emails,
  }) {
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
  }

  static async getHospitalData(_id) {
    // Find the hospital and include all fields
    const hospital = await Hospital.findOne(
      { _id } // Filter by _id and role
    );

    // If the hospital is not found, throw an error
    if (!hospital) {
        throw new Error("Hospital not found");
    }

    return hospital; // Returns the full hospital's data
  }

  static async updateHospital(hospitalId, updateFields, user) {
    // Validate the hospitalId as a valid MongoDB ObjectId
    if (!mongoose.isValidObjectId(hospitalId)) {
      throw new Error("hospitalService-update hospital: Invalid hospitalId");
    }

    // Prevent updating the _id field
    if (updateFields._id) {
        throw new Error("hospitalService-update hospital: Changing the '_id' field is not allowed");
    }

    // Internal helper function to check uniqueness across collections
    // const checkUniqueness = async (field, values, hospitalId) => {
    //   const collections = [Patient, Doctor, Admin, SuperAdmin, Hospital];
    
    //   for (const Collection of collections) {
    //     const query = { [field]: { $in: values } };
    
    //     // Exclude the current hospital being updated
    //     if (Collection.modelName === "Hospital") {
    //       query._id = { $ne: hospitalId };
    //     }
    
    //     const existingUsers = await Collection.find(query);
        
    //     for (const existingUser of existingUsers) {
    //       if (existingUser._id.toString() !== hospitalId) {
    //         throw new Error(`hospitalService-update hospital: One of the ${field} is already in use by another user`);
    //       }
    //     }
    //   }
    // };

    const checkUniqueness = async (field, values, hospitalId) => {
      const collections = [
        { model: Patient, isHospital: false },
        { model: Doctor, isHospital: false },
        { model: Admin, isHospital: false },
        { model: SuperAdmin, isHospital: false },
        { model: Hospital, isHospital: true },
      ];
    
      for (const { model, isHospital } of collections) {
        let query;
    
        if (isHospital) {
          // For hospitals, check if any of the provided values exist in the arrays
          query = { [field]: { $in: values }, _id: { $ne: hospitalId } };
        } else {
          // For other collections, check if any single value matches the string field
          query = { [field.slice(0, -1)]: { $in: values } }; // Convert to singular, e.g. 'emails' -> 'email'
        }
    
        const existingUsers = await model.find(query);
    
        for (const existingUser of existingUsers) {
          if (isHospital && existingUser._id.toString() !== hospitalId) {
            throw new Error(`hospitalService-update hospital: One of the ${field} is already in use by another hospital`);
          } else if (!isHospital) {
            throw new Error(`hospitalService-update hospital: One of the ${field} is already in use by another user`);
          }
        }
      }
    };

    console.log(updateFields);
    if (updateFields.emails && Array.isArray(updateFields.emails)) {
      await checkUniqueness("emails", updateFields.emails, hospitalId);
    }
    console.log(Array.isArray(updateFields.mobile_numbers));
    if (updateFields.mobile_numbers && Array.isArray(updateFields.mobile_numbers)) {
      await checkUniqueness("mobile_numbers", updateFields.mobile_numbers, hospitalId);
    }

    if (updateFields.suspended) {
      // Only superadmins can suspend hospitals
      if (user.role !== "superadmin") {
        throw new Error("hospitalService-update hospital: Only superadmins can suspend hospitals");
      }
    }

    // Perform the update
    const updatedHospital = await Hospital.findByIdAndUpdate(
        hospitalId,
        { $set: updateFields }, // Update only the provided fields
        { new: true, runValidators: true } // Return the updated document and run schema validators
    );

    if (!updatedHospital) {
        throw new Error("hospitalService-update hospital: Hospital not found");
    }

    return updatedHospital;
  }

  static async findAllHospitals() {
    // Fetch all hospital data
    return await Hospital.find({});
  }
}
module.exports = HospitalService;
