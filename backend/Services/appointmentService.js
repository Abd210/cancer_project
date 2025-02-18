const admin = require("firebase-admin");
const db = admin.firestore();

class AppointmentService {

  /**
   * Get all upcoming appointments.
   * Upcoming appointments are those with:
   * - appointment_date greater than or equal to now, and
   * - status equal to "scheduled".
   * Results are ordered by appointment_date in ascending order.
   *
   * @returns {Promise<Array>} List of upcoming appointment objects.
   */
  static async getAllUpcomingAppointments() {
    try {
      const snapshot = await db
        .collection("appointments")
        .where("appointment_date", ">=", new Date())
        .where("status", "==", "scheduled")
        .orderBy("appointment_date")
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
  static async getUpcomingAppointmentsForSpecificPatientOrDoctor({ entity_role, entity_id }) {
    if (!entity_id) {
      throw new Error(
        "appointmentService-getUpcomingAppointments: Invalid entity_id"
      );
    }

    const field = entity_role === "doctor" ? "doctor_id" : "patient_id";

    // let queryRef = db.collection("appointments");
    // queryRef = queryRef.where(field, "==", entity_id);
    // queryRef = queryRef.where("appointment_date", ">=", new Date());
    // queryRef = queryRef.where("status", "==", "scheduled");
    // queryRef = queryRef.orderBy("appointment_date");
    // const snapshot = await queryRef.get();

    const snapshot = await db
      .collection("appointments")
      .where(field, "==", entity_id)
      .where("appointment_date", ">=", new Date())
      .where("status", "==", "scheduled")
      .orderBy("appointment_date")
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
      queryRef = queryRef.where("doctor_id", "==", user_id);
    } else if (role === "patient") {
      queryRef = queryRef.where("patient_id", "==", user_id);
    } else if (role === "superadmin" && filterById && filterByRole) {
      if (filterByRole === "patient") {
        queryRef = queryRef.where("patient_id", "==", filterById);
      }
      else {
        queryRef = queryRef.where("doctor_id", "==", filterById);
      }
      // queryRef = queryRef.where(filterByRole, "==", filterById);
    }

    queryRef = queryRef
      .where("appointment_date", "<", new Date())
      .orderBy("appointment_date", "desc");

    const snapshot = await queryRef.get();

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
   * Creates a new appointment.
   */
  static async createAppointment({
    patient_id,
    doctor_id,
    appointment_date,
    purpose,
    status = "scheduled",
    suspended = false,
  }) {
    const appointmentData = {
      patient_id,
      doctor_id,
      appointment_date: admin.firestore.Timestamp.fromDate(
        new Date(appointment_date)
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

    return { message: "Appointment successfully deleted", appointment_id };
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

    // If appointment_date is present, convert it to a Firestore Timestamp.
    if (updateFields.appointment_date) {
      updateFields.appointment_date = admin.firestore.Timestamp.fromDate(
        new Date(updateFields.appointment_date)
      );
    }

    const appointmentRef = db.collection("appointments").doc(appointmentId);
    const appointmentDoc = await appointmentRef.get();

    if (!appointmentDoc.exists) {
      throw new Error(
        "appointmentService-updateAppointment: Appointment not found"
      );
    }

    await appointmentRef.update(updateFields);

    return {
      message: "Appointment updated successfully",
      id: appointmentId,
      ...updateFields,
    };
  }
}

module.exports = AppointmentService;
