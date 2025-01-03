// models/Device.js
const mongoose = require("mongoose");

const deviceSchema = new mongoose.Schema({
  _id: {
    type: String,
    required: true,
  },
  hospital: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Hospital",
    required: true,
  },
  patient: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Patient",
  },
  device_code: {
    type: String,
    unique: true,
    required: true,
  },
  purpose: {
    type: String,
  },
  status: {
    type: String,
    enum: ["operational", "malfunctioned", "standby"],
    required: true,
  },
  suspended: {
    type: Boolean,
    default: false,
  },
});

module.exports = mongoose.model("Device", deviceSchema);
