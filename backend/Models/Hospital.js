const { db } = require("../firebase"); // Import shared Firebase instance

const hospitalsCollection = db.collection("hospitals");

class Hospital {
  constructor({ name, address, mobileNumbers, emails, admin, suspended = false }) {
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
    if (admin !== undefined && typeof admin !== "string")
      throw new Error("Invalid admin: must be a string or undefined");
    if (typeof suspended !== "boolean")
      throw new Error("Invalid suspended: must be a boolean");

    this.name = name;
    this.address = address;
    this.mobileNumbers = mobileNumbers;
    this.emails = emails;
    this.admin = admin;
    this.suspended = suspended;
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
