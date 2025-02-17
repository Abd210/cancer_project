const { db } = require("../firebase"); // Import shared Firebase instance

const devicesCollection = db.collection("devices");

const STATUSES = ["operational", "malfunctioned", "standby"];

class Device {
  constructor({
    hospital,
    patient = null,
    device_code,
    purpose = "",
    status,
    suspended = false,
  }) {
    if (typeof hospital !== "string")
      throw new Error(
        "Invalid hospital: must be a Firestore document reference"
      );
    if (patient !== null && typeof patient !== "string")
      throw new Error(
        "Invalid patient: must be a Firestore document reference"
      );
    if (typeof device_code !== "string")
      throw new Error("Invalid device_code: must be a string");
    if (typeof purpose !== "string")
      throw new Error("Invalid purpose: must be a string");
    if (!STATUSES.includes(status))
      throw new Error(
        `Invalid status: ${status}. Allowed: ${STATUSES.join(", ")}`
      );
    if (typeof suspended !== "boolean")
      throw new Error("Invalid suspended: must be a boolean");

    this.hospital = hospital;
    this.patient = patient;
    this.device_code = device_code;
    this.purpose = purpose;
    this.status = status;
    this.suspended = suspended;
    this.createdAt = new Date();
    this.updatedAt = new Date();
  }

  async save() {
    try {
      this.updatedAt = new Date();
      const docRef = await devicesCollection.add({ ...this });
      return docRef.id;
    } catch (error) {
      throw new Error("Error saving device: " + error.message);
    }
  }
}

module.exports = Device;
