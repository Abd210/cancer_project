const mongoose = require("mongoose");
const bcrypt = require("bcrypt");

// Patient-specific schema based on the general User schema
const patientSchema = new mongoose.Schema(
  {
    pers_id: { type: String, unique: true, required: true }, // Patient's personal ID (pers_id)
    password: { type: String, required: true },
    role: {
      type: String,
      enum: "patient",
      required: true,
    },

    // Patient-specific fields
    name: { type: String, required: true },
    mobile_number: { type: String, required: true, unique: true },
    email: { type: String, required: true, unique: true },
    status: {
      type: String,
      enum: ["recovering", "recovered", "active", "inactive"],
      default: "active",
    },
    diagnosis: { type: String, default: "Not Diagnosed" }, // Medical problem/issue faced by the patient
    birth_date: { type: Date, required: true }, // Patient's date of birth
    medicalHistory: [{ type: String }], // Array of medical history strings
    hospital: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Hospital",
      required: true,
    }, // Reference to the hospital the doctor is affiliated with
  },
  { timestamps: true }
);

// Hash the password before saving the user
patientSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Compare given password with the stored hashed password
patientSchema.methods.comparePassword = function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model("Patient", patientSchema);
