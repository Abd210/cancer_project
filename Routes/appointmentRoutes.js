// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const appointmentController = require("../Controllers/Objects Controllers/appointmentController");
const { authenticate, authorize } = require("../middlewares/jwtAuth");

router.get(
  "/appointment/history",
  authenticate,
  authorize("patient", "doctor", "admin", "superadmin"),
  appointmentController.getUpcomingAppointments
);

router.get(
  "/appointment/upcoming",
  authenticate,
  authorize("patient", "doctor", "admin", "superadmin"),
  appointmentController.getUpcomingAppointments
);

router.post(
  "/appointment/cancel",
  authenticate,
  authorize("patient", "doctor", "admin", "superadmin"),
  appointmentController.cancelAppointment
);

router.post(
  "/appointment/new",
  authenticate,
  authorize("patient", "doctor", "admin", "superadmin"),
  appointmentController.createAppointment
);

module.exports = router;
