const { db } = require("../firebase"); // Import shared Firebase instance

const appointmentsCollection = db.collection("appointments");

const STATUSES = ["scheduled", "cancelled", "completed"];

class Appointment {
  constructor({
    patient,
    doctor,
    appointment_date,
    purpose,
    status = "scheduled",
    suspended = false,
  }) {
    if (typeof patient !== "string")
      throw new Error(
        "Invalid patient: must be a Firestore document reference"
      );
    if (typeof doctor !== "string")
      throw new Error("Invalid doctor: must be a Firestore document reference");
    if (!(appointment_date instanceof Date))
      throw new Error("Invalid appointment_date: must be a Date object");
    if (typeof purpose !== "string")
      throw new Error("Invalid purpose: must be a string");
    if (!STATUSES.includes(status))
      throw new Error(
        `Invalid status: ${status}. Allowed: ${STATUSES.join(", ")}`
      );
    if (typeof suspended !== "boolean")
      throw new Error("Invalid suspended: must be a boolean");

    this.patient = patient;
    this.doctor = doctor;
    this.appointment_date = appointment_date;
    this.purpose = purpose;
    this.status = status;
    this.suspended = suspended;
    this.createdAt = new Date();
    this.updatedAt = new Date();
  }

  async save() {
    try {
      this.updatedAt = new Date();
      const docRef = await appointmentsCollection.add({ ...this });
      return docRef.id;
    } catch (error) {
      throw new Error("Error saving appointment: " + error.message);
    }
  }
}

module.exports = Appointment;
