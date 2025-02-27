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

  static async findPatient(patientId, email, mobileNumber) {
    if (!patientId && !email && !mobileNumber) {
      throw new Error("patientService-findPatient: Invalid input parameters");
    }

    let patientDoc;

    if (patientId) {
      patientDoc = await db.collection("patients").doc(patientId).get();
      if (!patientDoc.exists) {
        throw new Error("patientService-findPatient: Invalid Patient Id");
      }
      return patientDoc.data();
    } else {
      let querySnapshot;

      if (email) {
        querySnapshot = await db
          .collection("patients")
          .where("email", "==", email)
          .get();
      } else if (mobileNumber) {
        querySnapshot = await db
          .collection("patients")
          .where("mobileNumber", "==", mobileNumber)
          .get();
      }

      if (querySnapshot.empty) {
        throw new Error(
          "patientService-findPatient: Invalid Email or Mobile Number"
        );
      }

      return querySnapshot.docs[0].data();
    }
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
   * @param {string} field - The field to check (e.g., email, persId, mobileNumber).
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

    const currentPatientData = patientDoc.data(); // Get current patient data

    if (updateFields.id) delete updateFields.id;
    if (updateFields.role) throw new Error("Cannot change role");

    if (updateFields.email)
      await this.checkUniqueness("email", updateFields.email, patientId);
    if (updateFields.mobileNumber)
      await this.checkUniqueness(
        "mobileNumber",
        updateFields.mobileNumber,
        patientId
      );
    if (updateFields.persId)
      await this.checkUniqueness("persId", updateFields.persId, patientId);

    if (updateFields.password) {
      const salt = await bcrypt.genSalt(10);
      updateFields.password = await bcrypt.hash(updateFields.password, salt);
    }

    if (updateFields.suspended && user.role !== "superadmin") {
      throw new Error("Only superadmins can suspend patients");
    }

    if (
      updateFields.doctor &&
      updateFields.doctor !== currentPatientData.doctor
    ) {
      const previousDoctorId = currentPatientData.doctor;
      const newDoctorId = updateFields.doctor;

      await db.runTransaction(async (transaction) => {
        // Read all necessary data first
        let prevDoctorRef, newDoctorRef;
        if (previousDoctorId)
          prevDoctorRef = db.collection("doctors").doc(previousDoctorId);
        if (newDoctorId)
          newDoctorRef = db.collection("doctors").doc(newDoctorId);

        if (previousDoctorId) {
          transaction.update(prevDoctorRef, {
            patients: admin.firestore.FieldValue.arrayRemove(patientId),
          });
        }

        if (newDoctorId) {
          transaction.update(newDoctorRef, {
            patients: admin.firestore.FieldValue.arrayUnion(patientId),
          });
        }

        // Update the patient's document
        transaction.update(patientRef, updateFields);
      });
    } else {
      // If the doctor field is NOT being updated, update the patient normally
      await patientRef.update(updateFields);
    }
    const updatedPatient = await patientRef.get();
    return { id: updatedPatient.id, ...updatedPatient.data() };
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

    return;
  }
}

module.exports = PatientService;
