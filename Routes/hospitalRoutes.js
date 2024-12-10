// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const hospitalController = require("../Controllers/General Roles Controllers/doctorController");
const { authenticate, authorize } = require("../middlewares/jwtAuth");

router.post(
  "/hospital/register",
  authenticate,
  authorize("patient", "doctor", "admin", "superadmin"),
  hospitalController.registerHospital
);

module.exports = router;
