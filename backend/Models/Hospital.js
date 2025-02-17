const { db } = require("../firebase"); // Import shared Firebase instance

const hospitalsCollection = db.collection("hospitals");

class Hospital {
  constructor({
    hospital_name,
    hospital_address,
    mobile_numbers,
    emails,
    suspended = false,
  }) {
    if (typeof hospital_name !== "string")
      throw new Error("Invalid hospital_name: must be a string");
    if (typeof hospital_address !== "string")
      throw new Error("Invalid hospital_address: must be a string");
    if (
      !Array.isArray(mobile_numbers) ||
      !mobile_numbers.every((num) => typeof num === "string")
    ) {
      throw new Error("Invalid mobile_numbers: must be an array of strings");
    }
    if (
      !Array.isArray(emails) ||
      !emails.every((email) => typeof email === "string")
    ) {
      throw new Error("Invalid emails: must be an array of strings");
    }
    if (typeof suspended !== "boolean")
      throw new Error("Invalid suspended: must be a boolean");

    this.hospital_name = hospital_name;
    this.hospital_address = hospital_address;
    this.mobile_numbers = mobile_numbers;
    this.emails = emails;
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
