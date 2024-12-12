const mongoose = require("mongoose");

const hospitalSchema = new mongoose.Schema({
  hospital_name: { type: String, required: true },
  hospital_address: { type: String, required: true },
  mobile_numbers: [{ type: String, required: true }],
  emails: [{ type: String, required: true }],
});

hospitalSchema.index({ hospital_name: 1, hospital_address: 1 }); // For efficient queries

module.exports = mongoose.model("Hospital", hospitalSchema);
