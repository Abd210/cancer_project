// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const hospitalController = require("../Controllers/Objects Controllers/hospitalController");
const { authenticate } = require("../middlewares/jwtAuth");
const { authorize } = require("../middlewares/roleAuth");
/**
 * Route: POST /hospital/register
 * Description: Allows a superadmin to register a new hospital. The request validates the provided data and ensures that no duplicate hospital with the same name and address exists.
 * Middleware:
 *   - authenticate: Ensures the user is authenticated by verifying the JWT token.
 *   - authorize: Restricts access to users with the "superadmin" role.
 * Request Body (JSON):
 *   - token: The JWT token for authentication.
 *   - name: The name of the hospital to be registered.
 *   - address: The address of the hospital.
 *   - mobileNumbers: An array of mobile numbers associated with the hospital.
 *   - emails: An array of email addresses associated with the hospital.
 *   - admin: (Optional) The Firestore ID of the hospital's admin.
 *   - suspended: (Optional) Boolean indicating if the hospital is suspended.
 * Response:
 *   - Success (201): Returns the details of the newly registered hospital.
 *   - Conflict (409): If a hospital with the same name and address already exists.
 *   - Unauthorized (401): If the user is not authenticated or the token is invalid.
 *   - Forbidden (403): If the user does not have the "superadmin" role.
 *   - Validation Error (400): If the request body contains invalid or missing data.
 *   - Internal Server Error (500): If any unexpected server error occurs.
 */
router.post(
  "/hospital/register",
  authenticate,
  authorize("superadmin"),
  hospitalController.register
);

router.get(
  "/hospital/data",
  authenticate, // Middleware to ensure the user is authenticated
  authorize(["patient", "doctor", "admin", "superadmin"]), // Allow all roles to access
  hospitalController.getHospitalData // Controller method to handle the request
);

router.put(
  "/hospital/data/update", // Endpoint
  authenticate, // Middleware to ensure the user is authenticated
  authorize(["admin", "superadmin"]), // Middleware to ensure only admins and superadmins can access this
  hospitalController.updateHospitalData // Controller function to handle the request
);

router.delete(
  "/hospital/delete",
  authenticate, // Middleware to ensure the user is authenticated
  authorize("superadmin"), // Middleware to ensure only superadmins can access this
  hospitalController.deleteHospital // Controller method to handle the request
);

module.exports = router;
