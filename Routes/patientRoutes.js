// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const patientController = require("../Controllers/General Roles Controllers/patientController");
const { authenticate, authorize } = require("../middlewares/jwtAuth");

/**
 * Route: GET /patient/personal-data
 * Description: Fetches the personal data of a specific patient. This route is accessible to users with specific roles, including patients, doctors, admins, and superadmins.
 * Middleware:
 *   - authenticate: Ensures the user is authenticated by verifying the JWT token.
 *   - authorize: Restricts access to users with the roles "patient", "doctor", "admin", or "superadmin".
 * Request Headers:
 *   - Authorization: JWT Token for authentication.
 *   - _id: The unique identifier of the patient whose data is being retrieved.
 *   - role: The role of the authenticated user (e.g., "patient", "doctor").
 * Response:
 *   - Success (200): Returns the personal data of the patient, including sensitive information if permitted.
 *   - Unauthorized (401): If the user is not authenticated or the token is invalid.
 *   - Forbidden (403): If the user does not have the required role.
 *   - Internal Server Error (500): If any unexpected server error occurs.
 */

router.get(
  "/patient/personal-data",
  authenticate,
  authorize(["patient", "doctor", "admin", "superadmin"]),
  patientController.getData
);

/**
 * Route: GET /patient/diagnosis
 * Description: Retrieves the diagnosis details of a specific patient. This route is accessible to users with roles such as patients, doctors, admins, and superadmins.
 * Middleware:
 *   - authenticate: Ensures the user is authenticated by verifying the JWT token.
 *   - authorize: Grants access only to users with the roles "patient", "doctor", "admin", or "superadmin".
 * Request Headers:
 *   - Authorization: JWT token for authentication.
 *   - _id: The unique identifier of the patient whose diagnosis data is being retrieved.
 *   - role: The role of the authenticated user (e.g., "patient", "doctor").
 * Response:
 *   - Success (200): Returns the diagnosis details of the patient.
 *   - Unauthorized (401): If the user is not authenticated or the token is invalid.
 *   - Forbidden (403): If the user does not have the required role.
 *   - Internal Server Error (500): If any unexpected server error occurs.
 */
router.get(
  "/patient/diagnosis",
  authenticate,
  authorize(["patient", "doctor", "admin", "superadmin"]),
  patientController.getDiagnosis
);

module.exports = router;