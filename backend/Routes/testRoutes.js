// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const TestController = require("../Controllers/Objects Controllers/testController");
const { authenticate, authorize } = require("../middlewares/jwtAuth");

router.get(
  "/test/results",
  authenticate,
  authorize(["patient", "doctor", "admin", "superadmin"]),
  TestController.getTestResults
);

router.get(
  "/test/review",
  authenticate,
  authorize(["patient", "doctor", "admin", "superadmin"]),
  TestController.getTestReview
);

router.post(
  "/test/new",
  authenticate,
  authorize(["device", "doctor", "admin", "superadmin"]),
  TestController.createTest
);

module.exports = router;
