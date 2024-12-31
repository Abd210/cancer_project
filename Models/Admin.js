const mongoose = require("mongoose");
const bcrypt = require("bcrypt");

const adminSchema = new mongoose.Schema(
  {
    pers_id: {
      type: String,
      unique: true,
      required: true,
    }, // Admin's personal ID
    password: {
      type: String,
      required: true,
    }, // Encrypted password
    role: {
      type: String,
      enum: ["admin"],
      default: "admin",
      required: true,
    }, // Role is fixed as 'admin'

    // Admin-specific fields
    name: {
      type: String,
      required: true,
    }, // Admin's full name
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
    hospital: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Hospital",
      required: true,
    }, // Reference to the hospital the admin is affiliated with
  },
  {
    timestamps: true,
  }
);

// Hash the password before saving the admin
adminSchema.pre("save", async function (next) {
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
adminSchema.methods.comparePassword = function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model("Admin", adminSchema);
