// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const patientController = require("../Controllers/General Roles Controllers/patientController");
const { authenticate, authorize } = require("../middlewares/jwtAuth");

router.get(
  "/patient/data",
  authenticate,
  authorize("patient"),
  patientController.getPatientData
);
router.get(
  "/doctor/public_data",
  authenticate,
  authorize("patient"),
  patientController.getDoctorPublicData
);
router.get(
  "/diagnosis",
  authenticate,
  authorize("patient"),
  patientController.getDiagnosis
);
router.get(
  "/appointment/history",
  authenticate,
  authorize("patient"),
  patientController.getAppointmentHistory
);
router.get(
  "/appointment/upcoming",
  authenticate,
  authorize("patient"),
  patientController.getUpcomingAppointments
);
router.post(
  "/appointment/cancel",
  authenticate,
  authorize("patient"),
  patientController.cancelAppointment
);
router.post(
  "/appointment/new",
  authenticate,
  authorize("patient"),
  patientController.createAppointment
);
router.get(
  "/test/results",
  authenticate,
  authorize("patient"),
  patientController.getTestResults
);
router.get(
  "/test/interpretation",
  authenticate,
  authorize("patient"),
  patientController.getTestInterpretation
);
router.post(
  "/test/request_interpretation",
  authenticate,
  authorize("patient"),
  patientController.requestTestInterpretation
);
router.post(
  "/ticket/new",
  authenticate,
  authorize("patient"),
  patientController.createTicket
);

module.exports = router;
// {

//     "patient_id": "<patient_id>",
//     "doctor_id": "<doctor_id>",
//     "appointment_date": "2025-01-10T10:00:00Z",
//     "purpose": "General check-up"
//   }
