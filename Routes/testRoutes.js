// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const TestController = require("../Controllers/Objects Controllers/testController");
const { authenticate, authorize } = require("../middlewares/jwtAuth");
const TestService = require("../Services/testService");

router.post(
  "/test/results",
  authenticate,
  authorize("patient", "doctor", "admin", "superadmin"),
  TestService.getTestResults
);

router.post(
  "/test/review",
  authenticate,
  authorize("patient", "doctor", "admin", "superadmin"),
  TestService.getTestReview
);

router.post(
  "/test/new",
  authenticate,
  authorize("device", "superadmin"),
  TestController.createTest
);

module.exports = router;
