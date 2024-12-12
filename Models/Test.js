// models/Test.js
const mongoose = require("mongoose");

const testSchema = new mongoose.Schema({
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
  device: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Device",
  },
  result_date: {
    type: Date,
  },
  status: {
    type: String,
    enum: ["reviewed", "in progress", "pending"],
    default: "pending",
  },
  purpose: {
    type: String,
    required: true,
  },
  review: {
    type: String,
  },
  results: [
    {
      type: String,
    },
  ],
});

testSchema.index({ patient_id: 1, test_result_date: 1 }); // For efficient queries

module.exports = mongoose.model("Test", testSchema);
