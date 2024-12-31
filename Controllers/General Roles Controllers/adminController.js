const AdminService = require("../../Services/adminService");

/**
 * AdminController handles actions related to Admin management.
 * It includes methods for deleting admin accounts and performing related operations.
 */
class AdminController {

    static async updateAdminData(req, res) {
        try {
            const { adminid } = req.headers;

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
            const updatedAdmin = await AdminService.updateAdmin(adminid, updateFields);
        
            // Check if the patient was found and updated
            if (!updatedAdmin) {
            return res.status(404).json({
                error: "AdminController- Update Admin Data: Admin not found",
            });
            }
        
            // Respond with the updated Admin data
            return res.status(200).json(updatedAdmin);
        } catch (updateAdminError) {
            // Catch and return errors
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
