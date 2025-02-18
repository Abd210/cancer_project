const admin = require("firebase-admin");
const db = admin.firestore();

class HospitalService {
  /**
   * Registers a new hospital while ensuring uniqueness of name, emails, and mobile numbers.
   */
  static async register({
    hospital_name,
    hospital_address,
    mobile_numbers,
    emails,
    suspended,
  }) {
    const hospitalRef = db.collection("hospitals");

    // Check if a hospital with the same name and address already exists
    const existingHospitals = await hospitalRef
      .where("hospital_name", "==", hospital_name)
      .where("hospital_address", "==", hospital_address)
      .get();

    if (!existingHospitals.empty) {
      throw new Error(
        "Hospital already exists with the same name and address."
      );
    }

    // Check uniqueness of emails and mobile numbers
    await this._checkUniqueFields("emails", emails);
    await this._checkUniqueFields("mobile_numbers", mobile_numbers);

    // Add new hospital
    const newHospital = {
      hospital_name,
      hospital_address,
      mobile_numbers,
      emails,
      createdAt: admin.firestore.Timestamp.now(),
      suspended: suspended || false,
    };

    const docRef = await hospitalRef.add(newHospital);
    return { id: docRef.id, ...newHospital };
  }

  /**
   * Retrieves hospital data by ID.
   */
  static async getHospitalData(hospitalId) {
    const hospitalRef = db.collection("hospitals").doc(hospitalId);
    const hospitalDoc = await hospitalRef.get();

    if (!hospitalDoc.exists) {
      throw new Error("Hospital not found.");
    }

    return { id: hospitalDoc.id, ...hospitalDoc.data() };
  }

  /**
   * Updates hospital details, ensuring uniqueness for emails and mobile numbers.
   */
  static async updateHospital(hospitalId, updateFields, userRole) {
    if (userRole !== "superadmin") {
      throw new Error("Unauthorized: Only superadmins can update hospitals.");
    }

    const hospitalRef = db.collection("hospitals").doc(hospitalId);
    const hospitalDoc = await hospitalRef.get();

    if (!hospitalDoc.exists) {
      throw new Error("Hospital not found.");
    }

    // Prevent updating `_id`
    if (updateFields._id) {
      throw new Error("Changing '_id' is not allowed.");
    }

    // Check uniqueness of emails and mobile numbers if updated
    if (updateFields.emails)
      await this._checkUniqueFields("emails", updateFields.emails, hospitalId);
    if (updateFields.mobile_numbers)
      await this._checkUniqueFields(
        "mobile_numbers",
        updateFields.mobile_numbers,
        hospitalId
      );

    await hospitalRef.update(updateFields);
    return { message: "Hospital updated successfully." };
  }

  /**
   * Deletes a hospital and all associated data (patients, doctors, admins, appointments, tests).
   */
  static async deleteHospital(hospitalId, userRole) {
    if (userRole !== "superadmin") {
      throw new Error("Unauthorized: Only superadmins can delete hospitals.");
    }

    const hospitalRef = db.collection("hospitals").doc(hospitalId);
    const hospitalDoc = await hospitalRef.get();

    if (!hospitalDoc.exists) {
      throw new Error("Hospital not found.");
    }

    // Start Firestore transaction
    const batch = db.batch();

    // Delete patients, doctors, and admins linked to this hospital
    const deleteLinkedRecords = async (collection) => {
      const snapshot = await db
        .collection(collection)
        .where("hospital", "==", hospitalId)
        .get();
      snapshot.forEach((doc) => batch.delete(doc.ref));
    };

    await deleteLinkedRecords("patients");
    await deleteLinkedRecords("doctors");
    await deleteLinkedRecords("admins");

    // Delete appointments and tests associated with patients & doctors
    const deleteAppointmentsAndTests = async (collection) => {
      const snapshot = await db
        .collection(collection)
        .where("hospital", "==", hospitalId)
        .get();
      snapshot.forEach((doc) => batch.delete(doc.ref));
    };

    await deleteAppointmentsAndTests("appointments");
    await deleteAppointmentsAndTests("tests");

    // Delete hospital itself
    batch.delete(hospitalRef);
    await batch.commit();

    return {
      message: "Hospital and all associated records successfully deleted.",
    };
  }

  /**
   * Retrieves all hospitals.
   */
  static async findAllHospitals() {
    const snapshot = await db.collection("hospitals").get();
    if (snapshot.empty) {
      throw new Error("No hospitals found.");
    }

    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Internal function to check uniqueness of emails and mobile numbers across collections.
   */
  static async _checkUniqueFields(field, values, hospitalId = null) {
    const collections = ["patients", "doctors", "admins", "hospitals"];

    for (const collection of collections) {
      const querySnapshot = await db
        .collection(collection)
        .where(field, "array-contains-any", values)
        .get();

      querySnapshot.forEach((doc) => {
        if (hospitalId && doc.id === hospitalId) return; // Skip the current hospital
        throw new Error(`One of the ${field} is already in use.`);
      });
    }
  }
}

module.exports = HospitalService;
