const admin = require("firebase-admin");
const db = admin.firestore();
const bcrypt = require("bcrypt");
const PatientService = require("./patientService");

class DoctorService {
  /**
   * Get public doctor data (excluding sensitive fields)
   */
  static async getPublicData(doctorId) {
    const doctorDoc = await db.collection("doctors").doc(doctorId).get();
    if (!doctorDoc.exists) throw new Error("Doctor not found");

    const doctorData = doctorDoc.data();
    delete doctorData.password; // Remove sensitive data
    delete doctorData.persId;
    delete doctorData.role;
    delete doctorData.createdAt;
    delete doctorData.updatedAt;

    return { id: doctorDoc.id, ...doctorData };
  }

  static async findDoctor(doctorId, email, mobileNumber) {
    if (!doctorId && !email && !mobileNumber) {
      throw new Error("doctorService-findDoctor: Invalid input parameters");
    }

    let doctorDoc;

    if (doctorId) {
      doctorDoc = await db.collection("doctors").doc(doctorId).get();
      if (!doctorDoc.exists) {
        throw new Error("doctorService-findDoctor: Invalid Doctor Id");
      }
      return doctorDoc.data();
    } else {
      let querySnapshot;

      if (email) {
        querySnapshot = await db
          .collection("doctors")
          .where("email", "==", email)
          .get();
      } else if (mobileNumber) {
        querySnapshot = await db
          .collection("doctors")
          .where("mobileNumber", "==", mobileNumber)
          .get();
      }

      if (querySnapshot.empty) {
        throw new Error(
          "doctorService-findDoctor: Invalid Email or Mobile Number"
        );
      }

      return querySnapshot.docs[0].data();
    }
  }

  /**
   * Get full doctor data
   */
  static async getDoctorData(doctorId) {
    const doctorDoc = await db.collection("doctors").doc(doctorId).get();
    if (!doctorDoc.exists) throw new Error("Doctor not found");
    return { id: doctorDoc.id, ...doctorDoc.data() };
  }

  /**
   * Fetch all doctors
   */
  static async findAllDoctors() {
    const snapshot = await db.collection("doctors").get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Fetch doctors by hospital ID
   */
  static async findAllDoctorsByHospital(hospitalId) {
    const snapshot = await db
      .collection("doctors")
      .where("hospital", "==", hospitalId)
      .get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Ensure uniqueness across collections
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
   * Update doctor data
   */
  static async updateDoctor(doctorId, updateFields, user) {
    const doctorRef = db.collection("doctors").doc(doctorId);
    const doctorDoc = await doctorRef.get();

    if (!doctorDoc.exists) throw new Error("Doctor not found");

    if (updateFields.id) delete updateFields.id;
    if (updateFields.role) throw new Error("Cannot change role");

    if (updateFields.email)
      await this.checkUniqueness("email", updateFields.email, doctorId);
    if (updateFields.mobileNumber)
      await this.checkUniqueness(
        "mobileNumber",
        updateFields.mobileNumber,
        doctorId
      );
    if (updateFields.persId)
      await this.checkUniqueness("persId", updateFields.persId, doctorId);

    if (updateFields.password) {
      const salt = await bcrypt.genSalt(10);
      updateFields.password = await bcrypt.hash(updateFields.password, salt);
    }

    if (updateFields.suspended && user.role !== "superadmin") {
      throw new Error("Only superadmins can suspend doctors");
    }

    const currentDoctorData = doctorDoc.data(); // Get current doctor data

    let oldPatients = currentDoctorData.patients || [];
    let newPatients = updateFields.patients || oldPatients; // If no update to patients array, keep the old list

    if (!Array.isArray(newPatients)) {
      throw new Error("updateDoctor: patients field must be an array");
    }

    // Identify removed and added patients
    const removedPatients = oldPatients.filter(
      (patientId) => !newPatients.includes(patientId)
    );
    const addedPatients = newPatients.filter(
      (patientId) => !oldPatients.includes(patientId)
    );

    // Update removed patients (set their doctor attribute to an empty string or null)
    await Promise.all(
      removedPatients.map(async (patientId) => {
        await PatientService.updatePatient(
          patientId,
          { doctor: null },
          { role: "superadmin" }
        );
      })
    );

    // Update added patients (set their doctor attribute to the new doctor's ID)
    await Promise.all(
      addedPatients.map(async (patientId) => {
        await PatientService.updatePatient(
          patientId,
          { doctor: doctorId },
          { role: "superadmin" }
        );
      })
    );

    await doctorRef.update(updateFields);
    return { message: "Doctor updated successfully" };
  }

  /**
   * Delete a doctor
   */
  static async deleteDoctor(doctorId) {
    const doctorRef = db.collection("doctors").doc(doctorId);
    const doctorDoc = await doctorRef.get();

    if (!doctorDoc.exists) throw new Error("Doctor not found");

    // Start Firestore batch operation
    const batch = db.batch();

    // 🔹 Delete all appointments and tests where "doctor" field matches doctorId
    const deleteAppointmentsAndTests = async (collection) => {
      const snapshot = await db
        .collection(collection)
        .where("doctor", "==", doctorId)
        .get();
      snapshot.forEach((doc) => batch.delete(doc.ref));
    };

    await deleteAppointmentsAndTests("appointments");
    await deleteAppointmentsAndTests("tests");

    // 🔹 Delete the doctor itself
    batch.delete(doctorRef);

    // Commit batch
    await batch.commit();

    return;
  }
}

module.exports = DoctorService;
