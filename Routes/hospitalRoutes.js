// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const hospitalController = require("../Controllers/Objects Controllers/hospitalController");
const { authenticate, authorize } = require("../middlewares/jwtAuth");

router.post(
  "/hospital/register",
  authenticate,
  authorize("superadmin"),
  hospitalController.register
);

module.exports = router;
