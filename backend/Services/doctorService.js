const admin = require("firebase-admin");
const db = admin.firestore();
const bcrypt = require("bcrypt");

class DoctorService {
  /**
   * Get public doctor data (excluding sensitive fields)
   */
  static async getPublicData(doctorId) {
    const doctorDoc = await db.collection("doctors").doc(doctorId).get();
    if (!doctorDoc.exists) throw new Error("Doctor not found");

    const doctorData = doctorDoc.data();
    delete doctorData.password; // Remove sensitive data
    delete doctorData.pers_id;
    delete doctorData.role;
    delete doctorData.createdAt;
    delete doctorData.updatedAt;

    return { id: doctorDoc.id, ...doctorData };
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
    if (updateFields.mobile_number)
      await this.checkUniqueness(
        "mobile_number",
        updateFields.mobile_number,
        doctorId
      );
    if (updateFields.pers_id)
      await this.checkUniqueness("pers_id", updateFields.pers_id, doctorId);

    if (updateFields.password) {
      const salt = await bcrypt.genSalt(10);
      updateFields.password = await bcrypt.hash(updateFields.password, salt);
    }

    if (updateFields.suspended && user.role !== "superadmin") {
      throw new Error("Only superadmins can suspend doctors");
    }

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
