const { db } = require("../firebase"); // Import shared Firebase instance

const testsCollection = db.collection("tests");

const STATUSES = ["reviewed", "in_progress", "pending"];

class Test {
  constructor({
    patient,
    doctor,
    device = null,
    result_date = null,
    status = "pending",
    purpose,
    review = "",
    results = [],
    suspended = false,
  }) {
    if (typeof patient !== "string")
      throw new Error(
        "Invalid patient: must be a Firestore document reference"
      );
    if (typeof doctor !== "string")
      throw new Error("Invalid doctor: must be a Firestore document reference");
    if (device !== null && typeof device !== "string")
      throw new Error("Invalid device: must be a Firestore document reference");
    if (result_date !== null && !(result_date instanceof Date))
      throw new Error("Invalid result_date: must be a Date object");
    if (!STATUSES.includes(status))
      throw new Error(
        `Invalid status: ${status}. Allowed: ${STATUSES.join(", ")}`
      );
    if (typeof purpose !== "string")
      throw new Error("Invalid purpose: must be a string");
    if (typeof review !== "string")
      throw new Error("Invalid review: must be a string");
    if (!Array.isArray(results))
      throw new Error("Invalid results: must be an array of strings");
    if (typeof suspended !== "boolean")
      throw new Error("Invalid suspended: must be a boolean");

    this.patient = patient;
    this.doctor = doctor;
    this.device = device;
    this.result_date = result_date;
    this.status = status;
    this.purpose = purpose;
    this.review = review;
    this.results = results;
    this.suspended = suspended;
    this.createdAt = new Date();
    this.updatedAt = new Date();
  }

  async save() {
    try {
      this.updatedAt = new Date();
      const docRef = await testsCollection.add({ ...this });
      return docRef.id;
    } catch (error) {
      throw new Error("Error saving test result: " + error.message);
    }
  }
}

module.exports = Test;
