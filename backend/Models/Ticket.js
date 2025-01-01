// models/Ticket.js
const mongoose = require("mongoose");

const ticketSchema = new mongoose.Schema({
  role: {
    type: String,
    required: true,
    enum: ["patient", "doctor", "admin", "superadmin"], // Adjust roles as needed
  },
  issue: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    enum: ["open", "in_progress", "resolved", "closed"],
    default: "open",
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  solvedAt: {
    type: Date,
    default: null, // Optional field
  },
  review: {
    type: String,
    default: null, // Optional review field
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    refPath: "role",
    required: true,
  },
  visibleTo: {
    type: [String],
    enum: ["patient", "doctor", "admin", "superadmin"],
    default: ["patient, doctor, admin", "superadmin"], // Optional field
  },
  suspended: { type: Boolean, default: false }, // New field indicating if the patient is suspended
});

module.exports = mongoose.model("Ticket", ticketSchema);
