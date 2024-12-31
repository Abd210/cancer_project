// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const appointmentController = require("../Controllers/Objects Controllers/appointmentController");
const { authenticate, authorize } = require("../middlewares/jwtAuth");

/**
 * Route: GET /appointment/history
 * Description: Fetches the history of past appointments for the authenticated user.
 * Middleware:
 *   - authenticate: Ensures the user is authenticated by verifying the JWT token.
 *   - authorize: Restricts access to specific roles ("patient", "doctor", "admin", "superadmin").
 * Request Headers:
 *   - Authorization: Bearer token for authentication (e.g., "Bearer <JWT_TOKEN>").
 *   - _id: The ID of the user (patient or doctor) making the request.
 *   - role: The role of the user making the request (e.g., "patient", "doctor").
 * Response:
 *   - Success (200): Returns a list of past appointments.
 *   - Unauthorized (401): If the user is not authenticated or token is invalid.
 *   - Forbidden (403): If the user does not have the required role.
 *   - Internal Server Error (500): If any unexpected server error occurs.
 */
router.get(
  "/appointment/history",
  authenticate,
  authorize(["patient", "doctor", "admin", "superadmin"]),
  appointmentController.getAppointmentHistory
);

/**
 * Route: GET /appointment/upcoming
 * Description: Fetches a list of upcoming appointments for the authenticated user.
 * Middleware:
 *   - authenticate: Ensures the user is authenticated by verifying the JWT token.
 *   - authorize: Restricts access to specific roles ("patient", "doctor", "admin", "superadmin").
 * Request Headers:
 *   - Authorization: Bearer token for authentication (e.g., "Bearer <JWT_TOKEN>").
 *   - _id: The ID of the user (patient or doctor) making the request.
 *   - role: The role of the user making the request (e.g., "patient", "doctor").
 * Response:
 *   - Success (200): Returns a list of upcoming appointments.
 *   - Unauthorized (401): If the user is not authenticated or token is invalid.
 *   - Forbidden (403): If the user does not have the required role.
 *   - Internal Server Error (500): If any unexpected server error occurs.
 */
router.get(
  "/appointment/upcoming",
  authenticate,
  authorize(["patient", "doctor", "admin", "superadmin"]),
  appointmentController.getUpcomingAppointments
);

/**
 * Route: POST /appointment/cancel
 * Description: Cancels an appointment for the authenticated user.
 * Middleware:
 *   - authenticate: Ensures the user is authenticated by verifying the JWT token.
 *   - authorize: Restricts access to specific roles ("patient", "doctor", "admin", "superadmin").
 * Request Headers:
 *   - Authorization: Bearer token for authentication (e.g., "Bearer <JWT_TOKEN>").
 *   - role: The role of the user making the request (e.g., "patient", "doctor").
 * Request Body (JSON):
 *   - appointment_id: The ID of the appointment to be canceled (string).
 * Response:
 *   - Success (200): Returns the details of the canceled appointment.
 *   - Bad Request (400): If the appointment ID is missing or invalid.
 *   - Unauthorized (401): If the user is not authenticated or token is invalid.
 *   - Forbidden (403): If the user does not have the required role to cancel the appointment.
 *   - Internal Server Error (500): If any unexpected server error occurs.
 */
router.post(
  "/appointment/cancel",
  authenticate,
  authorize(["patient", "doctor", "admin", "superadmin"]),
  appointmentController.cancelAppointment
);

/**
 * Route: POST /appointment/new
 * Description: Allows authenticated users to schedule a new appointment.
 * Middleware:
 *   - authenticate: Ensures the user is authenticated by verifying the JWT token.
 *   - authorize: Restricts access to specific roles ("patient", "doctor", "admin", "superadmin").
 * Request Headers:
 *   - Authorization: Bearer token for authentication (e.g., "Bearer <JWT_TOKEN>").
 *   - role: The role of the user making the request (e.g., "patient", "doctor").
 * Request Body (JSON):
 *   - role: The role of the requester scheduling the appointment (e.g., "patient").
 *   - patient: The ID of the patient for the appointment (required).
 *   - doctor: The ID of the doctor for the appointment (required).
 *   - appointment_date: The date and time of the appointment in ISO 8601 format (e.g., "2026-10-01") (required).
 *   - purpose: The purpose or reason for the appointment (e.g., "routine checkup") (required).
 *   - status: The status of the appointment (e.g., "scheduled"). Defaults to "scheduled".
 * Response:
 *   - Success (201): Returns the details of the newly created appointment.
 *   - Bad Request (400): If required fields are missing or invalid.
 *   - Unauthorized (401): If the user is not authenticated or token is invalid.
 *   - Forbidden (403): If the user does not have the required role.
 *   - Internal Server Error (500): If any unexpected server error occurs.
 */
router.post(
  "/appointment/new",
  authenticate,
  authorize(["patient", "doctor", "admin", "superadmin"]),
  appointmentController.createAppointment
);


router.delete(
  "/appointment/delete",
  authenticate, // Middleware to authenticate the user
  authorize("superadmin"), // Middleware to allow only superadmins
  appointmentController.deleteAppointment // Controller function
);

router.put(
  "/appointment/update",
  authenticate, // Middleware to authenticate the user
  authorize("superadmin"), // Middleware to allow only superadmins
  appointmentController.updateAppointmentData // Controller function
);

module.exports = router;
