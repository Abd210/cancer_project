const admin = require("firebase-admin");
const db = admin.firestore();


// Helper: Convert a Date object to a "HH:mm" string.
const formatTime = (dateObj) => {
  const hh = String(dateObj.getHours()).padStart(2, "0");
  const mm = String(dateObj.getMinutes()).padStart(2, "0");
  return `${hh}:${mm}`;
};

// Helper: Convert "HH:mm" to minutes since midnight.
const timeToMinutes = (timeStr) => {
  const [hours, minutes] = timeStr.split(":").map(Number);
  return hours * 60 + minutes;
};

// Helper: Derive the day (e.g., "Monday") from a Date object.
const getDayFromDate = (dateObj) => {
  return dateObj.toLocaleString("en-US", { weekday: "long" });
};

class AppointmentService {
  /**
   * Get all upcoming appointments.
   * Upcoming appointments are those with:
   * - appointmentDate greater than or equal to now, and
   * - status equal to "scheduled".
   * Results are ordered by appointmentDate in ascending order.
   *
   * @returns {Promise<Array>} List of upcoming appointment objects.
   */
  static async getAllUpcomingAppointments() {
    try {
      const snapshot = await db
        .collection("appointments")
        .where("appointmentDate", ">=", new Date())
        .where("status", "==", "scheduled")
        .orderBy("appointmentDate")
        .get();

      if (snapshot.empty) {
        return [];
      }

      return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
      throw new Error(`AppointmentService: ${error.message}`);
    }
  }

  /**
   * Fetches upcoming appointments for a specific user based on their role (doctor or patient).
   * Filters appointments that are scheduled and in the future.
   */
  static async getUpcomingAppointmentsForSpecificPatientOrDoctor({
    entity_role,
    entity_id,
  }) {
    if (!entity_id) {
      throw new Error(
        "appointmentService-getUpcomingAppointments: Invalid entity_id"
      );
    }

    const field = entity_role === "doctor" ? "doctor" : "patient";

    // let queryRef = db.collection("appointments");
    // queryRef = queryRef.where(field, "==", entity_id);
    // queryRef = queryRef.where("appointmentDate", ">=", new Date());
    // queryRef = queryRef.where("status", "==", "scheduled");
    // queryRef = queryRef.orderBy("appointmentDate");
    // const snapshot = await queryRef.get();

    const snapshot = await db
      .collection("appointments")
      .where(field, "==", entity_id)
      .where("appointmentDate", ">=", new Date())
      .where("status", "==", "scheduled")
      .orderBy("appointmentDate")
      .get();

    if (snapshot.empty) {
      return [];
    }

    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Fetches past appointments for a specific user based on their role (doctor or patient).
   * Filters appointments that have already occurred.
   */
  static async getAppointmentHistory({
    user_id,
    role,
    filterById,
    filterByRole,
  }) {
    if (!user_id) {
      throw new Error(
        "appointmentService-getAppointmentHistory: Invalid user_id"
      );
    }

    let queryRef = db.collection("appointments");

    if (role === "doctor") {
      queryRef = queryRef.where("doctor", "==", user_id);
    } else if (role === "patient") {
      queryRef = queryRef.where("patient", "==", user_id);
    } else if (role === "superadmin" && filterById && filterByRole) {
      if (filterByRole === "patient") {
        queryRef = queryRef.where("patient", "==", filterById);
      } else {
        queryRef = queryRef.where("doctor", "==", filterById);
      }
      // queryRef = queryRef.where(filterByRole, "==", filterById);
    }

    queryRef = queryRef
      .where("appointmentDate", "<", new Date())
      .orderBy("appointmentDate", "desc");

    const snapshot = await queryRef.get();

    if (snapshot.empty) {
      return [];
    }

    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Retrieves appointments for a specific date.
   *
   * @param {String} date - The date in 'YYYY-MM-DD' format.
   *
   * @returns {Promise<Array>} Returns a list of appointments scheduled for the given date.
   */
  static async getAppointmentsByDate(date) {
    const startDate = new Date(date);
    startDate.setHours(0, 0, 0, 0); // Beginning of the day
    const endDate = new Date(date);
    endDate.setHours(23, 59, 59, 999); // End of the day

    const snapshot = await db
      .collection("appointments")
      .where(
        "appointmentDate",
        ">=",
        admin.firestore.Timestamp.fromDate(startDate)
      )
      .where(
        "appointmentDate",
        "<=",
        admin.firestore.Timestamp.fromDate(endDate)
      )
      .orderBy("appointmentDate")
      .get();

    if (snapshot.empty) {
      return [];
    }

    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Cancels an appointment by updating its status to 'cancelled'.
   */
  static async cancelAppointment(appointment_id) {
    if (!appointment_id) {
      throw new Error(
        "appointmentService-cancelAppointment: Invalid appointment_id"
      );
    }

    const appointmentRef = db.collection("appointments").doc(appointment_id);
    const appointmentDoc = await appointmentRef.get();

    if (!appointmentDoc.exists) {
      throw new Error(
        "appointmentService-cancelAppointment: Appointment not found"
      );
    }

    await appointmentRef.update({ status: "cancelled" });

    return { message: "Appointment cancelled successfully", appointment_id };
  }

  /**
   * Checks if a doctor or patient exists in the database by their ID.
   */
  static async checkEntityExists(entityRole, entityId) {
    if (!entityId) {
      throw new Error(
        "appointmentService-checkEntityExists: Invalid entity_id"
      );
    }

    const collection = entityRole === "doctor" ? "doctors" : "patients";
    const entityDoc = await db.collection(collection).doc(entityId).get();

    if (!entityDoc.exists) {
      return false;
    }

    return true;
  }

  /**
   * Creates a new appointment.
   */
  static async createAppointment({
    patient,
    doctor,
    // appointmentDate,
    // day,         // New required attribute (e.g., "Monday")
    // startTime,
    // endTime,
    start,    // new full date-time string / Date
    end,      // new full date-time string / Date
    purpose,
    status = "scheduled",
    suspended = false,
  }) {
    // Ensure that doctor and patient exist.
    if (
      !(await this.checkEntityExists("doctor", doctor)) ||
      !(await this.checkEntityExists("patient", patient))
    ) {
      throw new Error(
        "appointmentService-createAppointment: Doctor or Patient not found"
      );
    }

    // // Validate required fields.
    // if (!day || !startTime || !endTime) {
    //   // throw new Error(
    //   //   "appointmentService-createAppointment: Missing required fields (day, startTime, endTime)"
    //   // );
    //   const error = new Error(`appointmentService-createAppointment: Missing required fields (day, startTime, endTime)`);
    //   error.status = 400;
    //   throw error;
    // }
    // const timeRegex = /^([01]\d|2[0-3]):([0-5]\d)$/;
    // if (!timeRegex.test(startTime) || !timeRegex.test(endTime)) {
    //   // throw new Error(
    //   //   "appointmentService-createAppointment: Invalid time format, expected HH:mm"
    //   // );
    //   const error = new Error(`appointmentService-createAppointment: Invalid time format, expected HH:mm`);
    //   error.status = 400;
    //   throw error;
    // }
    // const timeToMinutes = (timeStr) => {
    //   const [h, m] = timeStr.split(":").map(Number);
    //   return h * 60 + m;
    // };
    // if (timeToMinutes(startTime) >= timeToMinutes(endTime)) {
    //   // throw new Error(
    //   //   "appointmentService-createAppointment: startTime must be before endTime"
    //   // );
    //   const error = new Error(`appointmentService-createAppointment: startTime must be before endTime`);
    //   error.status = 400;
    //   throw error;
    // }

    // // Fetch the doctor's document to access the schedule.
    // const doctorDoc = await db.collection("doctors").doc(doctor).get();
    // if (!doctorDoc.exists) {
    //   throw new Error("appointmentService-createAppointment: Doctor not found");
    // }
    // const doctorData = doctorDoc.data();
    // const doctorSchedule = doctorData.schedule; // Array of { day, start, end } objects

    // // Check that the doctor's schedule includes the requested day.
    // const daySchedule = doctorSchedule.find(
    //   (sched) => sched.day.toLowerCase() === day.toLowerCase()
    // );
    // if (!daySchedule) {
    //   // throw new Error(
    //   //   `appointmentService-createAppointment: Doctor is not available on ${day}`
    //   // );
    //   const error = new Error(`appointmentService-createAppointment: Doctor is not available on ${day}`);
    //   error.status = 400;
    //   throw error;
    // }
    // // Ensure the requested appointment time is within the doctor's available hours.
    // if (
    //   timeToMinutes(startTime) < timeToMinutes(daySchedule.start) ||
    //   timeToMinutes(endTime) > timeToMinutes(daySchedule.end)
    // ) {
    //   // throw new Error(
    //   //   `appointmentService-createAppointment: Appointment time frame is outside the doctor's schedule on ${day}`
    //   // );
    //   const error = new Error(`appointmentService-createAppointment: Appointment time frame is outside the doctor's schedule on ${day}`);
    //   error.status = 400;
    //   throw error;
    // }

    // // Check for overlapping appointments on the same day for the same doctor.
    // const overlappingSnapshot = await db
    //   .collection("appointments")
    //   .where("doctor", "==", doctor)
    //   .where("day", "==", day)
    //   .where("status", "==", "scheduled")
    //   .get();

    // const overlappingAppointments = overlappingSnapshot.docs
    //   .map((doc) => doc.data())
    //   .filter((app) => {
    //     const existingStart = timeToMinutes(app.startTime);
    //     const existingEnd = timeToMinutes(app.endTime);
    //     const newStart = timeToMinutes(startTime);
    //     const newEnd = timeToMinutes(endTime);
    //     // Overlap condition: newStart < existingEnd && existingStart < newEnd
    //     return newStart < existingEnd && existingStart < newEnd;
    //   });

    // if (overlappingAppointments.length > 0) {
    //   // throw new Error(
    //   //   "appointmentService-createAppointment: There is an existing overlapping appointment for this doctor on the specified day"
    //   // );
    //   const error = new Error(`appointmentService-createAppointment: There is an existing overlapping appointment for this doctor on the specified day`);
    //   error.status = 400;
    //   throw error;
    // }

    // Convert start and end to Date objects (if not already)
    const startDate = start instanceof Date ? start : new Date(start);
    const endDate = end instanceof Date ? end : new Date(end);
    if (isNaN(startDate) || isNaN(endDate)) {
      // throw new Error("appointmentService-createAppointment: Invalid start or end date");
      const error = new Error("appointmentService-createAppointment: Invalid start or end date");
      error.status = 400;
      throw error;
    }
    if (startDate >= endDate) {
      // throw new Error("appointmentService-createAppointment: Start date/time must be before end date/time");
      const error = new Error("appointmentService-createAppointment: Start date/time must be before end date/time");
      error.status = 400;
      throw error;
    }

    // Derive day and time-of-day strings.
    const day = getDayFromDate(startDate); // e.g., "Monday"
    const startTimeStr = formatTime(startDate); // "HH:mm"
    const endTimeStr = formatTime(endDate);       // "HH:mm"

    // Fetch the doctor's schedule.
    const doctorDoc = await db.collection("doctors").doc(doctor).get();
    if (!doctorDoc.exists) {
      // throw new Error("appointmentService-createAppointment: Doctor not found");
      const error = new Error("appointmentService-createAppointment: Doctor not found");
      error.status = 400;
      throw error;
    }
    const doctorData = doctorDoc.data();
    const doctorSchedule = doctorData.schedule; // e.g., [{ day: "Monday", start: "09:00", end: "17:00" }, …]
    const daySchedule = doctorSchedule.find(
      (sched) => sched.day.toLowerCase() === day.toLowerCase()
    );
    if (!daySchedule) {
      // throw new Error(`appointmentService-createAppointment: Doctor is not available on ${day}`);
      const error = new Error(`appointmentService-createAppointment: Doctor is not available on ${day}`);
      error.status = 400;
      throw error;
    }
    // Check if the appointment's times fall within the doctor's working hours.
    if (
      timeToMinutes(startTimeStr) < timeToMinutes(daySchedule.start) ||
      timeToMinutes(endTimeStr) > timeToMinutes(daySchedule.end)
    ) {
      // throw new Error(`appointmentService-createAppointment: Appointment time frame (${startTimeStr} - ${endTimeStr}) is outside the doctor's schedule on ${day}`);
      const error = new Error(`appointmentService-createAppointment: Appointment time frame (${startTimeStr} - ${endTimeStr}) is outside the doctor's schedule on ${day}`);
      error.status = 400;
      throw error;
    }

    // Overlap check: Query for other appointments for that doctor on the same date.
    // We'll compare by deriving the date portion of the start time.
    const dayStart = new Date(startDate);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(startDate);
    dayEnd.setHours(23, 59, 59, 999);

    const overlappingSnapshot = await db
      .collection("appointments")
      .where("doctor", "==", doctor)
      .where("start", ">=", admin.firestore.Timestamp.fromDate(dayStart))
      .where("start", "<=", admin.firestore.Timestamp.fromDate(dayEnd))
      .where("status", "==", "scheduled")
      .get();

    const overlappingAppointments = overlappingSnapshot.docs
      .map(doc => doc.data())
      .filter(app => {
        // For each existing appointment, extract the start and end times.
        const existingStart = timeToMinutes(formatTime(app.start.toDate()));
        const existingEnd = timeToMinutes(formatTime(app.end.toDate()));
        const newStart = timeToMinutes(startTimeStr);
        const newEnd = timeToMinutes(endTimeStr);
        // Check for overlap condition: newStart < existingEnd && existingStart < newEnd
        return newStart < existingEnd && existingStart < newEnd;
      });
    if (overlappingAppointments.length > 0) {
      // throw new Error("appointmentService-createAppointment: There is an existing overlapping appointment for this doctor on the specified date");
      const error = new Error("appointmentService-createAppointment: There is an existing overlapping appointment for this doctor on the specified date");
      error.status = 400;
      throw error;
    }

    const appointmentData = {
      patient,
      doctor,
      // appointmentDate: admin.firestore.Timestamp.fromDate(
      //   new Date(appointmentDate)
      // ),
      // day,
      // startTime,
      // endTime,
      start: admin.firestore.Timestamp.fromDate(startDate),  // Stores full date & time.
      end: admin.firestore.Timestamp.fromDate(endDate),
      purpose,
      status,
      suspended,
      createdAt: new Date(),
      updatedAt: new Date(),
      // Optionally store the derived day and time-of-day strings for easier querying.
      // day,                   // e.g., "Monday"
      // startTime: startTimeStr, // e.g., "14:00"
      // endTime: endTimeStr      // e.g., "15:00"
    };

    const newAppointmentRef = await db
      .collection("appointments")
      .add(appointmentData);

    return {
      message: "Appointment created successfully",
      id: newAppointmentRef.id,
      ...appointmentData,
    };
  }

  /**
   * Finds an appointment by its unique identifier.
   */
  static async findAppointment(appointment_id) {
    if (!appointment_id) {
      throw new Error(
        "appointmentService-findAppointment: Invalid appointment_id"
      );
    }

    const appointmentDoc = await db
      .collection("appointments")
      .doc(appointment_id)
      .get();

    if (!appointmentDoc.exists) {
      throw new Error(
        "appointmentService-findAppointment: Appointment not found"
      );
    }

    return { id: appointmentDoc.id, ...appointmentDoc.data() };
  }

  /**
   * Deletes an appointment from Firestore.
   */
  static async deleteAppointment(appointment_id) {
    if (!appointment_id) {
      throw new Error(
        "appointmentService-deleteAppointment: Invalid appointment_id"
      );
    }

    const appointmentRef = db.collection("appointments").doc(appointment_id);
    const appointmentDoc = await appointmentRef.get();

    if (!appointmentDoc.exists) {
      throw new Error(
        "appointmentService-deleteAppointment: Appointment not found"
      );
    }

    await appointmentRef.delete();

    return;
  }

  /**
   * Updates an appointment in Firestore.
   */
  static async updateAppointment(appointmentId, updateFields, user) {

    console.log("updateFields yoomo", updateFields);
    if (!appointmentId) {
      throw new Error(
        "appointmentService-updateAppointment: Invalid appointmentId"
      );
    }

    if (updateFields.id) {
      throw new Error(
        "appointmentService-updateAppointment: Changing 'id' is not allowed"
      );
    }

    if (updateFields.suspended && user.role !== "superadmin") {
      throw new Error(
        "appointmentService-updateAppointment: Only superadmins can suspend appointments"
      );
    }

    const appointmentRef = db.collection("appointments").doc(appointmentId);
    const appointmentDoc = await appointmentRef.get();

    if (!appointmentDoc.exists) {
      throw new Error(
        "appointmentService-updateAppointment: Appointment not found"
      );
    }
    const currentAppointment = appointmentDoc.data();

    // // If either time frame attributes or the doctor are being updated, perform additional checks.
    // if (updateFields.day || updateFields.startTime || updateFields.endTime || updateFields.doctor) {
    //   console.log("updateFields yoomo 2", updateFields);
    //   // Use new values if provided, else fallback to existing ones.
    //   const newDay = updateFields.day ? updateFields.day : currentAppointment.day;
    //   const newStartTime = updateFields.startTime ? updateFields.startTime : currentAppointment.startTime;
    //   const newEndTime = updateFields.endTime ? updateFields.endTime : currentAppointment.endTime;
    //   const newDoctor = updateFields.doctor ? updateFields.doctor : currentAppointment.doctor;

    //   // Validate presence of required fields.
    //   if (!newDay || !newStartTime || !newEndTime) {
    //     const error = new Error("appointmentService-updateAppointment: day, startTime, and endTime are required for time frame updates");
    //     error.status = 400;
    //     throw error;
    //   }

    //   // Validate time format (HH:mm) using a regular expression.
    //   const timeRegex = /^([01]\d|2[0-3]):([0-5]\d)$/;
    //   if (!timeRegex.test(newStartTime) || !timeRegex.test(newEndTime)) {
    //     const error = new Error("appointmentService-updateAppointment: Invalid time format. Expected HH:mm");
    //     error.status = 400;
    //     throw error;
    //   }
    //   if (timeToMinutes(newStartTime) >= timeToMinutes(newEndTime)) {
    //     const error = new Error("appointmentService-updateAppointment: startTime must be before endTime");
    //     error.status = 400;
    //     throw error;
    //   }

    //   // Validate the doctor exists and retrieve doctor's schedule.
    //   const doctorDoc = await db.collection("doctors").doc(newDoctor).get();
    //   if (!doctorDoc.exists) {
    //     const error = new Error("appointmentService-updateAppointment: Doctor not found");
    //     error.status = 400;
    //     throw error;
    //   }

    //   console.log("yoomoo 5", doctorDoc.data());
    //   const doctorData = doctorDoc.data();
    //   const doctorSchedule = doctorData.schedule; // Array of objects: [{ day, start, end }, ...]
    //   console.log("yoomoo 6", doctorSchedule);

    //   // Ensure doctor works on newDay.
    //   const daySchedule = doctorSchedule.find(
    //     (sched) => sched.day.toLowerCase() === newDay.toLowerCase()
    //   );
    //   if (!daySchedule) {
    //     const error = new Error(`appointmentService-updateAppointment: Doctor is not available on ${newDay}`);
    //     error.status = 400;
    //     throw error;
    //   }

    //   // Check that the new time frame fits within the doctor's schedule.
    //   if (
    //     timeToMinutes(newStartTime) < timeToMinutes(daySchedule.start) ||
    //     timeToMinutes(newEndTime) > timeToMinutes(daySchedule.end)
    //   ) {
    //     const error = new Error(`appointmentService-updateAppointment: Appointment time frame (${newStartTime}-${newEndTime}) is outside the doctor's schedule on ${newDay}`);
    //     error.status = 400;
    //     throw error;
    //   }

    //   // Check for overlapping appointments on the same day, excluding the current appointment.
    //   const overlappingSnapshot = await db
    //     .collection("appointments")
    //     .where("doctor", "==", newDoctor)
    //     .where("day", "==", newDay)
    //     .where("status", "==", "scheduled")
    //     .get();
    //   const overlappingAppointments = overlappingSnapshot.docs
    //     .filter(doc => doc.id !== appointmentId)
    //     .map(doc => doc.data())
    //     .filter(app => {
    //       const existingStart = timeToMinutes(app.startTime);
    //       const existingEnd = timeToMinutes(app.endTime);
    //       const newStart = timeToMinutes(newStartTime);
    //       const newEnd = timeToMinutes(newEndTime);
    //       // Overlap if newStart < existingEnd && existingStart < newEnd.
    //       return newStart < existingEnd && existingStart < newEnd;
    //     });

    //   if (overlappingAppointments.length > 0) {
    //     const error = new Error("appointmentService-updateAppointment: There is an existing overlapping appointment for this doctor on the specified day");
    //     error.status = 400;
    //     throw error;
    //   }

    //   // If we passed all the checks, updateFields should include the (validated) new time frame and doctor.
    //   updateFields.day = newDay;
    //   updateFields.startTime = newStartTime;
    //   updateFields.endTime = newEndTime;
    //   updateFields.doctor = newDoctor;

    //   console.log("updateFields yoomo 3", updateFields);
    // }

    // If start, end, or doctor is updated, we need to run validations.
    if (updateFields.start || updateFields.end || updateFields.doctor) {
      const newStart = updateFields.start ? new Date(updateFields.start) : currentAppointment.start.toDate();
      const newEnd = updateFields.end ? new Date(updateFields.end) : currentAppointment.end.toDate();
      if (newStart >= newEnd) {
        // throw new Error("appointmentService-updateAppointment: Start must be before end");
        const error = new Error("appointmentService-updateAppointment: Start must be before end");
        error.status = 400;
        throw error;
      }
      // Derive day and time strings
      const derivedDay = getDayFromDate(newStart);
      const derivedStartTime = formatTime(newStart);
      const derivedEndTime = formatTime(newEnd);
      // Use new doctor if provided, otherwise use current doctor.
      const newDoctor = updateFields.doctor ? updateFields.doctor : currentAppointment.doctor;

      // Fetch the doctor and his/her schedule.
      const doctorDoc = await db.collection("doctors").doc(newDoctor).get();
      if (!doctorDoc.exists) {
        // throw new Error("appointmentService-updateAppointment: Doctor not found");
        const error = new Error("appointmentService-updateAppointment: Doctor not found");
        error.status = 400;
        throw error;
      }
      const doctorData = doctorDoc.data();
      const doctorSchedule = doctorData.schedule;
      const daySchedule = doctorSchedule.find(
        (sched) => sched.day.toLowerCase() === derivedDay.toLowerCase()
      );
      if (!daySchedule) {
        // throw new Error(`appointmentService-updateAppointment: Doctor is not available on ${derivedDay}`);
        const error = new Error(`appointmentService-updateAppointment: Doctor is not available on ${derivedDay}`);
        error.status = 400;
        throw error;
      }
      if (
        timeToMinutes(derivedStartTime) < timeToMinutes(daySchedule.start) ||
        timeToMinutes(derivedEndTime) > timeToMinutes(daySchedule.end)
      ) {
        // throw new Error(`appointmentService-updateAppointment: Updated time frame (${derivedStartTime}-${derivedEndTime}) is outside the doctor's schedule on ${derivedDay}`);
        const error = new Error(`appointmentService-updateAppointment: Updated time frame (${derivedStartTime}-${derivedEndTime}) is outside the doctor's schedule on ${derivedDay}`);
        error.status = 400;
        throw error;
      }

      // Overlapping check:
      const dayStart = new Date(newStart);
      dayStart.setHours(0, 0, 0, 0);
      const dayEnd = new Date(newStart);
      dayEnd.setHours(23, 59, 59, 999);

      const overlappingSnapshot = await db
        .collection("appointments")
        .where("doctor", "==", newDoctor)
        .where("start", ">=", admin.firestore.Timestamp.fromDate(dayStart))
        .where("start", "<=", admin.firestore.Timestamp.fromDate(dayEnd))
        .where("status", "==", "scheduled")
        .get();

      const overlappingAppointments = overlappingSnapshot.docs
        .filter(doc => doc.id !== appointmentId)
        .map(doc => doc.data())
        .filter(app => {
          const existingStart = timeToMinutes(formatTime(app.start.toDate()));
          const existingEnd = timeToMinutes(formatTime(app.end.toDate()));
          const newStartMinutes = timeToMinutes(derivedStartTime);
          const newEndMinutes = timeToMinutes(derivedEndTime);
          return newStartMinutes < existingEnd && existingStart < newEndMinutes;
        });
      if (overlappingAppointments.length > 0) {
        // throw new Error("appointmentService-updateAppointment: There is an existing overlapping appointment for this doctor on the specified date");
        const error = new Error("appointmentService-updateAppointment: There is an existing overlapping appointment for this doctor on the specified date");
        error.status = 400;
        throw error;
      }

      // Update the fields with the validated and derived values.
      updateFields.start = admin.firestore.Timestamp.fromDate(newStart);
      updateFields.end = admin.firestore.Timestamp.fromDate(newEnd);
      updateFields.doctor = newDoctor;
      // Optionally update these derived fields if you wish to store them:
      // updateFields.day = derivedDay;
      // updateFields.startTime = derivedStartTime;
      // updateFields.endTime = derivedEndTime;
    }

    if (updateFields.patient) {
      if (!(await this.checkEntityExists("patient", updateFields.patient))) {
        throw new Error(
          "appointmentService-updateAppointment: Patient not found"
        );
      }
    }

    // if (updateFields.doctor) {
    //   if (!(await this.checkEntityExists("doctor", updateFields.doctor))) {
    //     throw new Error(
    //       "appointmentService-updateAppointment: Doctor not found"
    //     );
    //   }
    // }

    // If appointmentDate is present, convert it to a Firestore Timestamp.
    // if (updateFields.appointmentDate) {
    //   updateFields.appointmentDate = admin.firestore.Timestamp.fromDate(
    //     new Date(updateFields.appointmentDate)
    //   );
    // }

    if (updateFields.status) {
      const STATUSES = [
        "scheduled",
        "cancelled",
        "completed",
        "no-show",
        "rescheduled",
      ];
      if (!STATUSES.includes(updateFields.status)) {
        throw new Error(
          `Invalid status: ${updateFields.status}. Allowed: ${STATUSES.join(
            ", "
          )}`
        );
      }
      // If status is being updated, ensure it is one of the allowed statuses.
    }

    updateFields.updatedAt = new Date();

    await appointmentRef.update(updateFields);

    const updatedAppointmentDoc = await appointmentRef.get();
    const updatedAppointment = {
      id: updatedAppointmentDoc.id,
      ...updatedAppointmentDoc.data(),
    };
    return updatedAppointment;
  }
}

module.exports = AppointmentService;
