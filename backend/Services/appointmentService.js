const admin = require("firebase-admin");
const db = admin.firestore();

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
      .where("appointmentDate", ">=", admin.firestore.Timestamp.fromDate(startDate))
      .where("appointmentDate", "<=", admin.firestore.Timestamp.fromDate(endDate))
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
    appointmentDate,
    purpose,
    status = "scheduled",
    suspended = false,
  }) {
    if (
      !(await this.checkEntityExists("doctor", doctor)) ||
      !(await this.checkEntityExists("patient", patient))
    ) {
      throw new Error(
        "appointmentService-createAppointment: Doctor or Patient not found"
      );
    }

    const appointmentData = {
      patient,
      doctor,
      appointmentDate: admin.firestore.Timestamp.fromDate(
        new Date(appointmentDate)
      ),
      purpose,
      status,
      suspended,
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

    if (updateFields.patient) {
      if (!(await this.checkEntityExists("patient", updateFields.patient))) {
        throw new Error(
          "appointmentService-updateAppointment: Patient not found"
        );
      }
    }

    if (updateFields.doctor) {
      if (!(await this.checkEntityExists("doctor", updateFields.doctor))) {
        throw new Error(
          "appointmentService-updateAppointment: Doctor not found"
        );
      }
    }

    // If appointmentDate is present, convert it to a Firestore Timestamp.
    if (updateFields.appointmentDate) {
      updateFields.appointmentDate = admin.firestore.Timestamp.fromDate(
        new Date(updateFields.appointmentDate)
      );
    }

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
