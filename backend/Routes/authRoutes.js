// routes/authRoutes.js
const express = require("express");
const router = express.Router();
const AuthController = require("../Controllers/redirectAuthController");
const { authenticate, authorize } = require("../middlewares/jwtAuth");

/**
 * Route: POST /auth/register
 * Description: Registers a new user (SuperAdmin, Patient, or Doctor) based on the provided role and details.
 * Middleware:
 *   - None specified for this route, direct access to `AuthController.register`.
 * Request Body:
 *   - For SuperAdmin:
 *     - pers_id: The personal ID of the SuperAdmin.
 *     - name: Name of the SuperAdmin.
 *     - role: The role of the user (should be "superadmin").
 *     - password: The password for the SuperAdmin account.
 *     - mobile_number: The mobile number of the SuperAdmin.
 *     - email: The email address of the SuperAdmin.
 *   - For Patient:
 *     - pers_id: The personal ID of the Patient.
 *     - name: Name of the Patient.
 *     - password: The password for the Patient account.
 *     - role: The role of the user (should be "patient").
 *     - mobile_number: The mobile number of the Patient.
 *     - email: The email address of the Patient.
 *     - status: The medical status of the Patient (e.g., recovering, stable).
 *     - problem: The primary medical issue or problem.
 *     - birth_date: The birth date of the Patient.
 *     - medicalHistory: An array of medical conditions or history.
 *     - hospital_id: The ID of the hospital the Patient is associated with.
 *   - For Doctor:
 *     - pers_id: The personal ID of the Doctor.
 *     - name: Name of the Doctor.
 *     - role: The role of the user (should be "doctor").
 *     - password: The password for the Doctor account.
 *     - email: The email address of the Doctor.
 *     - mobile_number: The mobile number of the Doctor.
 *     - birth_date: The birth date of the Doctor.
 *     - licenses: An array of licenses held by the Doctor.
 *     - description: A brief description about the Doctor.
 *     - hospital: The ID of the hospital the Doctor is associated with.
 * Response:
 *   - Success (201): Returns the created user object.
 *   - Bad Request (400): If required fields are missing or invalid.
 *   - Conflict (409): If a user with the same identifier already exists.
 *   - Internal Server Error (500): If any unexpected server error occurs.
 */
router.post(
    "/register", 
    authenticate,
    authorize("superadmin"),
    AuthController.register
);

/**
 * Route: POST /auth/login
 * Description: Logs in a user based on their role and credentials (email, password, or personal ID).
 * Controller: AuthController.login
 * Middleware: None
 * Request Body:
 *   - For SuperAdmin and Patient login:
 *     - email: The email address of the user.
 *     - password: The password for the user account.
 *     - role: The role of the user ("superadmin" or "patient").
 *   - For Doctor login:
 *     - pers_id or email or mobile_number: Either the personal ID of the doctor, the email of the doctor, or the phone number.
 *     - password: The password for the user account.
 *     - role: "doctor".
 * Response:
 *   - Success (200): Returns a JWT token and a success message upon successful login.
 *   - Unauthorized (401): If the credentials provided are incorrect.
 *   - Forbidden (403): If the user role is not allowed.
 *   - Internal Server Error (500): If any unexpected error occurs during login.
 */
router.post("/login", AuthController.login);


router.post("/forgot-password", AuthController.forgotPassword);
router.put("/reset-password", AuthController.resetPassword);

module.exports = router;
