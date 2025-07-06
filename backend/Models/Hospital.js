const { db } = require("../firebase"); // Import shared Firebase instance

const hospitalsCollection = db.collection("hospitals");

class Hospital {
  constructor({ name, address, mobileNumbers, emails, admin = "", suspended = false, appointments = [], patients = [], doctors = [] }) {
    if (typeof name !== "string")
      throw new Error("Invalid name: must be a string");
    if (typeof address !== "string")
      throw new Error("Invalid address: must be a string");
    if (
      !Array.isArray(mobileNumbers) ||
      !mobileNumbers.every((num) => typeof num === "string")
    ) {
      throw new Error("Invalid mobileNumbers: must be an array of strings");
    }
    if (
      !Array.isArray(emails) ||
      !emails.every((email) => typeof email === "string")
    ) {
      throw new Error("Invalid emails: must be an array of strings");
    }
    if (admin !== undefined && admin !== null && typeof admin !== "string")
      throw new Error("Invalid admin: must be a string, null, or undefined");
    if (typeof suspended !== "boolean")
      throw new Error("Invalid suspended: must be a boolean");
    if (!Array.isArray(appointments))
      throw new Error("Invalid appointments: must be an array");
    if (!Array.isArray(patients))
      throw new Error("Invalid patients: must be an array");
    if (!Array.isArray(doctors))
      throw new Error("Invalid doctors: must be an array");

    this.name = name;
    this.address = address;
    this.mobileNumbers = mobileNumbers;
    this.emails = emails;
    this.admin = admin || ""; // Default to empty string
    this.suspended = suspended;
    this.appointments = appointments;
    this.patients = patients;
    this.doctors = doctors;
    this.createdAt = new Date();
    this.updatedAt = new Date();
  }

  async save() {
    try {
      this.updatedAt = new Date();
      const docRef = await hospitalsCollection.add({ ...this });
      return docRef.id;
    } catch (error) {
      throw new Error("Error saving hospital: " + error.message);
    }
  }
}

module.exports = Hospital;
