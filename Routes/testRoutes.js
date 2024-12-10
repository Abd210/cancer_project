// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const testController = require("../Controllers/General Roles Controllers/testController");
const { authenticate, authorize } = require("../middlewares/jwtAuth");

router.get(
  "/test/results",
  authenticate,
  authorize("patient", "doctor", "admin", "superadmin"),
  testController.getTestResults
);

router.get(
  "/test/review",
  authenticate,
  authorize("patient", "doctor", "admin", "superadmin"),
  testController.getTestReview
);

router.post(
  "/test/request-review",
  authenticate,
  authorize("patient", "admin", "superadmin"),
  testController.requestTestReview
);

module.exports = router;
