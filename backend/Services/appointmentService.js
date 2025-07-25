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
   * (- status equal to "scheduled".)
   * Results are ordered by appointmentDate in ascending order.
   *
   * @returns {Promise<Array>} List of upcoming appointment objects.
   */
  static async getAllUpcomingAppointments() {
    try {
      const snapshot = await db
        .collection("appointments")
        .where("start", ">=", new Date())
//        .where("status", "==", "scheduled")
        .orderBy("start")
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
   * Filters appointments (that are scheduled and) in the future.
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

    const snapshot = await db
      .collection("appointments")
      .where(field, "==", entity_id)
      .where("start", ">=", new Date())
//      .where("status", "==", "scheduled")
      .orderBy("start")
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
      .where("start", "<", new Date())
      .orderBy("start", "desc");

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
        "start",
        ">=",
        admin.firestore.Timestamp.fromDate(startDate)
      )
      .where(
        "start",
        "<=",
        admin.firestore.Timestamp.fromDate(endDate)
      )
      .orderBy("start")
      .get();

    if (snapshot.empty) {
      return [];
    }

    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  // /**
  //  * Retrieves all appointments associated with a hospital.
  //  * This is done by:
  //  *  1. Querying the "doctors" collection for all doctors whose "hospital" field
  //  *     matches the given hospitalId.
  //  *  2. Extracting the doctor IDs.
  //  *  3. Querying the "appointments" collection for all appointments where the "doctor"
  //  *     field is in that list.
  //  *
  //  * @param {string} hospitalId - The ID of the hospital.
  //  * @returns {Promise<Array>} Array of appointment objects.
  //  */
  // static async getAppointmentsByHospital(hospitalId) {
  //   if (!hospitalId) {
  //     throw new Error("appointmentService-getAppointmentsByHospital: Missing hospitalId");
  //   }
    
  //   // Step 1: Query the doctors collection.
  //   const doctorsSnapshot = await db.collection("doctors")
  //     .where("hospital", "==", hospitalId)
  //     .get();
      
  //   if (doctorsSnapshot.empty) {
  //     // No doctors in this hospital.
  //     return [];
  //   }
    
  //   // Step 2: Extract doctor IDs.
  //   const doctorIds = doctorsSnapshot.docs.map(doc => doc.id);
  //   let appointments = [];
    
  //   // Step 3: Use Firestore 'in' query if possible (max 10 values allowed).
  //   if (doctorIds.length <= 10) {
  //     const appointmentsSnapshot = await db.collection("appointments")
  //       .where("doctor", "in", doctorIds)
  //       .get();
      
  //     appointments = appointmentsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  //   } else {
  //     // If more than 10 doctor IDs, query individually.
  //     for (const doc of doctorsSnapshot.docs) {
  //       const doctorId = doc.id;
  //       const snapshot = await db.collection("appointments")
  //         .where("doctor", "==", doctorId)
  //         .get();
          
  //       const docs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  //       appointments = appointments.concat(docs);
  //     }
  //   }
    
  //   return appointments;
  // }

  /**
   * Helper to fetch all appointments for a list of doctor IDs,
   * applying an optional range filter on the "start" field.
   */
  static async _fetchByDoctorIds(doctorIds, timeFilter = null) {
    let appointments = [];

    // If we can use an "in" query:
    if (doctorIds.length <= 10) {
      let query = db.collection("appointments").where("doctor", "in", doctorIds);
      if (timeFilter) {
        // timeFilter is { op: '>=|<', ts: Timestamp }
        query = query.where("start", timeFilter.op, timeFilter.ts);
      }
      const snap = await query.get();
      appointments = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    } else {
      // >10 doctors: query per-doctor
      for (const doctorId of doctorIds) {
        let query = db.collection("appointments").where("doctor", "==", doctorId);
        if (timeFilter) {
          query = query.where("start", timeFilter.op, timeFilter.ts);
        }
        const snap = await query.get();
        appointments = appointments.concat(
          snap.docs.map(d => ({ id: d.id, ...d.data() }))
        );
      }
    }

    return appointments;
  }

  /**
   * Returns all upcoming (future) appointments for a given hospital.
   * "Future" means appointment.start ≥ now.
   */
  static async getUpcomingAppointmentsByHospital(hospitalId) {
    if (!hospitalId) {
      throw new Error("appointmentService-getUpcomingAppointmentsByHospital: Missing hospitalId");
    }

    try {
      // Use hospital arrays for better performance
      const HospitalService = require("./hospitalService");
      const appointmentIds = await HospitalService.getHospitalEntities(hospitalId, "appointments");
      
      if (appointmentIds.length === 0) {
        return [];
      }

      // Fetch appointments and filter for upcoming ones
      const nowTs = admin.firestore.Timestamp.fromDate(new Date());
      const appointments = [];
      
      for (const appointmentId of appointmentIds) {
        try {
          const appointmentDoc = await db.collection("appointments").doc(appointmentId).get();
          if (appointmentDoc.exists) {
            const appointmentData = appointmentDoc.data();
            if (appointmentData.start >= nowTs) {
              appointments.push({ id: appointmentDoc.id, ...appointmentData });
            }
          }
        } catch (error) {
          console.error(`Error fetching appointment ${appointmentId}:`, error);
          // Continue with other appointments
        }
      }

      return appointments.sort((a, b) => a.start - b.start);
    } catch (error) {
      console.error("Error fetching upcoming appointments by hospital using arrays, falling back to original method:", error);
      // Fallback to original method if hospital arrays fail
      const doctorsSnap = await db.collection("doctors")
        .where("hospital", "==", hospitalId)
        .get();
      if (doctorsSnap.empty) return [];

      const doctorIds = doctorsSnap.docs.map(d => d.id);

      // 2) fetch appointments where start ≥ now
      const nowTs = admin.firestore.Timestamp.fromDate(new Date());
      return this._fetchByDoctorIds(doctorIds, { op: ">=", ts: nowTs });
    }
  }

  /**
   * Returns all past appointments for a given hospital.
   * "Past" means appointment.start < now.
   */
  static async getPastAppointmentsByHospital(hospitalId) {
    if (!hospitalId) {
      throw new Error("appointmentService-getPastAppointmentsByHospital: Missing hospitalId");
    }

    try {
      // Use hospital arrays for better performance
      const HospitalService = require("./hospitalService");
      const appointmentIds = await HospitalService.getHospitalEntities(hospitalId, "appointments");
      
      if (appointmentIds.length === 0) {
        return [];
      }

      // Fetch appointments and filter for past ones
      const nowTs = admin.firestore.Timestamp.fromDate(new Date());
      const appointments = [];
      
      for (const appointmentId of appointmentIds) {
        try {
          const appointmentDoc = await db.collection("appointments").doc(appointmentId).get();
          if (appointmentDoc.exists) {
            const appointmentData = appointmentDoc.data();
            if (appointmentData.start < nowTs) {
              appointments.push({ id: appointmentDoc.id, ...appointmentData });
            }
          }
        } catch (error) {
          console.error(`Error fetching appointment ${appointmentId}:`, error);
          // Continue with other appointments
        }
      }

      return appointments.sort((a, b) => b.start - a.start); // Sort in descending order for past appointments
    } catch (error) {
      console.error("Error fetching past appointments by hospital using arrays, falling back to original method:", error);
      // Fallback to original method if hospital arrays fail
      const doctorsSnap = await db.collection("doctors")
        .where("hospital", "==", hospitalId)
        .get();
      if (doctorsSnap.empty) return [];

      const doctorIds = doctorsSnap.docs.map(d => d.id);

      // 2) fetch appointments where start < now
      const nowTs = admin.firestore.Timestamp.fromDate(new Date());
      return this._fetchByDoctorIds(doctorIds, { op: "<", ts: nowTs });
    }
  }

  /**
   * Returns all appointments for a given hospital with optional patient and doctor filters.
   * Can filter by patient ID, doctor ID, or both.
   * Can filter for upcoming or past appointments based on timeDirection.
   * 
   * @param {string} hospitalId - The hospital ID
   * @param {string|null} patientId - Optional patient ID filter  
   * @param {string|null} doctorId - Optional doctor ID filter
   * @param {string} timeDirection - "upcoming" for future appointments, "past" for historical appointments
   * @returns {Promise<Array>} Array of filtered appointment objects
   */
  static async getFilteredHospitalAppointments(hospitalId, patientId = null, doctorId = null, timeDirection = "upcoming") {
    if (!hospitalId) {
      throw new Error("appointmentService-getFilteredHospitalAppointments: Missing hospitalId");
    }

    try {
      // Use hospital arrays for better performance
      const HospitalService = require("./hospitalService");
      const appointmentIds = await HospitalService.getHospitalEntities(hospitalId, "appointments");
      
      if (appointmentIds.length === 0) {
        return [];
      }

      // Fetch and filter appointments
      const nowTs = admin.firestore.Timestamp.fromDate(new Date());
      const appointments = [];
      
      for (const appointmentId of appointmentIds) {
        try {
          const appointmentDoc = await db.collection("appointments").doc(appointmentId).get();
          if (appointmentDoc.exists) {
            const appointmentData = appointmentDoc.data();
            
            // Apply time filter
            const isUpcoming = appointmentData.start >= nowTs;
            if ((timeDirection === "upcoming" && !isUpcoming) || (timeDirection === "past" && isUpcoming)) {
              continue;
            }
            
            // Apply doctor filter
            if (doctorId && appointmentData.doctor !== doctorId) {
              continue;
            }
            
            // Apply patient filter
            if (patientId && appointmentData.patient !== patientId) {
              continue;
            }
            
            appointments.push({ id: appointmentDoc.id, ...appointmentData });
          }
        } catch (error) {
          console.error(`Error fetching appointment ${appointmentId}:`, error);
          // Continue with other appointments
        }
      }

      // Sort appointments
      return timeDirection === "upcoming" 
        ? appointments.sort((a, b) => a.start - b.start)
        : appointments.sort((a, b) => b.start - a.start);
        
    } catch (error) {
      console.error("Error fetching filtered appointments by hospital using arrays, falling back to original method:", error);
      // Fallback to original method if hospital arrays fail
      const doctorsSnap = await db.collection("doctors")
        .where("hospital", "==", hospitalId)
        .get();
      if (doctorsSnap.empty) return [];

      let doctorIds = doctorsSnap.docs.map(d => d.id);

      // 2) If doctorId filter is provided, filter the doctor list
      if (doctorId) {
        if (!doctorIds.includes(doctorId)) {
          // The specified doctor is not in this hospital
          return [];
        }
        doctorIds = [doctorId]; // Only search for this specific doctor
      }

      // 3) Determine time filter
      const nowTs = admin.firestore.Timestamp.fromDate(new Date());
      const timeFilter = timeDirection === "upcoming" 
        ? { op: ">=", ts: nowTs }
        : { op: "<", ts: nowTs };

      // 4) Get appointments for these doctors
      let appointments = await this._fetchByDoctorIds(doctorIds, timeFilter);

      // 5) If patientId filter is provided, filter by patient
      if (patientId) {
        appointments = appointments.filter(appointment => appointment.patient === patientId);
      }

      return appointments;
    }
  }

  /**
   * OPTIMIZED: Returns appointments for a hospital by directly querying the hospital field.
   * Much more efficient than the indirect doctor-based approach.
   * 
   * @param {string} hospitalId - The hospital ID
   * @param {string|null} patientId - Optional patient ID filter  
   * @param {string|null} doctorId - Optional doctor ID filter
   * @param {string} timeDirection - "upcoming" for future appointments, "past" for historical appointments
   * @returns {Promise<Array>} Array of filtered appointment objects
   */
  static async getDirectHospitalAppointments(hospitalId, patientId = null, doctorId = null, timeDirection = "upcoming") {
    if (!hospitalId) {
      throw new Error("appointmentService-getDirectHospitalAppointments: Missing hospitalId");
    }

    // Build query to fetch appointments directly by hospital field
    let query = db.collection("appointments").where("hospital", "==", hospitalId);

    // Add time filter
    const nowTs = admin.firestore.Timestamp.fromDate(new Date());
    if (timeDirection === "upcoming") {
      query = query.where("start", ">=", nowTs);
    } else {
      query = query.where("start", "<", nowTs);
    }

    // Add optional doctor filter
    if (doctorId) {
      query = query.where("doctor", "==", doctorId);
    }

    // Execute query
    const snapshot = await query.get();
    let appointments = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    // Apply patient filter in memory (since Firestore compound queries have limitations)
    if (patientId) {
      appointments = appointments.filter(appointment => appointment.patient === patientId);
    }

    return appointments;
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
    hospital, // New required attribute (hospital ID)
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
    // Ensure that doctor, patient, and hospital exist.
    if (
      !(await this.checkEntityExists("doctor", doctor)) ||
      !(await this.checkEntityExists("patient", patient))
    ) {
      throw new Error(
        "appointmentService-createAppointment: Doctor or Patient not found"
      );
    }

    // Validate hospital exists
    if (!hospital) {
      const error = new Error("appointmentService-createAppointment: Hospital ID is required");
      error.status = 400;
      throw error;
    }
    const hospitalDoc = await db.collection("hospitals").doc(hospital).get();
    if (!hospitalDoc.exists) {
      const error = new Error("appointmentService-createAppointment: Hospital not found");
      error.status = 400;
      throw error;
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

    // Check for overlapping appointments for the patient.
    const overlappingPatientSnapshot = await db
      .collection("appointments")
      .where("patient", "==", patient)
      .where("start", ">=", admin.firestore.Timestamp.fromDate(dayStart))
      .where("start", "<=", admin.firestore.Timestamp.fromDate(dayEnd))
      .where("status", "==", "scheduled")
      .get();
    const overlappingPatientAppointments = overlappingPatientSnapshot.docs
      .map(doc => doc.data())
      .filter(app => {
        const existingStart = timeToMinutes(formatTime(app.start.toDate()));
        const existingEnd = timeToMinutes(formatTime(app.end.toDate()));
        const newStart = timeToMinutes(startTimeStr);
        const newEnd = timeToMinutes(endTimeStr);
        return newStart < existingEnd && existingStart < newEnd;
      });
    if (overlappingPatientAppointments.length > 0) {
      throw new Error("appointmentService-createAppointment: There is an existing overlapping appointment for this patient on the specified date");
    }

    const appointmentData = {
      patient,
      doctor,
      hospital, // Hospital ID (Firestore document reference)
      // appointmentDate: admin.firestore.Timestamp.fromDate(
      //   new Date(appointmentDate)
      // ),
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

    // Add appointment ID to hospital's appointments array
    try {
      const HospitalService = require("./hospitalService");
      await HospitalService.addEntityToHospital(hospital, newAppointmentRef.id, "appointments");
    } catch (error) {
      console.error(`Error adding appointment ${newAppointmentRef.id} to hospital ${hospital}:`, error);
      // Don't throw error here as the appointment was already created successfully
    }

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

    // Get appointment data to access hospital ID
    const appointmentData = appointmentDoc.data();
    const hospitalId = appointmentData.hospital;

    await appointmentRef.delete();

    // Remove appointment ID from hospital's appointments array
    if (hospitalId) {
      try {
        const HospitalService = require("./hospitalService");
        await HospitalService.removeEntityFromHospital(hospitalId, appointment_id, "appointments");
      } catch (error) {
        console.error(`Error removing appointment ${appointment_id} from hospital ${hospitalId}:`, error);
        // Don't throw error here as the appointment was already deleted successfully
      }
    }

    return;
  }

  /**
   * Updates an appointment in Firestore.
   */
  static async updateAppointment(appointmentId, updateFields, user) {

    const appointmentRef = db.collection("appointments").doc(appointmentId);
    const appointmentDoc = await appointmentRef.get();

    if (!appointmentDoc.exists) {
      throw new Error(
        "appointmentService-updateAppointment: Appointment not found"
      );
    }
    const currentAppointment = appointmentDoc.data();
    // ░░░ Allowed fields and extra field check ░░░
    // Note: hospital is NOT included - it's not editable after creation
    const ALLOWED_FIELDS = ["patient", "doctor", "start", "end", "purpose", "status", "suspended"];
    Object.keys(updateFields).forEach((key) => {
      if (updateFields[key] === undefined) {
        delete updateFields[key];
      } else if (!ALLOWED_FIELDS.includes(key)) {
        throw new Error(`Field '${key}' is not allowed`);
      }
    });
    
    // if (!appointmentId) {
    //   throw new Error(
    //     "appointmentService-updateAppointment: Invalid appointmentId"
    //   );
    // }

    if (updateFields.id !== undefined) {
      throw new Error(
        "appointmentService-updateAppointment: Changing 'id' is not allowed"
      );
    }

    // if (updateFields.suspended && user.role !== "superadmin") {
    //   throw new Error(
    //     "appointmentService-updateAppointment: Only superadmins can suspend appointments"
    //   );
    // }
    if (updateFields.suspended !== undefined) {
      if (typeof updateFields.suspended !== "boolean") {
        throw new Error("Invalid suspended: must be a boolean");
      }
      if (updateFields.suspended && user.role !== "superadmin") {
        throw new Error("Only superadmins can suspend appointments");
      }
    }

    if (updateFields.purpose !== undefined) {
      if (typeof updateFields.purpose !== "string") {
        throw new Error("Invalid purpose: must be a string");
      }
    }

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
    if (updateFields.start || updateFields.end || updateFields.doctor || updateFields.patient) {
      const newStart = updateFields.start ? new Date(updateFields.start) : currentAppointment.start.toDate();
      const newEnd = updateFields.end ? new Date(updateFields.end) : currentAppointment.end.toDate();
      if (isNaN(newStart) || isNaN(newEnd)) {
        const error = new Error("appointmentService-updateAppointment: Invalid start or end date");
        error.status = 400;
        throw error;
      }
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
      // Determine new patient value: use updated patient if provided, otherwise the current one.
      const newPatient = updateFields.patient ? updateFields.patient : currentAppointment.patient;

      // Validate that the new patient exists
      const patientDoc = await db.collection("patients").doc(newPatient).get();
      if (!patientDoc.exists) {
        const error = new Error("appointmentService-updateAppointment: Patient not found");
        error.status = 400;
        throw error;
      }

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

      // Check for overlapping appointments for the doctor (excluding this appointment).
      const overlappingDoctorSnapshot = await db
        .collection("appointments")
        .where("doctor", "==", newDoctor)
        .where("start", ">=", admin.firestore.Timestamp.fromDate(dayStart))
        .where("start", "<=", admin.firestore.Timestamp.fromDate(dayEnd))
        .where("status", "==", "scheduled")
        .get();
      const overlappingDoctorAppointments = overlappingDoctorSnapshot.docs
        .filter(doc => doc.id !== appointmentId)
        .map(doc => doc.data())
        .filter(app => {
          const existingStart = timeToMinutes(formatTime(app.start.toDate()));
          const existingEnd = timeToMinutes(formatTime(app.end.toDate()));
          const newStartMinutes = timeToMinutes(derivedStartTime);
          const newEndMinutes = timeToMinutes(derivedEndTime);
          return newStartMinutes < existingEnd && existingStart < newEndMinutes;
        });
      if (overlappingDoctorAppointments.length > 0) {
        const error = new Error("appointmentService-updateAppointment: There is an existing overlapping appointment for this doctor on the specified date");
        error.status = 400;
        throw error;
      }

      // Check for overlapping appointments for the patient.
      const overlappingPatientSnapshot = await db
        .collection("appointments")
        .where("patient", "==", newPatient)
        .where("start", ">=", admin.firestore.Timestamp.fromDate(dayStart))
        .where("start", "<=", admin.firestore.Timestamp.fromDate(dayEnd))
        .where("status", "==", "scheduled")
        .get();
      const overlappingPatientAppointments = overlappingPatientSnapshot.docs
        .filter(doc => doc.id !== appointmentId)
        .map(doc => doc.data())
        .filter(app => {
          const existingStart = timeToMinutes(formatTime(app.start.toDate()));
          const existingEnd = timeToMinutes(formatTime(app.end.toDate()));
          const newStartMinutes = timeToMinutes(derivedStartTime);
          const newEndMinutes = timeToMinutes(derivedEndTime);
          return newStartMinutes < existingEnd && existingStart < newEndMinutes;
        });
      if (overlappingPatientAppointments.length > 0) {
        const error = new Error("appointmentService-updateAppointment: There is an existing overlapping appointment for this patient on the specified date");
        error.status = 400;
        throw error;
      }

      // Update the fields with the validated and derived values.
      updateFields.start = admin.firestore.Timestamp.fromDate(newStart);
      updateFields.end = admin.firestore.Timestamp.fromDate(newEnd);
      updateFields.doctor = newDoctor;
      updateFields.patient = newPatient;
      // Optionally update these derived fields if you wish to store them:
      // updateFields.day = derivedDay;
      // updateFields.startTime = derivedStartTime;
      // updateFields.endTime = derivedEndTime;
    }

    // if (updateFields.patient) {
    //   if (!(await this.checkEntityExists("patient", updateFields.patient))) {
    //     throw new Error(
    //       "appointmentService-updateAppointment: Patient not found"
    //     );
    //   }
    // }

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
        "pending",
        "declined",
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

    // const updatedAppointmentDoc = await appointmentRef.get();
    // const updatedAppointment = {
    //   id: updatedAppointmentDoc.id,
    //   ...updatedAppointmentDoc.data(),
    // };
    return "Appointment updated successfully";
  }
}

module.exports = AppointmentService;
