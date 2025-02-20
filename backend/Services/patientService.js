const admin = require("firebase-admin");
const db = admin.firestore();
const bcrypt = require("bcrypt");

class PatientService {
  /**
   * Fetch a patient’s full data from Firestore.
   * @param {string} patientId - The Firestore ID of the patient.
   */
  static async getPatientData(patientId) {
    const patientDoc = await db.collection("patients").doc(patientId).get();
    if (!patientDoc.exists) throw new Error("Patient not found");

    return { id: patientDoc.id, ...patientDoc.data() };
  }

  /**
   * Get a patient's diagnosis field.
   * @param {string} patientId - The Firestore ID of the patient.
   */
  static async getPatientDiagnosis(patientId) {
    const patient = await this.getPatientData(patientId);
    return { diagnosis: patient.diagnosis || "Not Diagnosed" };
  }

  /**
   * Fetch all patients from Firestore.
   */
  static async findAllPatients() {
    const snapshot = await db.collection("patients").get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Fetch all patients belonging to a specific hospital.
   * @param {string} hospitalId - The Firestore ID of the hospital.
   */
  static async findAllPatientsByHospital(hospitalId) {
    const snapshot = await db
      .collection("patients")
      .where("hospital", "==", hospitalId)
      .get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Ensures uniqueness across collections (patients, doctors, admins, superadmins).
   * @param {string} field - The field to check (e.g., email, pers_id, mobile_number).
   * @param {string} value - The value to check for uniqueness.
   * @param {string} excludeId - (Optional) The ID to exclude (for updates).
   */
  static async checkUniqueness(field, value, excludeId = null) {
    const collections = ["patients", "doctors", "admins", "superadmins"];
    for (const collection of collections) {
      const snapshot = await db
        .collection(collection)
        .where(field, "==", value)
        .get();
      for (const doc of snapshot.docs) {
        if (doc.id !== excludeId) {
          throw new Error(`The ${field} '${value}' is already in use`);
        }
      }
    }
  }

  /**
   * Update a patient's data securely.
   * @param {string} patientId - The Firestore ID of the patient.
   * @param {Object} updateFields - The fields to update.
   * @param {Object} user - The authenticated user making the request.
   */
  static async updatePatient(patientId, updateFields, user) {
    const patientRef = db.collection("patients").doc(patientId);
    const patientDoc = await patientRef.get();

    if (!patientDoc.exists) throw new Error("Patient not found");

    if (updateFields.id) delete updateFields.id;
    if (updateFields.role) throw new Error("Cannot change role");

    if (updateFields.email)
      await this.checkUniqueness("email", updateFields.email, patientId);
    if (updateFields.mobile_number)
      await this.checkUniqueness(
        "mobile_number",
        updateFields.mobile_number,
        patientId
      );
    if (updateFields.pers_id)
      await this.checkUniqueness("pers_id", updateFields.pers_id, patientId);

    if (updateFields.password) {
      const salt = await bcrypt.genSalt(10);
      updateFields.password = await bcrypt.hash(updateFields.password, salt);
    }

    if (updateFields.suspended && user.role !== "superadmin") {
      throw new Error("Only superadmins can suspend patients");
    }

    await patientRef.update(updateFields);
    return { message: "Patient updated successfully" };
  }

  /**
   * Delete a patient from Firestore.
   * @param {string} patientId - The Firestore ID of the patient.
   */
  static async deletePatient(patientId) {
    const patientRef = db.collection("patients").doc(patientId);
    const patientDoc = await patientRef.get();

    if (!patientDoc.exists) throw new Error("Patient not found");

    // Start Firestore batch operation
    const batch = db.batch();

    // 🔹 Delete all appointments and tests where "patient" field matches patientId
    const deleteAppointmentsAndTests = async (collection) => {
      const snapshot = await db
        .collection(collection)
        .where("patient", "==", patientId)
        .get();
      snapshot.forEach((doc) => batch.delete(doc.ref));
    };

    await deleteAppointmentsAndTests("appointments");
    await deleteAppointmentsAndTests("tests");

    // 🔹 Delete the patient itself
    batch.delete(patientRef);

    // Commit batch
    await batch.commit();

    return {
      message:
        "Patient and all related appointments/tests successfully deleted.",
    };
  }
}

module.exports = PatientService;
