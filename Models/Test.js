// models/Test.js
const mongoose = require("mongoose");

const testSchema = new mongoose.Schema({
  patient_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Patient",
    required: true,
  },
  doctor_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Doctor",
    required: true,
  },
  device_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Device",
    required: true,
  },
  test_result_date: {
    type: Date,
    required: true,
  },
  status: {
    type: String,
    enum: ["reviewed", "pending"],
    default: "pending",
  },
  test_purpose: {
    type: String,
    required: true,
  },
  test_review: {
    type: String,
  },
});

testSchema.index({ patient_id: 1, test_result_date: 1 }); // For efficient queries

module.exports = mongoose.model("Test", testSchema);
