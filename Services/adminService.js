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
}

module.exports = AdminService;
