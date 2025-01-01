const mongoose = require("mongoose");
const bcrypt = require("bcrypt");

const doctorSchema = new mongoose.Schema(
  {
    pers_id: {
      type: String,
      unique: true,
      required: true,
    }, // Doctor's personal ID
    password: {
      type: String,
      required: true,
    }, // Encrypted password
    role: {
      type: String,
      enum: ["doctor"],
      default: "doctor",
      required: true,
    }, // Role is fixed as 'doctor'

    // Doctor-specific fields
    name: {
      type: String,
      required: true,
    }, // Doctor's full name
    email: {
      type: String,
      unique: true,
      required: true,
    }, // Email address
    mobile_number: {
      type: String,
      unique: true,
      required: true,
    }, // Contact number
    birth_date: {
      type: Date,
      required: true,
    }, // Doctor's date of birth
    licenses: [
      {
        type: String,
        required: true,
      },
    ], // Array of medical licenses
    description: {
      type: String,
      default: "",
    }, // Brief description or biography of the doctor
    hospital: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Hospital",
      required: true,
    }, // Reference to the hospital the doctor is affiliated with
    suspended: { type: Boolean, default: false }, // New field indicating if the patient is suspended
  },
  {
    timestamps: true,
  }
);

// Hash the password before saving the user
doctorSchema.pre("save", async function (next) {
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
doctorSchema.methods.comparePassword = function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model("Doctor", doctorSchema);
