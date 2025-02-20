const { db } = require("../firebase"); // Import shared Firebase instance

const bcrypt = require("bcrypt");

const patientsCollection = db.collection("patients");

const ROLES = ["patient"];
const STATUSES = ["recovering", "recovered", "active", "inactive"];

class Patient {
  constructor({
    pers_id,
    password,
    name,
    email,
    mobile_number,
    birthDate,
    hospital,
    status = "active",
    diagnosis = "Not Diagnosed",
    medicalHistory = [],
    role = "patient",
    suspended = false,
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
    if (!(birthDate instanceof Date))
      throw new Error("Invalid birthDate: must be a Date object");
    if (typeof hospital !== "string")
      throw new Error(
        "Invalid hospital: must be a Firestore document reference"
      );
    if (!STATUSES.includes(status))
      throw new Error(
        `Invalid status: ${status}. Allowed: ${STATUSES.join(", ")}`
      );
    if (typeof diagnosis !== "string")
      throw new Error("Invalid diagnosis: must be a string");
    if (!Array.isArray(medicalHistory))
      throw new Error("Invalid medicalHistory: must be an array of strings");
    if (!ROLES.includes(role))
      throw new Error(`Invalid role: ${role}. Allowed: ${ROLES.join(", ")}`);
    if (typeof suspended !== "boolean")
      throw new Error("Invalid suspended: must be a boolean");

    this.pers_id = pers_id;
    this.password = password;
    this.name = name;
    this.email = email;
    this.mobile_number = mobile_number;
    this.birthDate = birthDate;
    this.hospital = hospital;
    this.status = status;
    this.diagnosis = diagnosis;
    this.medicalHistory = medicalHistory;
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
      const docRef = await patientsCollection.add({ ...this });
      return docRef.id;
    } catch (error) {
      throw new Error("Error saving patient: " + error.message);
    }
  }

  async comparePassword(candidatePassword) {
    return bcrypt.compare(candidatePassword, this.password);
  }
}

module.exports = Patient;
