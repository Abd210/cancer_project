// Ensure all models are imported
const Patient = require("../Models/Patient");
const Doctor = require("../Models/Doctor");
const Admin = require("../Models/Admin");
const SuperAdmin = require("../Models/SuperAdmin");
const bcrypt = require("bcrypt");
const mongoose = require("mongoose");

/**
 * AdminService provides functionality related to managing admin data.
 * This includes methods for retrieving and managing admin accounts.
 */
class AdminService {

    static async findAdmin(admin_id) {
        if (!mongoose.isValidObjectId(admin_id)) {
            throw new Error("adminService-find admin: Invalid admin id");
        }

        return await Admin.findOne({ _id: admin_id });
    }

    static async findAllAdmins() {
        // Fetch all admin data
        return await Admin.find({});
    }

  /**
   * Deletes an admin account using their unique identifier (adminId).
   * 
   * @param {string} adminId - The ID of the admin to be deleted.
   * @returns {Object} A success message or an error if the admin is not found.
   * @throws Throws an error if the adminId is invalid or the admin is not found.
   */
  static async deleteAdmin(adminId) {
    // Validate the adminId as a valid MongoDB ObjectId
    if (!mongoose.isValidObjectId(adminId)) {
      throw new Error("adminService-delete admin: Invalid adminId");
    }

    // Find and delete the admin by ID
    const deletedAdmin = await Admin.findByIdAndDelete(adminId);

    if (!deletedAdmin) {
      throw new Error("adminService-delete admin: Admin not found");
    }

    return {
      message: "Admin successfully deleted",
      deletedAdmin, // Optionally return the deleted admin data
    };
  }

    static async updateAdmin(adminId, updateFields, user) {
        // Validate the adminId as a valid MongoDB ObjectId
        if (!mongoose.isValidObjectId(adminId)) {
        throw new Error("adminService-update admin: Invalid adminId");
        }

        // Prevent updating the _id field
        if (updateFields._id) {
            throw new Error("adminService-update admin: Changing the '_id' field is not allowed");
        }

        // Prevent updating the role field
        if (updateFields.role) {
            throw new Error("adminService-update admin: Changing the 'role' field is not allowed");
        }

        // Internal helper function to check uniqueness across collections
        const checkUniqueness = async (field, value) => {
        const collections = [Patient, Doctor, Admin, SuperAdmin];
        for (const Collection of collections) {
            const existingUser = await Collection.findOne({ [field]: value });
            if (existingUser && existingUser._id.toString() !== adminId) {
            throw new Error(`adminService-update admin: The ${field} '${value}' is already in use by another user`);
            }
        }
        };

        // Check `pers_id` uniqueness if it is being updated
        if (updateFields.pers_id) {
        await checkUniqueness("pers_id", updateFields.pers_id);
        }

        // Check `email` uniqueness if it is being updated
        if (updateFields.email) {
        await checkUniqueness("email", updateFields.email);
        }

        // Check `mobile_number` uniqueness if it is being updated
        if (updateFields.mobile_number) {
        await checkUniqueness("mobile_number", updateFields.mobile_number);
        }

        // Check if the password is being updated and hash it
        if (updateFields.password) {
            const salt = await bcrypt.genSalt(10);
            updateFields.password = await bcrypt.hash(updateFields.password, salt);
        }

        if (updateFields.suspended) {
            // Only superadmins can suspend admins
            if (user.role !== "superadmin") {
                throw new Error("adminService-update admin: Only superadmins can suspend admins");
            }
        }

        // Perform the update
        const updatedAdmin = await Admin.findByIdAndUpdate(
            adminId,
            { $set: updateFields }, // Update only the provided fields
            { new: true, runValidators: true } // Return the updated document and run schema validators
        );

        if (!updatedAdmin) {
            throw new Error("adminService-update admin: admin not found");
        }

        return updatedAdmin;
    }
}

module.exports = AdminService;
