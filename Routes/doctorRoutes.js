// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const doctorController = require("../Controllers/General Roles Controllers/doctorController");
const doctorService = require("../Services/doctorService");
const { authenticate, authorize } = require("../middlewares/jwtAuth");

router.get(
  "/doctor/public-data",
  authenticate,
  authorize("patient", "doctor", "admin", "superadmin"),
  doctorController.getPublicData
);

module.exports = router;
