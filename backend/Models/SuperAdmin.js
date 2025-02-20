const { db } = require("../firebase"); // Import shared Firebase instance

const bcrypt = require("bcrypt");

const superAdminsCollection = db.collection("superadmins");

const ROLES = ["superadmin"];

class SuperAdmin {
  constructor({
    persId,
    password,
    name,
    email,
    mobileNumber,
    role = "superadmin",
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
    if (!ROLES.includes(role))
      throw new Error(`Invalid role: ${role}. Allowed: ${ROLES.join(", ")}`);

    this.persId = persId;
    this.password = password;
    this.name = name;
    this.email = email;
    this.mobileNumber = mobileNumber;
    this.role = role;
    this.createdAt = new Date();
    this.updatedAt = new Date();
  }

  async save() {
    try {
      const salt = await bcrypt.genSalt(10);
      this.password = await bcrypt.hash(this.password, salt);
      this.updatedAt = new Date();

      // Firestore auto-generates the document ID
      const docRef = await superAdminsCollection.add({ ...this });
      return docRef.id; // Return the auto-generated ID
    } catch (error) {
      throw new Error("Error saving superadmin: " + error.message);
    }
  }

  async comparePassword(candidatePassword) {
    return bcrypt.compare(candidatePassword, this.password);
  }
}

module.exports = SuperAdmin;
