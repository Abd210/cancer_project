const { db } = require("../firebase"); // Import shared Firebase instance

const bcrypt = require("bcrypt");

const doctorsCollection = db.collection("doctors");

const ROLES = ["doctor"];

class Doctor {
  constructor({
    _id,
    pers_id,
    password,
    name,
    email,
    mobileNumber,
    birthDate,
    licenses,
    description = "",
    hospital,
    role = "doctor",
    suspended = false,
  }) {
    if (typeof _id !== "string")
      throw new Error("Invalid _id: must be a string");
    if (typeof pers_id !== "string")
      throw new Error("Invalid pers_id: must be a string");
    if (typeof password !== "string")
      throw new Error("Invalid password: must be a string");
    if (typeof name !== "string")
      throw new Error("Invalid name: must be a string");
    if (typeof email !== "string")
      throw new Error("Invalid email: must be a string");
    if (typeof mobileNumber !== "string")
      throw new Error("Invalid mobileNumber: must be a string");
    if (!(birthDate instanceof Date))
      throw new Error("Invalid birthDate: must be a Date object");
    if (!Array.isArray(licenses))
      throw new Error("Invalid licenses: must be an array of strings");
    if (typeof description !== "string")
      throw new Error("Invalid description: must be a string");
    if (typeof hospital !== "string")
      throw new Error(
        "Invalid hospital: must be a Firestore document reference"
      );
    if (!ROLES.includes(role))
      throw new Error(`Invalid role: ${role}. Allowed: ${ROLES.join(", ")}`);
    if (typeof suspended !== "boolean")
      throw new Error("Invalid suspended: must be a boolean");

    this._id = _id;
    this.pers_id = pers_id;
    this.password = password;
    this.name = name;
    this.email = email;
    this.mobileNumber = mobileNumber;
    this.birthDate = birthDate;
    this.licenses = licenses;
    this.description = description;
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
      await doctorsCollection.doc(this._id).set({ ...this });
    } catch (error) {
      throw new Error("Error saving doctor: " + error.message);
    }
  }

  async comparePassword(candidatePassword) {
    return bcrypt.compare(candidatePassword, this.password);
  }
}

module.exports = Doctor;
