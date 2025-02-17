const { db } = require("../firebase"); // Import shared Firebase instance

const bcrypt = require("bcrypt");

const superAdminsCollection = db.collection("superadmins");

const ROLES = ["superadmin"];

class SuperAdmin {
  constructor({
    pers_id,
    password,
    name,
    email,
    mobile_number,
    role = "superadmin",
  }) {
    if (typeof pers_id !== "string")
      throw new Error("Invalid pers_id: must be a string");
    if (typeof password !== "string")
      throw new Error("Invalid password: must be a string");
    if (typeof name !== "string")
      throw new Error("Invalid name: must be a string");
    if (typeof email !== "string")
      throw new Error("Invalid email: must be a string");
    if (typeof mobile_number !== "string")
      throw new Error("Invalid mobile_number: must be a string");
    if (!ROLES.includes(role))
      throw new Error(`Invalid role: ${role}. Allowed: ${ROLES.join(", ")}`);

    this.pers_id = pers_id;
    this.password = password;
    this.name = name;
    this.email = email;
    this.mobile_number = mobile_number;
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
