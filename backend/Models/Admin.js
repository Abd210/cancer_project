const { db } = require("../firebase"); // Import shared Firebase instance

const bcrypt = require("bcrypt");

const adminsCollection = db.collection("admins");

const ROLES = ["admin"];

class Admin {
  constructor({
    persId,
    password,
    name,
    email,
    mobileNumber,
    hospital,
    role = "admin",
    suspended = false,
  }) {
    if (typeof persId !== "string")
      throw new Error("Invalid persId: must be a string");
    if (typeof password !== "string")
      throw new Error("Invalid password: must be a string");
    if (typeof name !== "string")
      throw new Error("Invalid name: must be a string");
    if (typeof email !== "string")
      throw new Error("Invalid email: must be a string");
    if (typeof mobileNumber !== "string")
      throw new Error("Invalid mobileNumber: must be a string");
    if (typeof hospital !== "string")
      throw new Error(
        "Invalid hospital: must be a Firestore document reference"
      );
    if (!ROLES.includes(role))
      throw new Error(`Invalid role: ${role}. Allowed: ${ROLES.join(", ")}`);
    if (typeof suspended !== "boolean")
      throw new Error("Invalid suspended: must be a boolean");

    this.persId = persId;
    this.password = password;
    this.name = name;
    this.email = email;
    this.mobileNumber = mobileNumber;
    this.hospital = hospital;
    this.role = role;
    this.suspended = suspended;
    this.createdAt = new Date();
    this.updatedAt = new Date();
  }

  async save() {
    try {
      const salt = await bcrypt.genSalt(10);
      this.password = await bcrypt.hash(this.password, salt);
      this.updatedAt = new Date();

      // Firestore will auto-generate the document ID
      const docRef = await adminsCollection.add({ ...this });
      return docRef.id; // Return the auto-generated ID
    } catch (error) {
      throw new Error("Error saving admin: " + error.message);
    }
  }

  async comparePassword(candidatePassword) {
    return bcrypt.compare(candidatePassword, this.password);
  }
}

module.exports = Admin;
