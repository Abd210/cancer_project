// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const TestController = require("../Controllers/Objects Controllers/testController");
const { authenticate, authorize } = require("../middlewares/jwtAuth");

router.get(
  "/test/details",
  authenticate,
  authorize(["patient", "doctor", "admin", "superadmin"]),
  TestController.getTestDetails
)

/**
 * Route: POST /test/new
 * Description: Creates a new test in the system. This route is accessible to users with roles such as device, doctor, admin, and superadmin.
 * Middleware:
 *   - authenticate: Ensures the user is authenticated by verifying the JWT token.
 *   - authorize: Grants access only to users with the roles "device", "doctor", "admin", or "superadmin".
 * Request Headers:
 *   - token: JWT token for authentication.
 *   - role: The role of the authenticated user (e.g., "doctor", "admin").
 * Request Body:
 *   - Should include necessary details for creating a test (e.g., test name, parameters, and associated data).
 * Response:
 *   - Success (201): Returns the details of the newly created test.
 *   - Unauthorized (401): If the user is not authenticated or the token is invalid.
 *   - Forbidden (403): If the user does not have the required role.
 *   - Bad Request (400): If the request body is invalid or incomplete.
 *   - Internal Server Error (500): If any unexpected server error occurs.
 */

router.post(
  "/test/new",
  authenticate,
  authorize(["device", "doctor", "admin", "superadmin"]),
  TestController.createTest
);

module.exports = router;
