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
  review: {
    type: String,
    trim: true,
    default: null, // Optional review field
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    refPath: "role",
    required: true,
  },
});

module.exports = mongoose.model("Ticket", ticketSchema);
