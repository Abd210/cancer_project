const admin = require("firebase-admin");
const db = admin.firestore();

class HospitalService {
  /**
   * Registers a new hospital while ensuring uniqueness of name, emails, and mobile numbers.
   * @param {Object} hospitalData - The hospital data.
   * @param {string} hospitalData.name - The name of the hospital.
   * @param {string} hospitalData.address - The address of the hospital.
   * @param {Array<string>} hospitalData.mobileNumbers - The mobile numbers of the hospital.
   * @param {Array<string>} hospitalData.emails - The emails of the hospital.
   * @param {boolean} [hospitalData.suspended] - The suspended status of the hospital.
   * @returns {Promise<Object>} The newly registered hospital data including its ID.
   * @throws {Error} If a hospital with the same name and address already exists or if emails/mobile numbers are not unique.
   */
  static async register({ name, address, mobileNumbers, emails, suspended }) {
    const hospitalRef = db.collection("hospitals");

    // Check if a hospital with the same name and address already exists
    const existingHospitals = await hospitalRef
      .where("name", "==", name)
      .where("address", "==", address)
      .get();

    if (!existingHospitals.empty) {
      throw new Error(
        "Hospital already exists with the same name and address."
      );
    }

    // Check uniqueness of emails and mobile numbers
    await this._checkUniqueFields("emails", emails);
    await this._checkUniqueFields("mobileNumbers", mobileNumbers);

    // Add new hospital
    const newHospital = {
      name,
      address,
      mobileNumbers,
      emails,
      createdAt: admin.firestore.Timestamp.now(),
      suspended: suspended || false,
    };

    const docRef = await hospitalRef.add(newHospital);
    return { id: docRef.id, ...newHospital };
  }

  /**
   * Retrieves hospital data by ID.
   * @param {string} hospitalId - The ID of the hospital.
   * @returns {Promise<Object>} The hospital data including its ID.
   * @throws {Error} If the hospital is not found.
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
   * @param {string} hospitalId - The ID of the hospital to update.
   * @param {Object} updateFields - The fields to update.
   * @param {Array<string>} [updateFields.emails] - The new emails of the hospital.
   * @param {Array<string>} [updateFields.mobileNumbers] - The new mobile numbers of the hospital.
   * @returns {Promise<Object>} A message indicating the hospital was updated successfully.
   * @throws {Error} If the hospital is not found or if emails/mobile numbers are not unique.
   */
  static async updateHospital(hospitalId, updateFields, user) {
    const hospitalRef = db.collection("hospitals").doc(hospitalId);
    const hospitalDoc = await hospitalRef.get();

    if (!hospitalDoc.exists) {
      throw new Error("Hospital not found.");
    }

    // 1. Whitelist allowed fields
    const ALLOWED_FIELDS = ["name","address","mobileNumbers","emails","suspended"];
    Object.keys(updateFields).forEach(key => {
      if (!ALLOWED_FIELDS.includes(key)) {
        throw new Error(`Field '${key}' is not allowed`);
      }
    });

    // Prevent updating `_id`
    // if (updateFields._id) {
    //   throw new Error("Changing '_id' is not allowed.");
    // }

    if (updateFields.name !== undefined) {
      if (typeof updateFields.name !== "string") {
        throw new Error("Invalid name: must be a string");
      }
    }

    if (updateFields.address !== undefined) {
      if (typeof updateFields.address !== "string") {
        throw new Error("Invalid address: must be a string");
      }
    }

    // Check uniqueness of emails and mobile numbers if updated
    // if (updateFields.emails)
    //   await this._checkUniqueFields("emails", updateFields.emails, hospitalId);

    if (updateFields.emails !== undefined) {
      if (
        !Array.isArray(updateFields.emails) ||
        !updateFields.emails.every(email => typeof email === "string")
      ) {
        throw new Error("Invalid emails: must be an array of strings");
      }
      await this._checkUniqueFields("emails", updateFields.emails, hospitalId);
    }
    // if (updateFields.mobileNumbers)
    //   await this._checkUniqueFields(
    //     "mobileNumbers",
    //     updateFields.mobileNumbers,
    //     hospitalId
    //   );
    if (updateFields.mobileNumbers !== undefined) {
      if (
        !Array.isArray(updateFields.mobileNumbers) ||
        !updateFields.mobileNumbers.every(num => typeof num === "string")
      ) {
        throw new Error("Invalid mobileNumbers: must be an array of strings");
      }
      await this._checkUniqueFields("mobileNumbers", updateFields.mobileNumbers, hospitalId);
    }

    if (updateFields.suspended !== undefined) {
      if (typeof updateFields.suspended !== "boolean") {
        throw new Error("Invalid suspended: must be a boolean");
      }
      if (updateFields.suspended && user.role !== "superadmin") {
        throw new Error("Only superadmins can suspend doctors");
      }
    }

    updateFields.updatedAt = admin.firestore.Timestamp.now
    ? admin.firestore.Timestamp.now()
    : new Date();
    await hospitalRef.update(updateFields);
    return "Hospital updated successfully.";
  }

  /**
   * Deletes a hospital and all associated data (patients, doctors, admins, appointments, tests).
   * @param {string} hospitalId - The ID of the hospital to delete.
   * @returns {Promise<Object>} A message indicating the hospital and all associated records were successfully deleted.
   * @throws {Error} If the hospital is not found.
   */
  static async deleteHospital(hospitalId) {
    const hospitalRef = db.collection("hospitals").doc(hospitalId);
    const hospitalDoc = await hospitalRef.get();

    if (!hospitalDoc.exists) {
      throw new Error("Hospital not found.");
    }

    // Start Firestore transaction
    const batch = db.batch();

    // 🔹 Collect IDs of Patients and Doctors linked to the hospital
    const collectIds = async (collection) => {
      const snapshot = await db
        .collection(collection)
        .where("hospital", "==", hospitalId)
        .get();
      return snapshot.docs.map((doc) => doc.id);
    };

    const patientIds = await collectIds("patients");
    const doctorIds = await collectIds("doctors");

    // 🔹 Delete Patients, Doctors, and Admins linked to this hospital
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

    // 🔹 Delete Appointments linked to collected patient & doctor IDs
    const deleteAppointmentsAndTests = async (collection, field) => {
      const snapshot = await db
        .collection(collection)
        .where(field, "in", [...patientIds, ...doctorIds])
        .get();
      snapshot.forEach((doc) => batch.delete(doc.ref));
    };

    await deleteAppointmentsAndTests("appointments", "patient");
    await deleteAppointmentsAndTests("appointments", "doctor");
    await deleteAppointmentsAndTests("tests", "patient");
    await deleteAppointmentsAndTests("tests", "doctor");

    // 🔹 Delete the hospital itself
    batch.delete(hospitalRef);
    await batch.commit();

    return { message: "Hospital and all associated records deleted successfully." };
  }

  static async findHospital(hospitalId) {
    const hospitalRef = db.collection("hospitals").doc(hospitalId);
    const hospitalDoc = await hospitalRef.get();

    if (!hospitalDoc.exists) {
      throw new Error("hospitalService-findHospital: Invalid Hospital ID");
    }

    return { id: hospitalDoc.id, ...hospitalDoc };
  }

  /**
   * Retrieves all hospitals.
   * @returns {Promise<Array<Object>>} An array of all hospitals including their IDs.
   * @throws {Error} If no hospitals are found.
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
   * @param {string} field - The field to check for uniqueness (e.g., "emails" or "mobileNumbers").
   * @param {Array<string>} values - The values to check for uniqueness.
   * @param {string} [hospitalId] - The ID of the current hospital (to exclude from uniqueness check).
   * @returns {Promise<void>}
   * @throws {Error} If any of the values are already in use.
   * @private
   */
  // static async _checkUniqueFields(field, values, hospitalId = null) {
  //   const collections = ["patients", "doctors", "admins", "hospitals"];

  //   for (const collection of collections) {
  //     const querySnapshot = await db
  //       .collection(collection)
  //       .where(field, "array-contains-any", values)
  //       .get();

  //     querySnapshot.forEach((doc) => {
  //       if (hospitalId && doc.id === hospitalId) return; // Skip the current hospital
  //       throw new Error(`One of the ${field} is already in use.`);
  //     });
  //   }
  // }

  static async _checkUniqueFields(field, values, hospitalId = null) {
    const collections = ["patients", "doctors", "admins", "superadmins", "hospitals"];
  
    let field_updated;
    switch (field) {
      case "emails":
        field_updated = "email";
        break;
      case "mobileNumbers":
        field_updated = "mobileNumber";
        break;
      default:
        throw new Error("Invalid field provided.");
    }
  
    // Helper to chunk values into groups of 10
    const chunkArray = (arr, size) => {
      const result = [];
      for (let i = 0; i < arr.length; i += size) {
        result.push(arr.slice(i, i + size));
      }
      return result;
    };
  
    for (const coll of collections) {
      if (coll === "hospitals") {
        // Only one query needed since we're using `array-contains-any`
        const snapshot = await db
          .collection(coll)
          .where(field, "array-contains-any", values)
          .get();
  
        snapshot.docs.forEach((doc) => {
          if (hospitalId && doc.id === hospitalId) return;
          throw new Error(`One of the ${field} is already in use.`);
        });
      } else {
        const valueChunks = chunkArray(values, 10);
  
        for (const chunk of valueChunks) {
          const snapshot = await db
            .collection(coll)
            .where(field_updated, "in", chunk)
            .get();
  
          snapshot.docs.forEach((doc) => {
            throw new Error(`One of the ${field} is already in use.`);
          });
        }
      }
    }
  }  
  
}

module.exports = HospitalService;
