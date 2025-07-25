const { db } = require("../firebase"); // Import shared Firebase instance

const appointmentsCollection = db.collection("appointments");

const STATUSES = ["scheduled", "cancelled", "completed", "pending", "declined"];

// Helper: Convert "HH:mm" to minutes since midnight.
function timeToMinutes(timeStr) {
  const [hours, minutes] = timeStr.split(":").map(Number);
  return hours * 60 + minutes;
}

class Appointment {
  constructor({
    patient,
    doctor,
    hospital, // New required attribute (hospital ID)
    // day,           // New required attribute (e.g. "Monday")
    // appointmentDate,
    // startTime,
    // endTime,
    start, // Full Date
    end, // Full Date
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
    if (typeof hospital !== "string")
      throw new Error("Invalid hospital: must be a Firestore document reference");
    // if (!(appointmentDate instanceof Date))
    //   throw new Error("Invalid appointmentDate: must be a Date object");
    // if (typeof day !== "string")
    //   throw new Error("Invalid day: must be a string (e.g., 'Monday')");
    if (!(start instanceof Date))
      throw new Error("Invalid start: must be a Date object");
    if (!(end instanceof Date))
      throw new Error("Invalid end: must be a Date object");
    if (start >= end)
      throw new Error("Invalid time frame: start must be before end");

    // const timeRegex = /^([01]\d|2[0-3]):([0-5]\d)$/;
    // if (typeof startTime !== "string" || !timeRegex.test(startTime))
    //   throw new Error("Invalid startTime: must be a string in HH:mm format");
    // if (typeof endTime !== "string" || !timeRegex.test(endTime))
    //   throw new Error("Invalid endTime: must be a string in HH:mm format");
    // if (timeToMinutes(startTime) >= timeToMinutes(endTime))
    //   throw new Error("Invalid time frame: startTime must be before endTime");

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
    this.hospital = hospital; // Hospital ID (Firestore document reference)
    // this.day = day;
    // this.startTime = startTime;
    // this.endTime = endTime;
    // this.appointmentDate = appointmentDate;
    this.start = start; // Full date and time
    this.end = end; // Full date and time
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
      console.error("Error in Appointment.save:", error);
      throw new Error("Error saving appointment: " + error.message);
    }
  }
}

module.exports = Appointment;
