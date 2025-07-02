const AdminService = require("../../Services/adminService");
const SuspendController = require("../suspendController");

/**
 * AdminController handles actions related to Admin management.
 * It includes methods for deleting admin accounts and performing related operations.
 */
class AdminController {
  static async updateAdminData(req, res) {
    console.log(`[${req.method}] ${req.originalUrl}`);
    try {
      const { user, adminid } = req.headers;

      // Destructure the fields to update from the request body
      const updateFields = req.body;

      // Validate if adminId is provided
      if (!adminid) {
        return res.status(400).json({
          error: "AdminController-update admin: Missing adminid",
        });
      }

      // Validate if updateFields are provided
      if (!updateFields || Object.keys(updateFields).length === 0) {
        return res.status(400).json({
          error: "AdminController-update admin: No fields provided to update",
        });
      }

      // Call the AdminService to perform the update
      const updatedAdmin = await AdminService.updateAdmin(
        adminid,
        updateFields,
        user
      );

      // Check if the admin was found and updated
      if (!updatedAdmin) {
        return res.status(404).json({
          error: "AdminController- Update Admin Data: Admin not found",
        });
      }

      // Respond with the updated Admin data
      return res.status(200).json(updatedAdmin);
    } catch (updateAdminError) {
      console.error("Error in updateAdminData:", updateAdminError);
      return res.status(500).json({
        error: `AdminController-update admin: ${updateAdminError.message}`,
      });
    }
  }

  /**
   * Deletes an admin account using their unique identifier (adminid) from the request headers.
   * Handles missing adminid error and interacts with the AdminService to perform the deletion.
   *
   * @param {Object} req - The Express request object, containing the adminid in the headers.
   * @param {Object} res - The Express response object used to send the result or errors.
   *
   * @returns {Object} A JSON response indicating success or failure of the deletion.
   */
  static async deleteAdmin(req, res) {
    console.log(`[${req.method}] ${req.originalUrl}`);
    try {
      const { adminid } = req.headers;

      // Validate if adminId is provided
      if (!adminid) {
        return res.status(400).json({
          error: "AdminController-delete admin: Missing adminId",
        });
      }

      // Call the AdminService to perform the deletion
      const result = await AdminService.deleteAdmin(adminid);

      // Check if the service returned an error
      if (result.error) {
        return res.status(400).json({ error: result.error });
      }

      // Respond with success
      return res.status(200).json({ message: "Admin deleted successfully" });
    } catch (deleteAdminError) {
      console.error("Error in deleteAdmin:", deleteAdminError);
      return res.status(500).json({
        error: `AdminController-delete admin: ${deleteAdminError.message}`,
      });
    }
  }

  static async getAdminData(req, res) {
    console.log(`[${req.method}] ${req.originalUrl}`);
    try {
      // Destructure _id, user, and role from the request headers
      const { user, adminid, filter, hospitalid } = req.headers;

      // If the user's role is "admin", ensure they can only access their own data
      if (user.role === "admin") {
        const admin_data = await AdminService.findAdmin(user.id, null, null);
        // Check if the admin data exists
        if (!admin_data) {
          return res.status(404).json({ error: "Admin not found" });
        }

        // Return the fetched admin data with a 200 status code
        return res.status(200).json(admin_data);
      } else if (user.role === "superadmin") {
        // If the user is a superadmin and a specific admin's ID was not provided
        if (!adminid) {
          if (filter) {
            if (hospitalid) {
              console.log(
                "AdminController- Get Admin Data: Fetching admin data by hospital"
              );
              // Retrieve all admins' data from specified hospital if no adminid is given and hospitalid is provided
              const allAdmins = await AdminService.findAllAdminsByHospital(
                hospitalid
              );
              console.log(allAdmins);

              const filtered_data = await SuspendController.filterData(
                allAdmins,
                user.role,
                filter
              );
              return res.status(200).json(filtered_data); // Return all admin data
            } else {
              // Retrieve all admins' data if no adminid is provided
              const allAdmins = await AdminService.findAllAdmins();

              const filtered_data = await SuspendController.filterData(
                allAdmins,
                user.role,
                filter
              );
              return res.status(200).json(filtered_data); // Return all admin data
            }
          } else {
            return res.status(400).json({
              error:
                "AdminController- Get Admin Data: Please provide either a filter or a admin's id", // Specific error for missing filter
            });
          }
        }
      } else {
        // If the role is neither 'admin' nor 'superadmin', deny access
        return res.status(403).json({
          error: "AdminController- Get Admin Data: Access denied", // Access denied error
        });
      }

      console.log("AdminController- Get Admin Data: Fetching admin data");
      // Call the AdminService to find the admin data based on the _id
      const admin_data = await AdminService.findAdmin(adminid, null, null);

      // Check if the admin data exists
      if (!admin_data) {
        return res.status(404).json({ error: "Admin not found" });
      }

      // Return the fetched admin data with a 200 status code
      return res.status(200).json(admin_data);
    } catch (fetchAdminDataError) {
      console.error("Error in getAdminData:", fetchAdminDataError);
      return res.status(500).json({
        error: `AdminController-fetch admin data: ${fetchAdminDataError.message}`,
      });
    }
  }
}

module.exports = AdminController;
