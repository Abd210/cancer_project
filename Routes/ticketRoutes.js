// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const ticketController = require("../Controllers/General Roles Controllers/ticketController");
const { authenticate, authorize } = require("../middlewares/jwtAuth");

router.post(
  "/ticket/new",
  authenticate,
  authorize("patient", "doctor", "admin", "superadmin"),
  ticketController.createTicket
);

router.get(
  "/ticket/review",
  authenticate,
  authorize("patient", "doctor", "admin", "superadmin"),
  ticketController.getTicketReview
);

module.exports = router;
