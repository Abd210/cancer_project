// models/Appointment.js
const mongoose = require("mongoose");

const appointmentSchema = new mongoose.Schema({
  patient: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Patient",
    required: true,
  },
  doctor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Doctor",
    required: true,
  },
  appointment_date: { type: Date, required: true },
  purpose: { type: String, required: true },
  status: {
    type: String,
    enum: ["scheduled", "cancelled", "completed"],
    default: "scheduled",
  },
  suspended: { type: Boolean, default: false }, // New field indicating if the patient is suspended
});

appointmentSchema.index({ patient: 1, appointment_date: 1 }); // For efficient queries

module.exports = mongoose.model("Appointment", appointmentSchema);
