const mongoose = require("mongoose");
const bcrypt = require("bcrypt");

const superAdminSchema = new mongoose.Schema(
  {
    pers_id: {
      type: String,
      unique: true,
      required: true,
    },
    name: {
      type: String,
      required: true,
    }, // SuperAdmin's full name
    email: {
      type: String,
      unique: true,
      required: true,
      trim: true,
    }, // Unique email address
    mobile_number: {
      type: String,
      unique: true,
      required: true,
      trim: true,
    }, // Unique mobile number
    password: {
      type: String,
      required: true,
    }, // Encrypted password
    role: {
      type: String,
      enum: ["superadmin"],
      default: "superadmin",
      required: true,
    }, // Fixed role as "superadmin"
  },
  { timestamps: true }
);

// Hash the password before saving the SuperAdmin
superAdminSchema.pre("save", async function (next) {
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
superAdminSchema.methods.comparePassword = function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model("SuperAdmin", superAdminSchema);
