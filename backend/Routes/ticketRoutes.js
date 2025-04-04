// routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const ticketController = require("../Controllers/Objects Controllers/ticketController");
const ticketService = require("../Services/ticketService");

const { authenticate } = require("../middlewares/jwtAuth");
const { authorize } = require("../middlewares/roleAuth");
router.post(
  "/ticket/new",
  authenticate,
  authorize(["patient", "doctor", "admin", "superadmin"]),
  ticketController.createTicket
);

router.post(
  "/ticket/review",
  authenticate,
  authorize(["patient", "doctor", "admin", "superadmin"]),
  ticketService.getTicketReview
);

module.exports = router;
