// routes/adminRoutes.js
const express = require("express");
const router = express.Router();
const adminController = require("../Controllers/General Roles Controllers/adminController");
const { authenticate, authorize } = require("../middlewares/jwtAuth");

/**
 * Route: DELETE /admin/delete
 * Description: Deletes an admin based on the provided admin ID.
 * Middleware:
 *   - authenticate: Ensures the user is authenticated by verifying the JWT token.
 *   - authorize: Restricts access to the "superadmin" role.
 * Request Headers:
 *   - Authorization: JWT token for authentication.
 *   - role: The role of the requesting user (must be "superadmin").
 *   - adminid: The unique ID of the admin to be deleted.
 * Response:
 *   - Success (200): Returns a success message upon successful deletion.
 *   - Unauthorized (401): If the user is not authenticated or the token is invalid.
 *   - Forbidden (403): If the user does not have the "superadmin" role.
 *   - Not Found (404): If no admin is found with the provided ID.
 *   - Internal Server Error (500): If any unexpected server error occurs.
 */
router.delete(
  "/admin/delete",
  authenticate, // Middleware to authenticate the user
  authorize("superadmin"), // Middleware to allow only superadmins
  adminController.deleteAdmin // Controller function
);

module.exports = router;