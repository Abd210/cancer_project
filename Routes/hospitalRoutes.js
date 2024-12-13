// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const hospitalController = require("../Controllers/Objects Controllers/hospitalController");
const { authenticate, authorize } = require("../middlewares/jwtAuth");

/**
 * Route: POST /hospital/register
 * Description: Allows a superadmin to register a new hospital. The request validates the provided data and ensures that no duplicate hospital with the same name and address exists.
 * Middleware:
 *   - authenticate: Ensures the user is authenticated by verifying the JWT token.
 *   - authorize: Restricts access to users with the "superadmin" role.
 * Request Body (JSON):
 *   - token: The JWT token for authentication.
 *   - hospital_name: The name of the hospital to be registered.
 *   - hospital_address: The address of the hospital.
 *   - mobile_numbers: An array of mobile numbers associated with the hospital.
 *   - emails: An array of email addresses associated with the hospital.
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

module.exports = router;
