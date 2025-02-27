// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const doctorController = require("../Controllers/General Roles Controllers/doctorController");
const { authenticate } = require("../middlewares/jwtAuth");
const { authorize } = require("../middlewares/roleAuth");
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
  authorize(["patient", "doctor", "admin", "superadmin"]),
  doctorController.getPublicData
);

router.get(
  "/doctor/data",
  authenticate,
  authorize(["doctor", "superadmin"]),
  doctorController.getDoctorData
);

// Route to update doctor data (Superadmin access only)
router.put(
  "/doctor/data/update", // Endpoint
  authenticate, // Middleware to ensure the user is authenticated
  authorize(["admin", "superadmin"]), // Middleware to ensure only admins and superadmins can access this
  doctorController.updateDoctorData // Controller function to handle the request
);

router.delete(
  "/doctor/delete",
  authenticate, // Middleware to authenticate the user
  authorize("superadmin"), // Middleware to allow only superadmins
  doctorController.deleteDoctorData // Controller function
);

module.exports = router;
