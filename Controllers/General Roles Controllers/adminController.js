const AdminService = require("../../Services/adminService");

/**
 * AdminController handles actions related to Admin management.
 * It includes methods for deleting admin accounts and performing related operations.
 */
class AdminController {
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
      return res.status(200).json(result);
    } catch (deleteAdminError) {
      // Catch and return errors
      return res.status(500).json({
        error: `AdminController-delete admin: ${deleteAdminError.message}`,
      });
    }
  }
}

module.exports = AdminController;
