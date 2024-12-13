// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const doctorController = require("../Controllers/General Roles Controllers/doctorController");
const { authenticate, authorize } = require("../middlewares/jwtAuth");

/**
 * Route: GET /doctor/public-data
 * Description: Fetches the public data of a doctor based on the provided doctor ID.
 * Middleware:
 *   - authenticate: Ensures the user is authenticated by verifying the JWT token.
 *   - authorize: Restricts access to specific roles ("patient", "doctor", "admin", "superadmin").
 * Request Headers:
 *   - Authorization: JWT token for authentication.
 *   - role: The role of the requesting user (e.g., "patient", "doctor", "admin", or "superadmin").
 *   - _id: The unique ID of the doctor whose public data is being requested.
 * Response:
 *   - Success (200): Returns the public data of the requested doctor, excluding sensitive fields like `pers_id`, `password`, and timestamps.
 *   - Unauthorized (401): If the user is not authenticated or the token is invalid.
 *   - Forbidden (403): If the user does not have the required role.
 *   - Not Found (404): If no doctor is found with the provided ID.
 *   - Internal Server Error (500): If any unexpected server error occurs.
 */
router.get(
  "/doctor/public-data",
  authenticate,
  authorize("patient", "doctor", "admin", "superadmin"),
  doctorController.getPublicData
);

module.exports = router;
