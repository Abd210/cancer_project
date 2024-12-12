// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const patientController = require("../Controllers/General Roles Controllers/patientController");
const { authenticate, authorize } = require("../middlewares/jwtAuth");

// No need for validating input in GET requests, authorization is enough
router.get(
  "/patient/personal-data",
  authenticate,
  authorize(["patient", "doctor", "admin", "superadmin"]),
  patientController.getData
);

router.get(
  "/patient/diagnosis",
  authenticate,
  authorize(["patient", "doctor", "admin", "superadmin"]),
  patientController.getDiagnosis
);

module.exports = router;
